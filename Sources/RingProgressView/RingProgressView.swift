// The MIT License (MIT)
//
// Copyright (c) 2025 Alexey Bukhtin (github.com/buh).
//

import SwiftUI

public struct RingProgressView<Symbol: View>: View {
    @Environment(\.self) private var environment
    
    @Binding var progress: Double
    let lineWidth: CGFloat
    let startColor: Color
    let endColor: Color
    let placeholderColor: Color?
    let headShadowRadius: CGFloat?
    let rotationEffectAngle: Angle
    let isSymbolRotating: Bool
    let symbol: Symbol
    
    public init(
        progress: Binding<Double>,
        lineWidth: CGFloat = 30,
        startColor: Color = .blue,
        endColor: Color = .teal,
        placeholderColor: Color? = .blue.opacity(0.3),
        headShadowRadius: CGFloat? = 5,
        rotationEffectAngle: Angle = Angle(degrees: -90),
        isSymbolRotating: Bool = true,
        @ViewBuilder symbol: () -> Symbol
    ) {
        _progress = progress
        self.lineWidth = max(2, lineWidth)
        self.startColor = startColor
        self.endColor = endColor
        self.placeholderColor = placeholderColor
        self.headShadowRadius = headShadowRadius
        self.rotationEffectAngle = rotationEffectAngle
        self.isSymbolRotating = isSymbolRotating
        self.symbol = symbol()
    }
    
    public var body: some View {
        Canvas { context, size in
            let minSize = minSize(size: size)
            let radius = (minSize - lineWidth) / 2
            
            guard minSize > 10, radius > 0 else { return }
            
            let angle = Angle(degrees: max(0, progress) * 360)
            let startCGColor: CGColor
            let endCGColor: CGColor
            
            if #available(iOS 17, macOS 14, watchOS 10, *) {
                startCGColor = startColor.resolve(in: environment).cgColor
                endCGColor = endColor.resolve(in: environment).cgColor
            } else {
                startCGColor = startColor.legacyCGColor
                endCGColor = endColor.legacyCGColor
            }
            
            let stepAngle = Angle(degrees: 2)
            let moduloDegrees = Int(angle.degrees) % 360
            
            var progressAngle = angle.degrees > 360
            ? Angle(degrees: moduloDegrees == 0 ? 360 : Double(moduloDegrees)) : .zero
            
            drawBackgroundCircle(context: context, size: size, angle: angle)
            
            repeat {
                let x: CGFloat = (size.width - lineWidth) / 2 + radius * cos(progressAngle.radians)
                let y: CGFloat = (size.height - lineWidth) / 2 + radius * sin(progressAngle.radians)
                let path = Circle().path(in: CGRect(x: x, y: y, width: lineWidth, height: lineWidth))
                
                drawHeadCircleShadow(
                    context: context,
                    circleSize: lineWidth,
                    x: x,
                    y: y,
                    angle: angle,
                    progressAngle: progressAngle,
                    stepAngle: stepAngle,
                    path: path
                )
                
                let colorProgress = angle.radians > 0 ? progressAngle.radians / angle.radians : 0
                
                let cgColor = startCGColor.interpolate(
                    to: endCGColor,
                    fraction: angle.degrees > 360 ? colorProgress : progressAngle.degrees / 360
                )
                
                context.fill(path, with: .color(Color(cgColor)))
                
                drawSymbol(
                    context: context,
                    circleSize: lineWidth,
                    x: x,
                    y: y,
                    angle: angle,
                    progressAngle: progressAngle,
                    stepAngle: stepAngle
                )
                
                progressAngle += stepAngle
            } while progressAngle <= angle
        } symbols: {
            symbol.tag(0)
        }
        .rotationEffect(rotationEffectAngle)
    }
    
    @inlinable
    func minSize(size: CGSize) -> CGFloat {
        min(size.width, size.height)
    }
    
    private func drawBackgroundCircle(context: GraphicsContext, size: CGSize, angle: Angle) {
        guard let placeholderColor, angle.degrees < 360 else { return }
        
        let minSize = minSize(size: size)
        let x: CGFloat = (size.width - minSize + lineWidth) / 2
        let y: CGFloat = (size.height - minSize + lineWidth) / 2
        let path = Path(ellipseIn: CGRect(x: x, y: y, width: minSize - lineWidth, height: minSize - lineWidth))
        context.stroke(path, with: .color(placeholderColor), lineWidth: lineWidth)
    }
    
    private func drawHeadCircleShadow(
        context: GraphicsContext,
        circleSize: CGFloat,
        x: CGFloat,
        y: CGFloat,
        angle: Angle,
        progressAngle: Angle,
        stepAngle: Angle,
        path: Path
    ) {
        guard let headShadowRadius else { return }
        
        let nextAngle = progressAngle + stepAngle
        
        guard nextAngle > angle, nextAngle.degrees > 335 else { return }
        
        var context = context
        let tx = x + circleSize / 2
        let ty = y + circleSize / 2
        context.translateBy(x: tx, y: ty)
        var clipPath = Path()
        clipPath.move(to: .init(x: circleSize / -2, y: 0))
        clipPath.addLine(to: .init(x: circleSize / 2, y: 0))
        clipPath.addLine(to: .init(x: circleSize / 2, y: circleSize))
        clipPath.addLine(to: .init(x: circleSize / -2, y: circleSize))
        clipPath.closeSubpath()
        context.rotate(by: progressAngle)
        context.clip(to: clipPath)
        context.translateBy(x: -tx, y: -ty)
        
        let opacity: Double = min(1, (nextAngle.degrees - 335.0) / 25.0)
        context.addFilter(
            .shadow(
                color: Color(.sRGBLinear, white: 0, opacity: 0.33 * opacity),
                radius: headShadowRadius,
                options: .shadowOnly
            )
        )
        
        context.fill(path, with: .color(.black))
    }
    
    private func drawSymbol(
        context: GraphicsContext,
        circleSize: CGFloat,
        x: CGFloat,
        y: CGFloat,
        angle: Angle,
        progressAngle: Angle,
        stepAngle: Angle
    ) {
        let nextAngle = progressAngle + stepAngle
        
        guard nextAngle > angle, let symbol = context.resolveSymbol(id: 0) else { return }
        
        var context = context
        let tx = x + circleSize / 2
        let ty = y + circleSize / 2
        context.translateBy(x: tx, y: ty)
        context.rotate(by: (isSymbolRotating ? progressAngle : .zero) - rotationEffectAngle)
        
        context.draw(
            symbol,
            in: .init(x: circleSize / -2, y: circleSize / -2, width: circleSize, height: circleSize)
        )
    }
}

public extension RingProgressView where Symbol == EmptyView {
    init(
        progress: Binding<Double>,
        lineWidth: CGFloat = 30,
        startColor: Color = .blue,
        endColor: Color = .teal,
        placeholderColor: Color? = .blue.opacity(0.3),
        headShadowRadius: CGFloat? = 5,
        rotationEffectAngle: Angle = Angle(degrees: -90)
    ) {
        self.init(
            progress: progress,
            lineWidth: lineWidth,
            startColor: startColor,
            endColor: endColor,
            placeholderColor: placeholderColor,
            headShadowRadius: headShadowRadius,
            rotationEffectAngle: rotationEffectAngle
        ) {
            EmptyView()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProgressRingPreview()
    }
    #if os(macOS)
    .frame(height: 500)
    .frame(maxWidth: 400)
    #endif
    .colorScheme(.dark)
}

struct ProgressRingPreview: View {
    @State var degrees: Double = 0.75
    
    var body: some View {
        VStack {
            ZStack {
                ZStack {
                    RingProgressView(progress: $degrees) {
                        Image(systemName: "arrow.right")
                            .padding(8)
                    }
                    #if os(watchOS)
                    #endif
                    
                    #if !os(watchOS)
                    RingProgressView(
                        progress: $degrees,
                        startColor: .purple,
                        endColor: .pink,
                        placeholderColor: .purple.opacity(0.3)
                    ) {
                        Image(systemName: "arrow.right")
                            .padding(8)
                    }
                    .padding(32)
                    
                    RingProgressView(
                        progress: $degrees,
                        startColor: .green,
                        endColor: .orange,
                        placeholderColor: .green.opacity(0.3)
                    ) {
                        Image(systemName: "arrow.right")
                            .padding(8)
                    }
                    .padding(64)
                    #endif
                }
                #if os(watchOS)
                .frame(height: 150)
                #endif
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(degrees * 100))")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .numericTextTransition()
                        .animation(.bouncy, value: degrees)
                    Text("%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .offset(x: 6)
            }
            #if !os(watchOS)
            .padding(50)
            #endif
            
            Slider(value: $degrees, in: 0...2, step: 0.01)
                .padding()
        }
    }
}

extension View {
    func numericTextTransition() -> some View {
        if #available(iOS 16.0, macOS 13.0, watchOS 9, *) {
            return self.contentTransition(.numericText())
        }
        
        return self
    }
}
#endif
