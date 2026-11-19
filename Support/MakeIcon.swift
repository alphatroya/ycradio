// Renders the app icon: swift Support/MakeIcon.swift out-dir [variant]
// macOS grid: 1024 canvas, squircle inset, so no extra padding is needed.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

func canvas() -> CGContext {
    let ctx = CGContext(
        data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    return ctx
}

/// macOS icon grid: content squircle inset in the canvas.
func squircle(_ ctx: CGContext, colors: [CGColor]) {
    let inset = S * 0.098
    let rect = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
    let path = CGPath(roundedRect: rect, cornerWidth: rect.width * 0.2237,
                      cornerHeight: rect.height * 0.2237, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -S * 0.012), blur: S * 0.03,
                  color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.28))
    ctx.addPath(path)
    ctx.setFillColor(colors[0])
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0),
                           options: [])
    ctx.restoreGState()
}

func circle(_ ctx: CGContext, _ center: CGPoint, _ r: CGFloat, _ color: CGColor) {
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
}

func arc(_ ctx: CGContext, _ center: CGPoint, _ r: CGFloat, _ width: CGFloat,
         _ color: CGColor, from: CGFloat = -60, to: CGFloat = 60) {
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.addArc(center: center, radius: r,
               startAngle: from * .pi / 180, endAngle: to * .pi / 180, clockwise: false)
    ctx.strokePath()
}

let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
let whiteSoft = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.55)

// A — broadcast: a dot sending waves, indigo to violet.
func variantWaves() -> CGContext {
    let ctx = canvas()
    squircle(ctx, colors: [rgb(0x3D3AA8), rgb(0x8E4BD8)])
    let origin = CGPoint(x: S * 0.30, y: S * 0.5)
    for (i, r) in [0.17, 0.32, 0.47].enumerated() {
        arc(ctx, origin, S * r, S * 0.075, i == 2 ? whiteSoft : white)
    }
    circle(ctx, origin, S * 0.085, white)
    return ctx
}

// B — record: warm amber, white vinyl with a note-less label.
func variantRecord() -> CGContext {
    let ctx = canvas()
    squircle(ctx, colors: [rgb(0xF2A03C), rgb(0xC2432C)])
    let c = CGPoint(x: S / 2, y: S / 2)
    circle(ctx, c, S * 0.325, white)
    for r in [0.27, 0.235, 0.20] {
        ctx.setStrokeColor(CGColor(srgbRed: 0.76, green: 0.30, blue: 0.20, alpha: 0.35))
        ctx.setLineWidth(S * 0.012)
        ctx.addArc(center: c, radius: S * CGFloat(r), startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.strokePath()
    }
    circle(ctx, c, S * 0.115, rgb(0xC2432C))
    circle(ctx, c, S * 0.035, rgb(0xF2A03C))
    return ctx
}

// C — tuning dial: cream, thin concentric arcs and a needle.
func variantDial() -> CGContext {
    let ctx = canvas()
    squircle(ctx, colors: [rgb(0xF6EFE2), rgb(0xE3D3B6)])
    let c = CGPoint(x: S / 2, y: S * 0.44)
    let ink = rgb(0x26374B)
    for (i, r) in [0.30, 0.22].enumerated() {
        ctx.setStrokeColor(i == 0 ? ink : CGColor(srgbRed: 0.15, green: 0.22, blue: 0.29, alpha: 0.35))
        ctx.setLineWidth(S * (i == 0 ? 0.045 : 0.028))
        ctx.addArc(center: c, radius: S * CGFloat(r), startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.strokePath()
    }
    // needle
    ctx.setStrokeColor(rgb(0xD2542B))
    ctx.setLineWidth(S * 0.045)
    ctx.setLineCap(.round)
    ctx.move(to: c)
    ctx.addLine(to: CGPoint(x: c.x + S * 0.21, y: c.y + S * 0.15))
    ctx.strokePath()
    circle(ctx, c, S * 0.06, ink)
    return ctx
}

let variants: [(String, () -> CGContext)] = [
    ("waves", variantWaves), ("record", variantRecord), ("dial", variantDial),
]

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let only = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
for (name, draw) in variants where only == nil || only == name {
    let ctx = draw()
    let image = ctx.makeImage()!
    let url = URL(fileURLWithPath: "\(out)/icon-\(name).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("write failed: \(url.path)") }
    print(url.path)
}
