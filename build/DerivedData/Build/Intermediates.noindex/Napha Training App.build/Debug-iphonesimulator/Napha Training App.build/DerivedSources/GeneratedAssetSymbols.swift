import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Launch_screen_colour" asset catalog color resource.
    static let launchScreenColour = DeveloperToolsSupport.ColorResource(name: "Launch_screen_colour", bundle: resourceBundle)

    /// The "UIColour" asset catalog color resource.
    static let uiColour = DeveloperToolsSupport.ColorResource(name: "UIColour", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Calendar" asset catalog image resource.
    static let calendar = DeveloperToolsSupport.ImageResource(name: "Calendar", bundle: resourceBundle)

    /// The "Crunches" asset catalog image resource.
    static let crunches = DeveloperToolsSupport.ImageResource(name: "Crunches", bundle: resourceBundle)

    /// The "Leg Lifts" asset catalog image resource.
    static let legLifts = DeveloperToolsSupport.ImageResource(name: "Leg Lifts", bundle: resourceBundle)

    /// The "Leg Lifts with Hip Raises" asset catalog image resource.
    static let legLiftsWithHipRaises = DeveloperToolsSupport.ImageResource(name: "Leg Lifts with Hip Raises", bundle: resourceBundle)

    /// The "Reverse Crunches" asset catalog image resource.
    static let reverseCrunches = DeveloperToolsSupport.ImageResource(name: "Reverse Crunches", bundle: resourceBundle)

    /// The "Seated Knee-ups" asset catalog image resource.
    static let seatedKneeUps = DeveloperToolsSupport.ImageResource(name: "Seated Knee-ups", bundle: resourceBundle)

    /// The "Sit-ups" asset catalog image resource.
    static let sitUps = DeveloperToolsSupport.ImageResource(name: "Sit-ups", bundle: resourceBundle)

    /// The "TargetBoard" asset catalog image resource.
    static let targetBoard = DeveloperToolsSupport.ImageResource(name: "TargetBoard", bundle: resourceBundle)

    /// The "U-Crunches" asset catalog image resource.
    static let uCrunches = DeveloperToolsSupport.ImageResource(name: "U-Crunches", bundle: resourceBundle)

    /// The "final-image" asset catalog image resource.
    static let final = DeveloperToolsSupport.ImageResource(name: "final-image", bundle: resourceBundle)

    /// The "naapfa_logo" asset catalog image resource.
    static let naapfaLogo = DeveloperToolsSupport.ImageResource(name: "naapfa_logo", bundle: resourceBundle)

    /// The "red hexagon" asset catalog image resource.
    static let redHexagon = DeveloperToolsSupport.ImageResource(name: "red hexagon", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "Launch_screen_colour" asset catalog color.
    static var launchScreenColour: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launchScreenColour)
#else
        .init()
#endif
    }

    /// The "UIColour" asset catalog color.
    static var uiColour: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .uiColour)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "Launch_screen_colour" asset catalog color.
    static var launchScreenColour: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .launchScreenColour)
#else
        .init()
#endif
    }

    /// The "UIColour" asset catalog color.
    static var uiColour: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .uiColour)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "Launch_screen_colour" asset catalog color.
    static var launchScreenColour: SwiftUI.Color { .init(.launchScreenColour) }

    /// The "UIColour" asset catalog color.
    static var uiColour: SwiftUI.Color { .init(.uiColour) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "Launch_screen_colour" asset catalog color.
    static var launchScreenColour: SwiftUI.Color { .init(.launchScreenColour) }

    /// The "UIColour" asset catalog color.
    static var uiColour: SwiftUI.Color { .init(.uiColour) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Calendar" asset catalog image.
    static var calendar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .calendar)
#else
        .init()
#endif
    }

    /// The "Crunches" asset catalog image.
    static var crunches: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .crunches)
#else
        .init()
#endif
    }

    /// The "Leg Lifts" asset catalog image.
    static var legLifts: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .legLifts)
#else
        .init()
#endif
    }

    /// The "Leg Lifts with Hip Raises" asset catalog image.
    static var legLiftsWithHipRaises: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .legLiftsWithHipRaises)
#else
        .init()
#endif
    }

    /// The "Reverse Crunches" asset catalog image.
    static var reverseCrunches: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .reverseCrunches)
#else
        .init()
#endif
    }

    /// The "Seated Knee-ups" asset catalog image.
    static var seatedKneeUps: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .seatedKneeUps)
#else
        .init()
#endif
    }

    /// The "Sit-ups" asset catalog image.
    static var sitUps: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sitUps)
#else
        .init()
#endif
    }

    /// The "TargetBoard" asset catalog image.
    static var targetBoard: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .targetBoard)
#else
        .init()
#endif
    }

    /// The "U-Crunches" asset catalog image.
    static var uCrunches: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .uCrunches)
#else
        .init()
#endif
    }

    /// The "final-image" asset catalog image.
    static var final: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .final)
#else
        .init()
#endif
    }

    /// The "naapfa_logo" asset catalog image.
    static var naapfaLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .naapfaLogo)
#else
        .init()
#endif
    }

    /// The "red hexagon" asset catalog image.
    static var redHexagon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .redHexagon)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Calendar" asset catalog image.
    static var calendar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .calendar)
#else
        .init()
#endif
    }

    /// The "Crunches" asset catalog image.
    static var crunches: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .crunches)
#else
        .init()
#endif
    }

    /// The "Leg Lifts" asset catalog image.
    static var legLifts: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .legLifts)
#else
        .init()
#endif
    }

    /// The "Leg Lifts with Hip Raises" asset catalog image.
    static var legLiftsWithHipRaises: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .legLiftsWithHipRaises)
#else
        .init()
#endif
    }

    /// The "Reverse Crunches" asset catalog image.
    static var reverseCrunches: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .reverseCrunches)
#else
        .init()
#endif
    }

    /// The "Seated Knee-ups" asset catalog image.
    static var seatedKneeUps: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .seatedKneeUps)
#else
        .init()
#endif
    }

    /// The "Sit-ups" asset catalog image.
    static var sitUps: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sitUps)
#else
        .init()
#endif
    }

    /// The "TargetBoard" asset catalog image.
    static var targetBoard: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .targetBoard)
#else
        .init()
#endif
    }

    /// The "U-Crunches" asset catalog image.
    static var uCrunches: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .uCrunches)
#else
        .init()
#endif
    }

    /// The "final-image" asset catalog image.
    static var final: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .final)
#else
        .init()
#endif
    }

    /// The "naapfa_logo" asset catalog image.
    static var naapfaLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .naapfaLogo)
#else
        .init()
#endif
    }

    /// The "red hexagon" asset catalog image.
    static var redHexagon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .redHexagon)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

