// The MIT License (MIT)
//
// Copyright (c) 2025 Alexey Bukhtin (github.com/buh).
//

import SwiftUI

#if canImport(UIKit)
import UIKit
typealias NativeColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias NativeColor = NSColor
#endif

extension Color {
    var legacyCGColor: CGColor {
        NativeColor(self).cgColor
    }
}

extension CGColor {
    func interpolate(to endColor: CGColor, fraction: CGFloat) -> CGColor {
        let fraction: CGFloat = min(max(0, fraction), 1)
        
        guard let c1 = components, let c2 = endColor.components else {
            return CGColor(gray: 0, alpha: 1)
        }
        
        let r = c1[0] + (c2[0] - c1[0]) * fraction
        let g = c1[1] + (c2[1] - c1[1]) * fraction
        let b = c1[2] + (c2[2] - c1[2]) * fraction
        
        return CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
