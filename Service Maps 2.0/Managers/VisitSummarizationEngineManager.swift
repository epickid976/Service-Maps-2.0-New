import Foundation
import NaturalLanguage

/// An adaptive visit summarization engine with contextual understanding,
/// pattern recognition, memory-based weighting, and human-like insights.
public struct VisitSummarizationEngineManager {
    public let notes: [String]
    public let visitDates: [Date]?

    private var processedNotes: [ProcessedNote] = []
    private var relationshipModel = RelationshipInsightModel()
    private var visitContexts: [VisitContext] = []
    private var narrativeGenerator: NarrativeGenerator

    private var patternRecognition = AdaptivePatternRecognizer()
    private var contextualMemory: ContextualMemory

    public init(notes: [String], visitDates: [Date]? = nil) {
        self.notes = notes
        self.visitDates = visitDates
        self.contextualMemory = ContextualMemory(capacity: max(20, notes.count * 2))
        self.narrativeGenerator = NarrativeGenerator()

        processVisitHistory()
        analyzeRelationshipDynamics()
    }
    // MARK: - Intelligent Processing
        private mutating func processVisitHistory() {
            let weights = computeAdaptiveRecencyWeights()

            for i in 0..<notes.count {
                let note = notes[i].trimmingCharacters(in: .whitespacesAndNewlines)
                let date = i < (visitDates?.count ?? 0) ? visitDates?[i] : nil
                let weight = i < weights.count ? weights[i] : 1.0
                guard !note.isEmpty && note != "NC" else { continue }

                // Sentence-level analysis with role extraction
                let sentences = extractSentences(from: note)
                var sentenceInsights: [ProcessedNote] = []

                for sentence in sentences {
                    let processedNote = processNoteWithNLP(note: sentence, date: date, weight: weight)
                    sentenceInsights.append(processedNote)
                }

                // Combine into one final ProcessedNote per visit
                let final = combineProcessedNotes(from: sentenceInsights, originalNote: note, date: date, weight: weight)
                processedNotes.append(final)

                let context = extractVisitContext(from: final)
                visitContexts.append(context)
                contextualMemory.store(insight: "Visit \(i+1): \(context.primaryTheme)", weight: weight)
                patternRecognition.learn(from: final)
            }
        }
    
    private func extractSentences(from text: String) -> [String] {
            var result: [String] = []
            let tokenizer = NLTokenizer(unit: .sentence)
            tokenizer.string = text
            tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    result.append(sentence)
                }
                return true
            }
            return result
        }
    
    private func combineProcessedNotes(from notes: [ProcessedNote], originalNote: String, date: Date?, weight: Double) -> ProcessedNote {
           var allLemmas = Set<String>()
           var allTopics = Set<Topic>()
           var allIntents = Set<Intent>()
           var allRestrictions = Set<String>()
           var totalScore: Double = 0
           var totalIntensity: Double = 0
           var tones = Set<EmotionalTone>()
           var revisitaName: String? = nil

           for n in notes {
               allLemmas.formUnion(n.lemmas)
               allTopics.formUnion(n.topics)
               allIntents.formUnion(n.intents)
               allRestrictions.formUnion(n.restrictions)
               totalScore += n.sentiment.score
               totalIntensity += n.sentiment.intensity
               tones.formUnion(n.sentiment.emotionalTones)
               if let name = n.revisitaName {
                   revisitaName = name
               }
           }

           let avgScore = totalScore / Double(notes.count)
           let avgIntensity = totalIntensity / Double(notes.count)

           return ProcessedNote(
               original: originalNote,
               date: date,
               weight: weight,
               lemmas: Array(allLemmas),
               sentiment: SentimentAnalysis(score: avgScore, intensity: avgIntensity, emotionalTones: tones, isAmbiguous: abs(avgScore) < 0.2),
               topics: Array(allTopics),
               intents: Array(allIntents),
               restrictions: Array(allRestrictions),
               revisitaName: revisitaName
           )
       }
    
    private func computeAdaptiveRecencyWeights() -> [Double] {
        let now = Date()
        let count = notes.count
        return (0..<count).map { idx in
            guard let dates = visitDates, idx < dates.count else { return 1.0 }
            let days = now.timeIntervalSince(dates[idx]) / 86400.0
            return 2.0 / (1.0 + exp(min(days - 30, 90) / 30.0))
        }
    }
    
    private func processNoteWithNLP(note: String, date: Date?, weight: Double) -> ProcessedNote {
            let tagger = NLTagger(tagSchemes: [.lemma, .nameType, .tokenType])
            tagger.string = note

            let lemmas = extractLemmas(from: note, using: tagger)
            let sentiment = detectSentimentNuanced(note: note, lemmas: lemmas)
            let topics = extractTopics(from: note, lemmas: lemmas)
            let intents = recognizeIntents(in: note, lemmas: lemmas)
            let restrictions = extractRestrictions(from: note, lemmas: lemmas)

            var revisitaName: String? = nil
            let revisitaRegex = try? NSRegularExpression(pattern: #"revisita(?: de| a)? (\w+)"#, options: .caseInsensitive)
            if let match = revisitaRegex?.firstMatch(in: note, range: NSRange(note.startIndex..., in: note)),
               let range = Range(match.range(at: 1), in: note) {
                revisitaName = String(note[range])
            }

            return ProcessedNote(
                original: note,
                date: date,
                weight: weight,
                lemmas: lemmas,
                sentiment: sentiment,
                topics: topics,
                intents: intents,
                restrictions: restrictions,
                revisitaName: revisitaName
            )
        }
    
    private func extractLemmas(from text: String, using tagger: NLTagger) -> [String] {
        var lemmas: [String] = []
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma) { tag, tokenRange in
            if let lemma = tag?.rawValue.lowercased(),
               lemma.count > 2,
               !StopWords.spanish.contains(lemma) {
                lemmas.append(lemma)
            }
            return true
        }
        
        return lemmas
    }
    
    private func detectSentimentNuanced(note: String, lemmas: [String]) -> SentimentAnalysis {
        // More nuanced sentiment analysis based on language patterns, negations
        // and emotional keywords in Spanish
        
        let text = note.lowercased()
        var score: Double = 0
        var intensity: Double = 0
        var emotionalTones: Set<EmotionalTone> = []
        
        // Check for positive signals
        let positivePatterns = [
            "interesad": 0.6, "acept": 0.5, "amable": 0.4, "atent": 0.3,
            "escuch": 0.3, "bien": 0.3, "feliz": 0.7, "content": 0.5,
            "agrad": 0.6, "recib": 0.3, "gust": 0.5, "abierto": 0.4
        ]
        
        // Check for negative signals
        let negativePatterns = [
            "rechaz": -0.7, "no ": -0.2, "cerr": -0.5, "molest": -0.6,
            "enojad": -0.7, "ocupad": -0.3, "no puede": -0.4, "no quiere": -0.6,
            "desinteresad": -0.7, "negativ": -0.5, "hostil": -0.8
        ]
        
        // Process positive patterns
        for (pattern, value) in positivePatterns {
            if text.contains(pattern) {
                // Check for negations
                if text.contains("no \(pattern)") || text.contains("sin \(pattern)") {
                    score -= value / 2
                } else {
                    score += value
                    intensity += value / 2
                    
                    // Detect emotional tones
                    if value > 0.5 {
                        emotionalTones.insert(.enthusiasm)
                    } else {
                        emotionalTones.insert(.openness)
                    }
                }
            }
        }
        
        // Direct phrase boosts
        if text.contains("escuchó muy bien") || text.contains("atendió muy bien") {
            score += 0.4
            intensity += 0.3
            emotionalTones.insert(.openness)
        }

        // General phrase combo (just in case spelling varies)
        if text.contains("escuch") && text.contains("bien") {
            score += 0.3
            intensity += 0.2
            emotionalTones.insert(.openness)
        }
        
        // Process negative patterns
        for (pattern, value) in negativePatterns {
            if text.contains(pattern) {
                score += value  // already negative
                intensity += abs(value) / 2
                
                // Detect emotional tones
                if value < -0.6 {
                    emotionalTones.insert(.rejection)
                } else {
                    emotionalTones.insert(.hesitation)
                }
            }
        }
        
        // Adjust for emphasis words
        if text.contains("muy ") || text.contains("mucho") || text.contains("bastante") {
            score *= 1.3
            intensity += 0.2
        }
        
        // Normalize
        score = max(-1.0, min(1.0, score))
        intensity = max(0.1, min(1.0, intensity))
        
        return SentimentAnalysis(
            score: score,
            intensity: intensity,
            emotionalTones: emotionalTones,
            isAmbiguous: abs(score) < 0.2
        )
    }
    
    private func extractTopics(from note: String, lemmas: [String]) -> [Topic] {
        var topics: [Topic] = []
        let text = note.lowercased()
        
        // Topic detection based on domain knowledge
        let topicPatterns: [String: Topic] = [
            "familia": .family,
            "reunión": .meeting,
            "reuniones": .meeting,
            "invitación": .invitation,
            "estudio": .study,
            "publicación": .publication,
            "libro": .publication,
            "revista": .publication,
            "biblia": .religious,
            "dios": .religious,
            "oración": .religious,
            "fe": .religious,
            "creencia": .religious,
            "católic": .religious,
            "cristian": .religious,
            "enferm": .personal,
            "salud": .personal,
            "tiempo": .availability,
            "horario": .availability,
            "conmemoración": .event,
            "evento": .event,
            "programar": .scheduling,
            "cita": .scheduling
        ]
        
        for (pattern, topic) in topicPatterns {
            if text.contains(pattern) {
                topics.append(topic)
            }
        }
        
        return topics
    }
    
    private func recognizeIntents(in note: String, lemmas: [String]) -> [Intent] {
        var intents: [Intent] = []
        let text = note.lowercased()
        
        // Intent recognition patterns
        if text.contains("pregunt") {
            intents.append(.question)
        }
        
        if text.contains("aceptó") || text.contains("recibió") || text.contains("tomó") {
            intents.append(.acceptance)
        }
        
        if text.contains("rechaz") || text.contains("no quiso") || text.contains("no acept") {
            intents.append(.rejection)
        }
        
        if text.contains("volver") || text.contains("regresar") || text.contains("otra vez") ||
            text.contains("próxima") || text.contains("seguimiento") {
            intents.append(.followUp)
        }
        
        if text.contains("no ") && (text.contains("molestar") || text.contains("tocar") || text.contains("visitar")) {
            intents.append(.restriction)
        }
        
        return intents
    }
    
    private func extractRestrictions(from note: String, lemmas: [String]) -> [String] {
        var restrictions: [String] = []
        let text = note.lowercased()
        
        // Common restriction patterns
        let restrictionPatterns = [
            // Explicit refusal
            "no tocar",
            "no molestar",
            "no visitar",
            "no recibir",
            "no aceptar visitas",
            "no aceptan",
            "no interesa",
            "no quiere saber nada",
            "no quiere que regresen",
            "rechazó",
            "cerró la puerta",
            "no le interesa",
            "no quiere escuchar",
            "ya dijo que no",
            
            // Gender-specific or sister-related restrictions
            "que no toquen mujeres",
            "que no toquen hermanas",
            "solo hombres",
            "solo varones",
            "no quiere que vayan hermanas",
            "no acepta visitas de mujeres",
            "prefiere que vaya un hermano",
            "prefiere hombres",
            
            // Phone/call required
            "avisar antes",
            "llamar antes",
            "solo con cita",
            "solo por teléfono",
            "solo si llama antes",
            "programar antes",
            "con aviso previo",
            
            // Aggressive or rude
            "agresivo",
            "gritó",
            "grosero",
            "reaccionó mal",
            "hostil",
            "se enojó",
            "levantó la voz",
            "amenazó",
            "nos insultó",
            "muy rudo",
            "maleducado",
            "reaccionó con violencia",
            
            // Apathetic or indifferent
            "no mostró interés",
            "no quiso hablar",
            "no habló",
            "no respondió",
            "actitud apática",
            "cerrado",
            "se negó",
            "ni abrió",
            "no dijo nada",
            "no quiso saber",
            "no prestó atención",
            
            // Polite refusals or soft no
            "no por ahora",
            "gracias pero no",
            "tal vez otro día",
            "ahora no",
            "está ocupado",
            "más adelante",
            "en otro momento",
            "no tiene tiempo",
            
            // Visual or physical cues
            "puso cartel de no molestar",
            "cartel de no visitas",
            "avisó por nota",
            "cerró sin hablar",
            "cerró sin decir nada",
            "se escondió",
            
            // Religious or doctrinal refusals
            "es de otra religión",
            "no quiere cambiar",
            "no está interesado en religión",
            "es muy católico",
            "dijo que ya tiene su fe",
            "no quiere hablar de religión"
        ]
        
        for pattern in restrictionPatterns {
            if text.contains(pattern) {
                restrictions.append(pattern)
            }
        }
        
        return restrictions
    }
    
    // MARK: - Relationship Analysis
    private mutating func analyzeRelationshipDynamics() {
        guard !processedNotes.isEmpty else { return }
        
        // Build relationship insights from visit history
        for (index, note) in processedNotes.enumerated() {
            // Extract key patterns to build relationship model
            let visitInsight = VisitInsight(
                visitNumber: index + 1,
                sentiment: note.sentiment,
                topics: note.topics,
                intents: note.intents,
                restrictions: note.restrictions,
                weight: note.weight
            )
            
            // Update relationship model
            relationshipModel.incorporate(insight: visitInsight)
        }
        
        // Find significant relationship patterns
        let patterns = patternRecognition.identifySignificantPatterns()
        relationshipModel.applyPatterns(patterns)
        
        // Generate narrative elements
        narrativeGenerator.prepare(
            relationshipModel: relationshipModel,
            visitContexts: visitContexts,
            memory: contextualMemory
        )
    }
    
    // MARK: - Context Extraction
    private func extractVisitContext(from note: ProcessedNote) -> VisitContext {
        let primaryTopic = note.topics.first ?? .general
        let emotionalState = determineEmotionalState(from: note.sentiment)
        
        let primaryIntent: Intent = note.intents.first { intent in
            intent == .followUp || intent == .rejection || intent == .restriction
        } ?? (note.intents.first ?? .none)
        
        return VisitContext(
            primaryTheme: primaryTopic.description,
            emotionalState: emotionalState,
            primaryIntent: primaryIntent,
            hasRestrictions: !note.restrictions.isEmpty,
            sentiment: note.sentiment.score
        )
    }
    
    private func determineEmotionalState(from sentiment: SentimentAnalysis) -> String {
        if sentiment.score > 0.5 {
            return sentiment.intensity > 0.7 ? "Entusiasmo" : "Receptividad"
        } else if sentiment.score > 0.2 {
            return "Interés moderado"
        } else if sentiment.score < -0.5 {
            return sentiment.intensity > 0.7 ? "Rechazo firme" : "Desinterés"
        } else if sentiment.score < -0.2 {
            return "Indiferencia"
        } else {
            return "Neutral"
        }
    }
    
    // MARK: - Public Interface
    
    /// Generates a concise, intelligent summary of the visit history with actionable insights
    public func generateActionOrientedNarrative() -> String {
            guard let model = relationshipModel as RelationshipInsightModel? else {
                return "No hay suficiente información para generar un resumen."
            }

            if let revisitaName = processedNotes.last?.revisitaName {
                return "🔁 Revisita con \(revisitaName.capitalized). " + narrativeGenerator.generate(style: .actionOriented)
            } else if processedNotes.last?.intents.contains(.followUp) == true {
                return "🔁 Esta es una revisita. " + narrativeGenerator.generate(style: .actionOriented)
            } else {
                return narrativeGenerator.generate(style: .actionOriented)
            }
        }
    
    /// Generate different narrative styles
    public func generateNarrative(style: NarrativeStyle = .balanced) -> String {
        return narrativeGenerator.generate(style: style)
    }
    
    /// Notes that require human review
    public var notesToReview: [String] {
        return processedNotes
            .filter { $0.sentiment.isAmbiguous && $0.intents.isEmpty }
            .map { $0.original }
    }
}

// MARK: - Supporting Types

/// Narrative styles for different uses
public enum NarrativeStyle {
    case concise          // Brief summary with key points only
    case detailed         // Comprehensive report with all data
    case actionOriented   // Focused on next steps and recommendations
    case balanced         // Default middle ground
}

/// Processed note with NLP analysis
struct ProcessedNote {
    let original: String
    let date: Date?
    let weight: Double
    let lemmas: [String]
    let sentiment: SentimentAnalysis
    let topics: [Topic]
    let intents: [Intent]
    let restrictions: [String]
    let revisitaName: String?
}

/// Comprehensive sentiment analysis
struct SentimentAnalysis {
    let score: Double             // -1.0 (negative) to 1.0 (positive)
    let intensity: Double         // 0.0 (mild) to 1.0 (strong)
    let emotionalTones: Set<EmotionalTone>
    let isAmbiguous: Bool
}

/// Emotional tones detected
enum EmotionalTone: String {
    case enthusiasm
    case openness
    case curiosity
    case hesitation
    case indifference
    case rejection
    case hostility
}

/// Recognized visit topics
enum Topic: CustomStringConvertible {
    case family
    case religious
    case event
    case meeting
    case study
    case publication
    case personal
    case availability
    case invitation
    case scheduling
    case general
    
    var description: String {
        switch self {
        case .family: return "Familia"
        case .religious: return "Creencias"
        case .event: return "Evento"
        case .meeting: return "Reunión"
        case .study: return "Estudio"
        case .publication: return "Publicación"
        case .personal: return "Personal"
        case .availability: return "Disponibilidad"
        case .invitation: return "Invitación"
        case .scheduling: return "Programación"
        case .general: return "General"
        }
    }
}

/// Recognized intents
enum Intent {
    case acceptance
    case rejection
    case question
    case followUp
    case restriction
    case none
}

/// Visit contextual information
struct VisitContext {
    let primaryTheme: String
    let emotionalState: String
    let primaryIntent: Intent
    let hasRestrictions: Bool
    let sentiment: Double
}

/// Relationship insight from a specific visit
struct VisitInsight {
    let visitNumber: Int
    let sentiment: SentimentAnalysis
    let topics: [Topic]
    let intents: [Intent]
    let restrictions: [String]
    let weight: Double
}

/// Model for relationship dynamics
class RelationshipInsightModel {
    var overallSentiment: Double = 0
    var trajectory: Trajectory = .stable
    var engagementLevel: EngagementLevel = .moderate
    var significantTopics: [Topic: Int] = [:]
    var hasActiveFollowUps: Bool = false
    var hasRestrictions: Bool = false
    var rejectionCount: Int = 0
    var acceptanceCount: Int = 0
    var visitCount: Int = 0
    var lastVisitSentiment: Double?
    var consistentPatterns: [String] = []
    
    enum Trajectory {
        case improving
        case declining
        case stable
        case fluctuating
    }
    
    enum EngagementLevel {
        case high
        case moderate
        case low
        case negative
    }
    
    func incorporate(insight: VisitInsight) {
        visitCount += 1
        
        // Update sentiment tracking
        let weightedSentiment = insight.sentiment.score * insight.weight
        overallSentiment = ((overallSentiment * Double(visitCount - 1)) + weightedSentiment) / Double(visitCount)
        lastVisitSentiment = insight.sentiment.score
        
        // Track topics
        for topic in insight.topics {
            significantTopics[topic, default: 0] += 1
        }
        
        // Track intents
        if insight.intents.contains(.followUp) {
            hasActiveFollowUps = true
        }
        
        if insight.intents.contains(.restriction) {
            hasRestrictions = true
        }
        
        if insight.intents.contains(.rejection) {
            rejectionCount += 1
        }
        
        if insight.intents.contains(.acceptance) {
            acceptanceCount += 1
        }
        
        // Update engagement level
        updateEngagementLevel()
    }
    
    func applyPatterns(_ patterns: [String]) {
        self.consistentPatterns = patterns
    }
    
    private func updateEngagementLevel() {
        // Special rule: One strong positive visit = moderate engagement
        if visitCount == 1 && (lastVisitSentiment ?? 0) > 0.3 {
            engagementLevel = .moderate
            return
        }
        
        // Update trajectory
        if visitCount >= 3 {
            // Logic to determine trajectory based on sentiment trends
            if overallSentiment > 0.4 && (lastVisitSentiment ?? 0) > 0.4 {
                trajectory = .improving
            } else if overallSentiment < -0.2 || rejectionCount > visitCount / 3 {
                trajectory = .declining
            } else {
                trajectory = .stable
            }
        }
        
        // Update engagement level
        if overallSentiment > 0.5 && acceptanceCount > visitCount / 2 {
            engagementLevel = .high
        } else if overallSentiment > 0 && rejectionCount < visitCount / 4 {
            engagementLevel = .moderate
        } else if rejectionCount > visitCount / 3 || overallSentiment < -0.3 {
            engagementLevel = .negative
        } else {
            engagementLevel = .low
        }
    }
}

/// Adaptive pattern recognition for visit analysis
struct AdaptivePatternRecognizer {
    private var notePatterns: [String: Int] = [:]
    private var topicSequences: [[Topic]] = []
    private var sentimentChanges: [Double] = []
    
    mutating func learn(from note: ProcessedNote) {
        // Learn from key phrases and patterns
        for lemma in note.lemmas {
            notePatterns[lemma, default: 0] += 1
        }
        
        // Track topic sequences
        if !note.topics.isEmpty {
            topicSequences.append(note.topics)
        }
        
        // Track sentiment changes
        sentimentChanges.append(note.sentiment.score)
    }
    
    func identifySignificantPatterns() -> [String] {
        var patterns: [String] = []
        
        // Identify frequent lemmas
        let significantLemmas = notePatterns
            .filter { $0.value > 1 }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        if !significantLemmas.isEmpty {
            patterns.append("Temas recurrentes: \(significantLemmas.joined(separator: ", "))")
        }
        
        // Identify sentiment patterns
        if sentimentChanges.count >= 3 {
            let recentTrend = sentimentChanges.suffix(3)
            if recentTrend.allSatisfy({ $0 > 0.3 }) {
                patterns.append("Tendencia positiva consistente")
            } else if recentTrend.allSatisfy({ $0 < -0.2 }) {
                patterns.append("Tendencia negativa consistente")
            } else if recentTrend.max()! - recentTrend.min()! > 0.6 {
                patterns.append("Receptividad variable")
            }
        }
        
        // Identify topic patterns
        if topicSequences.count >= 2 {
            // Check for recurring topics
            let flatTopics = topicSequences.flatMap { $0 }
            let topicCounts = flatTopics.reduce(into: [Topic: Int]()) { $0[$1, default: 0] += 1 }
            
            if let (primaryTopic, count) = topicCounts.max(by: { $0.value < $1.value }),
               count >= topicSequences.count / 2 {
                patterns.append("Interés consistente en: \(primaryTopic.description)")
            }
        }
        
        return patterns
    }
}

/// Context-aware memory for historical patterns
class ContextualMemory {
    private var insights: [(String, Double)] = []
    private let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func store(insight: String, weight: Double) {
        insights.append((insight, weight))
        if insights.count > capacity {
            insights.removeFirst()
        }
    }
    
    func retrieveTopInsights(count: Int = 3) -> [String] {
        return insights
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map { $0.0 }
    }
}

/// Intelligent narrative generator
// MARK: - Intelligent narrative generator
class NarrativeGenerator {
    private var relationshipModel: RelationshipInsightModel?
    private var visitContexts: [VisitContext] = []
    private var memory: ContextualMemory?
    
    func prepare(relationshipModel: RelationshipInsightModel, visitContexts: [VisitContext], memory: ContextualMemory) {
        self.relationshipModel = relationshipModel
        self.visitContexts = visitContexts
        self.memory = memory
    }
    
    func generate(style: NarrativeStyle) -> String {
        guard let model = relationshipModel else {
            return "No hay suficiente información para generar un resumen."
        }
        
        switch style {
        case .actionOriented:
            return generateActionOrientedNarrative(model)
        case .concise:
            return generateConciseNarrative(model)
        case .detailed:
            return generateDetailedNarrative(model)
        case .balanced:
            return generateBalancedNarrative(model)
        }
    }
    
    private func generateActionOrientedNarrative(_ model: RelationshipInsightModel) -> String {
        // Special case: single visit with good sentiment
        if model.visitCount == 1, let sentiment = model.lastVisitSentiment, sentiment > 0.3 {
            return "📖 Primer contacto positivo. Podría considerarse una revisita."
        }
        
        if model.rejectionCount > model.visitCount / 3 {
            return PhraseBank.randomPhrase(from: PhraseBank.rejectionPhrases)
        }
        
        if model.hasRestrictions {
            return PhraseBank.randomPhrase(from: PhraseBank.restrictionPhrases)
        }
        
        if model.hasActiveFollowUps {
            let relevantTopics = model.significantTopics
                .sorted { $0.value > $1.value }
                .prefix(2)
                .map { $0.key.description }
                .joined(separator: ", ")
            
            return "\(PhraseBank.randomPhrase(from: PhraseBank.followUpPhrases)) Temas sugeridos: \(relevantTopics). \(generateEngagementRecommendation(model))"
        }
        
        switch model.engagementLevel {
        case .high:
            return PhraseBank.randomPhrase(from: PhraseBank.highEngagementPhrases)
        case .moderate:
            return PhraseBank.randomPhrase(from: PhraseBank.moderateEngagementPhrases)
        case .low:
            return PhraseBank.randomPhrase(from: PhraseBank.lowEngagementPhrases)
        case .negative:
            return PhraseBank.randomPhrase(from: PhraseBank.negativeEngagementPhrases)
        }
    }
    
    private func generateEngagementRecommendation(_ model: RelationshipInsightModel) -> String {
        switch model.trajectory {
        case .improving:
            return PhraseBank.randomPhrase(from: PhraseBank.improvingTrajectoryPhrases)
        case .declining:
            return PhraseBank.randomPhrase(from: PhraseBank.decliningTrajectoryPhrases)
        case .stable:
            return PhraseBank.randomPhrase(from: PhraseBank.stableTrajectoryPhrases)
        case .fluctuating:
            return PhraseBank.randomPhrase(from: PhraseBank.fluctuatingTrajectoryPhrases)
        }
    }
    
    private func generateConciseNarrative(_ model: RelationshipInsightModel) -> String {
        let sentiment = model.overallSentiment > 0.3 ? "positiva" :
        (model.overallSentiment < -0.2 ? "negativa" : "neutral")
        
        let action = model.hasActiveFollowUps ? PhraseBank.randomPhrase(from: PhraseBank.followUpPhrases) :
        (model.hasRestrictions ? PhraseBank.randomPhrase(from: PhraseBank.restrictionPhrases) :
            PhraseBank.randomPhrase(from: PhraseBank.moderateEngagementPhrases))
        
        return "Relación \(sentiment). \(action)"
    }
    
    private func generateBalancedNarrative(_ model: RelationshipInsightModel) -> String {
        let relationshipStatus: String
        switch model.engagementLevel {
        case .high:
            relationshipStatus = PhraseBank.randomPhrase(from: PhraseBank.highEngagementPhrases)
        case .moderate:
            relationshipStatus = PhraseBank.randomPhrase(from: PhraseBank.moderateEngagementPhrases)
        case .low:
            relationshipStatus = PhraseBank.randomPhrase(from: PhraseBank.lowEngagementPhrases)
        case .negative:
            relationshipStatus = PhraseBank.randomPhrase(from: PhraseBank.negativeEngagementPhrases)
        }
        
        let topTopics = model.significantTopics
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0.key.description }
            .joined(separator: ", ")
        
        let nextSteps = model.hasActiveFollowUps ? PhraseBank.randomPhrase(from: PhraseBank.followUpPhrases) :
        (model.hasRestrictions ? PhraseBank.randomPhrase(from: PhraseBank.restrictionPhrases) :
            PhraseBank.randomPhrase(from: PhraseBank.moderateEngagementPhrases))
        
        return "\(relationshipStatus) Temas: \(topTopics). \(nextSteps)"
    }
    
    private func generateDetailedNarrative(_ model: RelationshipInsightModel) -> String {
        let topics = model.significantTopics
            .sorted { $0.value > $1.value }
            .map { "\($0.key.description) (\($0.value))" }
            .joined(separator: ", ")
        
        let patterns = model.consistentPatterns.joined(separator: ". ")
        
        return """
        Visitas: \(model.visitCount). Sentimiento: \(String(format: "%.1f", model.overallSentiment)).
        Temas: \(topics).
        Patrón: \(patterns.isEmpty ? "No hay patrones claros" : patterns).
        Recomendación: \(generateActionOrientedNarrative(model))
        """
    }
}


// Spanish stopwords to improve NLP processing
struct StopWords {
    static let spanish: Set<String> = [
        "a", "al", "algo", "algunas", "algunos", "ante", "antes", "como", "con", "contra",
        "cual", "cuando", "de", "del", "desde", "donde", "durante", "e", "el", "ella",
        "ellas", "ellos", "en", "entre", "era", "erais", "eran", "eras", "eres", "es",
        "esa", "esas", "ese", "eso", "esos", "esta", "estaba", "estabais", "estaban",
        "estabas", "estad", "estada", "estadas", "estado", "estados", "estamos", "estando",
        "estar", "estaremos", "estará", "estarán", "estarás", "estaré", "estaréis",
        "estaría", "estaríais", "estaríamos", "estarían", "estarías", "estas", "este",
        "estemos", "esto", "estos", "estoy", "estuve", "estuviera", "estuvierais",
        "estuvieran", "estuvieras", "estuvieron", "estuviese", "estuvieseis", "estuviesen",
        "estuvieses", "estuvimos", "estuviste", "estuvisteis", "estuvo", "está", "estábamos",
        "estáis", "están", "estás", "esté", "estéis", "estén", "estés", "fue", "fuera",
        "fuerais", "fueran", "fueras", "fueron", "fuese", "fueseis", "fuesen", "fueses",
        "fui", "fuimos", "fuiste", "fuisteis", "ha", "habéis", "había", "habíais", "habíamos", "habían", "habías",
        "han", "has", "hasta", "hay", "haya", "hayáis", "hayamos", "hayan", "hayas", "he",
        "hemos", "hube", "hubiera", "hubierais", "hubieran", "hubieras", "hubieron",
        "hubiese", "hubieseis", "hubiesen", "hubieses", "hubimos", "hubiste", "hubisteis",
        "hubo", "la", "las", "le", "les", "lo", "los", "me", "mi", "mis", "mucho", "muchos",
        "muy", "más", "mí", "mía", "mías", "mío", "míos", "nada", "ni", "no", "nos",
        "nosotras", "nosotros", "nuestra", "nuestras", "nuestro", "nuestros", "o", "os",
        "otra", "otras", "otro", "otros", "para", "pero", "poco", "por", "porque", "que",
        "quien", "quienes", "qué", "se", "sea", "seamos", "sean", "seas", "sentid",
        "sentida", "sentidas", "sentido", "sentidos", "ser", "seremos", "será", "serán",
        "serás", "seré", "seréis", "sería", "seríais", "seríamos", "serían", "serías",
        "seáis", "si", "sido", "siendo", "sin", "sobre", "sois", "somos", "son", "soy",
        "su", "sus", "suya", "suyas", "suyo", "suyos", "sí", "también", "tanto", "te",
        "tendremos", "tendrá", "tendrán", "tendrás", "tendré", "tendréis", "tendría",
        "tendríais", "tendríamos", "tendrían", "tendrías", "tened", "tenemos", "tenga",
        "tengáis", "tengamos", "tengan", "tengas", "tengo", "tengáis", "tenida", "tenidas",
        "tenido", "tenidos", "teniendo", "tenéis", "tenía", "teníais", "teníamos", "tenían",
        "tenías", "ti", "tiene", "tienen", "tienes", "todo", "todos", "tu", "tus", "tuve",
        "tuviera", "tuvierais", "tuvieran", "tuvieras", "tuvieron", "tuviese", "tuvieseis",
        "tuviesen", "tuvieses", "tuvimos", "tuviste", "tuvisteis", "tuvo", "tuya", "tuyas",
        "tuyo", "tuyos", "tú", "un", "una", "uno", "unos", "vosotras", "vosotros", "vuestra",
        "vuestras", "vuestro", "vuestros", "y", "ya", "yo", "él", "éramos"
    ]
}

struct PhraseBank {
    static func randomPhrase(from options: [String]) -> String {
        options.randomElement() ?? ""
    }

    // MARK: - Rejection Phrases
    static let rejectionPhrases: [String] = [
        "🛑 Parece que no quieren saber nada por ahora.",
        "🚫 Las visitas no han sido bien recibidas últimamente.",
        "🟥 Ha habido una actitud constante de rechazo.",
        "⚠️ Varias señales apuntan a desinterés firme.",
        "🔴 Rechazo claro en más de una ocasión.",
        "📉 La persona no ha mostrado apertura recientemente."
    ]

    // MARK: - Restriction Phrases
    static let restrictionPhrases: [String] = [
        "🚫 Hay límites que debemos respetar al regresar.",
        "🔒 Nos han pedido ciertas condiciones para futuras visitas.",
        "⛔️ Han establecido reglas claras sobre cuándo o cómo visitar.",
        "🗒️ Es importante seguir las indicaciones que nos dieron.",
        "🔐 La interacción está limitada por petición de la persona."
    ]

    // MARK: - Follow-up Phrases
    static let followUpPhrases: [String] = [
        "🔔 Vale la pena regresar y seguir la conversación.",
        "📝 Hay razones para dar seguimiento pronto.",
        "📌 Se puede volver en otra ocasión para continuar.",
        "📅 Es un buen momento para retomar el contacto.",
        "🕒 Hay interés. Una próxima visita podría ser útil."
    ]

    // MARK: - High Engagement Phrases
    static let highEngagementPhrases: [String] = [
        "💬 Han estado muy receptivos y con buena actitud.",
        "🌱 Muestran interés real. Es buena oportunidad para avanzar.",
        "📖 Escuchan con atención. Vale la pena seguir compartiendo.",
        "🙌 Hay apertura. Podemos ofrecer más material sin problema.",
        "✅ Muy buena disposición. Se puede proponer algo más profundo."
    ]

    // MARK: - Moderate Engagement Phrases
    static let moderateEngagementPhrases: [String] = [
        "📝 Hay algo de interés. Podríamos seguir intentando.",
        "👀 A veces escuchan, vale la pena observar su reacción.",
        "📚 Escucharon con respeto. Quizás haya una oportunidad.",
        "🔎 No es rechazo, pero tampoco mucho interés aún.",
        "🙂 Algunas respuestas positivas. Veremos cómo evoluciona."
    ]

    // MARK: - Low Engagement Phrases
    static let lowEngagementPhrases: [String] = [
        "🔍 Poco interés hasta ahora. Tal vez otro enfoque ayude.",
        "😐 No han respondido mucho. Tocará ser pacientes.",
        "💤 La reacción ha sido mínima. Veremos si cambia.",
        "📉 Aún no conectamos del todo. Necesita tiempo.",
        "🪶 No se han mostrado muy interesados por el momento."
    ]

    // MARK: - Negative Engagement Phrases
    static let negativeEngagementPhrases: [String] = [
        "⚠️ No ha ido bien. Mejor hacer una pausa.",
        "🚷 No es buen momento para insistir.",
        "❌ Han rechazado varias veces. Mejor esperar.",
        "🧱 La actitud ha sido muy cerrada.",
        "⛔️ Parece que no están cómodos con nuestras visitas."
    ]

    // MARK: - Trajectory Insights
    static let improvingTrajectoryPhrases: [String] = [
        "📈 Han mejorado con el tiempo. Aprovechemos eso.",
        "🆙 Poco a poco están más abiertos.",
        "🌤️ Últimamente ha habido más receptividad.",
        "👣 Se nota un avance, aunque sea pequeño.",
        "🔁 Va mejorando. Sigamos con tacto."
    ]

    static let decliningTrajectoryPhrases: [String] = [
        "📉 Ha disminuido la apertura últimamente.",
        "⛔️ Están menos receptivos que antes.",
        "🔻 El interés parece estar bajando.",
        "🚦 Hay menos participación que en visitas anteriores.",
        "🪃 Antes escuchaban más. Ahora no tanto."
    ]

    static let stableTrajectoryPhrases: [String] = [
        "⚖️ La actitud se ha mantenido estable.",
        "🔁 No ha habido muchos cambios últimamente.",
        "📊 La respuesta es constante, ni mejor ni peor.",
        "🟰 Siguen igual que en visitas pasadas.",
        "🛤️ La situación está estable. Podemos seguir igual."
    ]

    static let fluctuatingTrajectoryPhrases: [String] = [
        "🔄 Algunas veces bien, otras no tanto.",
        "🎢 Cambios de actitud entre visitas.",
        "📉📈 A veces abren, a veces no.",
        "🌀 Es impredecible. Mejor ir con cuidado.",
        "⛅️ Depende del día cómo responden."
    ]
}

