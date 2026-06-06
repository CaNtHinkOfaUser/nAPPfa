#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"k.Napha-Training-App";

/// The "Launch_screen_colour" asset catalog color resource.
static NSString * const ACColorNameLaunchScreenColour AC_SWIFT_PRIVATE = @"Launch_screen_colour";

/// The "UIColour" asset catalog color resource.
static NSString * const ACColorNameUIColour AC_SWIFT_PRIVATE = @"UIColour";

/// The "Calendar" asset catalog image resource.
static NSString * const ACImageNameCalendar AC_SWIFT_PRIVATE = @"Calendar";

/// The "Crunches" asset catalog image resource.
static NSString * const ACImageNameCrunches AC_SWIFT_PRIVATE = @"Crunches";

/// The "Leg Lifts" asset catalog image resource.
static NSString * const ACImageNameLegLifts AC_SWIFT_PRIVATE = @"Leg Lifts";

/// The "Leg Lifts with Hip Raises" asset catalog image resource.
static NSString * const ACImageNameLegLiftsWithHipRaises AC_SWIFT_PRIVATE = @"Leg Lifts with Hip Raises";

/// The "Reverse Crunches" asset catalog image resource.
static NSString * const ACImageNameReverseCrunches AC_SWIFT_PRIVATE = @"Reverse Crunches";

/// The "Seated Knee-ups" asset catalog image resource.
static NSString * const ACImageNameSeatedKneeUps AC_SWIFT_PRIVATE = @"Seated Knee-ups";

/// The "Sit-ups" asset catalog image resource.
static NSString * const ACImageNameSitUps AC_SWIFT_PRIVATE = @"Sit-ups";

/// The "TargetBoard" asset catalog image resource.
static NSString * const ACImageNameTargetBoard AC_SWIFT_PRIVATE = @"TargetBoard";

/// The "U-Crunches" asset catalog image resource.
static NSString * const ACImageNameUCrunches AC_SWIFT_PRIVATE = @"U-Crunches";

/// The "final-image" asset catalog image resource.
static NSString * const ACImageNameFinalImage AC_SWIFT_PRIVATE = @"final-image";

/// The "naapfa_logo" asset catalog image resource.
static NSString * const ACImageNameNaapfaLogo AC_SWIFT_PRIVATE = @"naapfa_logo";

/// The "red hexagon" asset catalog image resource.
static NSString * const ACImageNameRedHexagon AC_SWIFT_PRIVATE = @"red hexagon";

#undef AC_SWIFT_PRIVATE
