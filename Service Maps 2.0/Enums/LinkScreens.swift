//
//  LinkScreens.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/25/24.
//

import Foundation

enum LinkScreens: String {
    case VALIDATE_EMAIL = "https://servicemaps.ejvapps.online/api/auth/signup/activate/"
    case REGISTER_KEY = "https://servicemaps.ejvapps.online/app/registerkey/"
    case RESET_PASSWORD = "https://servicemaps.ejvapps.online/app/passwordreset/"
    case PRIVACY_POLICY = "https://servicemaps.ejvapps.online/privacy"
    case LOGIN_EMAIL = "https://servicemaps.ejvapps.online/app/login/email"
    case OTHER = "Other"
}

enum DestinationEnum: String {
    case SplashScreen = "SplashScreenView"
    case HomeScreen = "HomeTabView"
    case WelcomeScreen = "WelcomeView"
    case LoginScreen = "LoginView"
    case AdministratorLoginScreen = "AdministratorLoginView"
    case PhoneLoginScreen = "PhoneLoginScreenView"
    case ValidationScreen = "ValidationView"
    case LoadingScreen = "LoadingView"
    case NoDataScreen = "NoDataView"
    case ActivateEmail = "ActivateEmailView"
    case RegisterKeyView = "RegisterKeyView"
    case ResetPasswordView = "ResetPasswordView"
    case PrivacyPolicyView = "PrivacyPolicyView"
    case loginWithEmailView = "LoginWithEmailView"
}
