#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "android" asset catalog image resource.
static NSString * const ACImageNameAndroid AC_SWIFT_PRIVATE = @"android";

/// The "iTunesArtwork" asset catalog image resource.
static NSString * const ACImageNameITunesArtwork AC_SWIFT_PRIVATE = @"iTunesArtwork";

/// The "ios" asset catalog image resource.
static NSString * const ACImageNameIos AC_SWIFT_PRIVATE = @"ios";

/// The "mapImage" asset catalog image resource.
static NSString * const ACImageNameMapImage AC_SWIFT_PRIVATE = @"mapImage";

/// The "testTerritoryImage" asset catalog image resource.
static NSString * const ACImageNameTestTerritoryImage AC_SWIFT_PRIVATE = @"testTerritoryImage";

#undef AC_SWIFT_PRIVATE
