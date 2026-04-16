#!/usr/bin/env swift

import AppKit
import Foundation

struct IconRenderer {
    let side: CGFloat

    func writePNG(to url: URL) throws {
        let size = Int(side.rounded())
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: size,
                pixelsHigh: size,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ),
            let context = NSGraphicsContext(bitmapImageRep: rep)
        else {
            throw NSError(domain: "IconRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create drawing context"])
        }

        rep.size = NSSize(width: side, height: side)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        draw()
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "IconRenderer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG data"])
        }

        try pngData.write(to: url)
    }

    private func draw() {
        let rect = CGRect(origin: .zero, size: CGSize(width: side, height: side))
        drawBackground(in: rect)
        drawCardStack(in: rect)
        drawCaptureBadge(in: rect)
    }

    private func drawBackground(in rect: CGRect) {
        let outer = rect.insetBy(dx: side * 0.055, dy: side * 0.055)
        let radius = outer.width * 0.24
        let path = NSBezierPath(roundedRect: outer, xRadius: radius, yRadius: radius)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.24)
        shadow.shadowBlurRadius = side * 0.08
        shadow.shadowOffset = NSSize(width: 0, height: -side * 0.03)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        let gradient = NSGradient(
            colorsAndLocations:
                (NSColor(srgbRed: 0.37, green: 0.77, blue: 0.98, alpha: 1.0), 0.0),
                (NSColor(srgbRed: 0.12, green: 0.42, blue: 0.90, alpha: 1.0), 0.48),
                (NSColor(srgbRed: 0.04, green: 0.11, blue: 0.28, alpha: 1.0), 1.0)
        )
        gradient?.draw(in: path, angle: -90)
        NSGraphicsContext.restoreGraphicsState()

        path.addClip()

        let glow = NSBezierPath(ovalIn: CGRect(
            x: outer.minX - side * 0.08,
            y: outer.maxY - side * 0.35,
            width: side * 0.56,
            height: side * 0.34
        ))
        NSColor(calibratedWhite: 1.0, alpha: 0.16).setFill()
        glow.fill()

        let shine = NSBezierPath(ovalIn: CGRect(
            x: outer.maxX - side * 0.38,
            y: outer.maxY - side * 0.26,
            width: side * 0.28,
            height: side * 0.18
        ))
        NSColor(calibratedWhite: 1.0, alpha: 0.12).setFill()
        shine.fill()
    }

    private func drawCardStack(in rect: CGRect) {
        let outer = rect.insetBy(dx: side * 0.055, dy: side * 0.055)

        let backCard = CGRect(
            x: outer.minX + outer.width * 0.16,
            y: outer.minY + outer.height * 0.28,
            width: outer.width * 0.52,
            height: outer.height * 0.50
        )
        let backPath = NSBezierPath(
            roundedRect: backCard,
            xRadius: backCard.width * 0.13,
            yRadius: backCard.width * 0.13
        )
        NSColor(calibratedWhite: 1.0, alpha: 0.18).setFill()
        backPath.fill()

        let frontCard = CGRect(
            x: outer.minX + outer.width * 0.24,
            y: outer.minY + outer.height * 0.18,
            width: outer.width * 0.54,
            height: outer.height * 0.58
        )
        let frontPath = NSBezierPath(
            roundedRect: frontCard,
            xRadius: frontCard.width * 0.15,
            yRadius: frontCard.width * 0.15
        )

        let cardShadow = NSShadow()
        cardShadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.22)
        cardShadow.shadowBlurRadius = side * 0.05
        cardShadow.shadowOffset = NSSize(width: 0, height: -side * 0.02)

        NSGraphicsContext.saveGraphicsState()
        cardShadow.set()
        NSColor(srgbRed: 0.06, green: 0.10, blue: 0.20, alpha: 1.0).setFill()
        frontPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        let screenInset = frontCard.width * 0.06
        let screenRect = frontCard.insetBy(dx: screenInset, dy: screenInset)
        let screenPath = NSBezierPath(
            roundedRect: screenRect,
            xRadius: screenRect.width * 0.10,
            yRadius: screenRect.width * 0.10
        )
        NSColor(srgbRed: 0.97, green: 0.98, blue: 1.0, alpha: 1.0).setFill()
        screenPath.fill()

        let headerRect = CGRect(
            x: screenRect.minX,
            y: screenRect.maxY - screenRect.height * 0.18,
            width: screenRect.width,
            height: screenRect.height * 0.18
        )
        let headerPath = NSBezierPath(
            roundedRect: headerRect,
            xRadius: screenRect.width * 0.10,
            yRadius: screenRect.width * 0.10
        )
        NSColor(srgbRed: 0.91, green: 0.94, blue: 0.98, alpha: 1.0).setFill()
        headerPath.fill()

        let indicatorY = headerRect.midY
        let indicatorRadius = side * 0.016
        drawCircle(center: CGPoint(x: headerRect.minX + screenRect.width * 0.10, y: indicatorY), radius: indicatorRadius, color: NSColor(srgbRed: 0.99, green: 0.59, blue: 0.26, alpha: 1.0))
        drawCircle(center: CGPoint(x: headerRect.minX + screenRect.width * 0.16, y: indicatorY), radius: indicatorRadius, color: NSColor(srgbRed: 0.95, green: 0.78, blue: 0.28, alpha: 1.0))
        drawCircle(center: CGPoint(x: headerRect.minX + screenRect.width * 0.22, y: indicatorY), radius: indicatorRadius, color: NSColor(srgbRed: 0.24, green: 0.83, blue: 0.56, alpha: 1.0))

        let sidebarRect = CGRect(
            x: screenRect.minX + screenRect.width * 0.07,
            y: screenRect.minY + screenRect.height * 0.12,
            width: screenRect.width * 0.14,
            height: screenRect.height * 0.56
        )
        let sidebarPath = NSBezierPath(
            roundedRect: sidebarRect,
            xRadius: sidebarRect.width * 0.35,
            yRadius: sidebarRect.width * 0.35
        )
        NSColor(srgbRed: 0.99, green: 0.83, blue: 0.32, alpha: 1.0).setFill()
        sidebarPath.fill()

        let previewRect = CGRect(
            x: screenRect.minX + screenRect.width * 0.28,
            y: screenRect.minY + screenRect.height * 0.16,
            width: screenRect.width * 0.57,
            height: screenRect.height * 0.46
        )
        let previewPath = NSBezierPath(
            roundedRect: previewRect,
            xRadius: previewRect.width * 0.10,
            yRadius: previewRect.width * 0.10
        )
        NSColor(srgbRed: 0.89, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
        previewPath.fill()

        let mountain = NSBezierPath()
        mountain.move(to: CGPoint(x: previewRect.minX, y: previewRect.minY + previewRect.height * 0.14))
        mountain.line(to: CGPoint(x: previewRect.minX + previewRect.width * 0.28, y: previewRect.minY + previewRect.height * 0.48))
        mountain.line(to: CGPoint(x: previewRect.minX + previewRect.width * 0.48, y: previewRect.minY + previewRect.height * 0.28))
        mountain.line(to: CGPoint(x: previewRect.maxX, y: previewRect.minY + previewRect.height * 0.58))
        mountain.line(to: CGPoint(x: previewRect.maxX, y: previewRect.minY))
        mountain.line(to: CGPoint(x: previewRect.minX, y: previewRect.minY))
        mountain.close()
        NSColor(srgbRed: 0.46, green: 0.78, blue: 0.96, alpha: 1.0).setFill()
        mountain.fill()

        drawCircle(
            center: CGPoint(x: previewRect.minX + previewRect.width * 0.18, y: previewRect.minY + previewRect.height * 0.70),
            radius: previewRect.width * 0.08,
            color: NSColor(srgbRed: 0.99, green: 0.78, blue: 0.27, alpha: 1.0)
        )

        drawCropCorners(around: previewRect)
    }

    private func drawCaptureBadge(in rect: CGRect) {
        let outer = rect.insetBy(dx: side * 0.055, dy: side * 0.055)
        let badgeRect = CGRect(
            x: outer.maxX - outer.width * 0.29,
            y: outer.minY + outer.height * 0.13,
            width: outer.width * 0.24,
            height: outer.width * 0.24
        )

        let badgeShadow = NSShadow()
        badgeShadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.24)
        badgeShadow.shadowBlurRadius = side * 0.035
        badgeShadow.shadowOffset = NSSize(width: 0, height: -side * 0.015)

        NSGraphicsContext.saveGraphicsState()
        badgeShadow.set()
        let badgePath = NSBezierPath(ovalIn: badgeRect)
        let badgeGradient = NSGradient(
            colorsAndLocations:
                (NSColor(srgbRed: 1.0, green: 0.83, blue: 0.29, alpha: 1.0), 0.0),
                (NSColor(srgbRed: 0.99, green: 0.56, blue: 0.20, alpha: 1.0), 1.0)
        )
        badgeGradient?.draw(in: badgePath, angle: -90)
        NSGraphicsContext.restoreGraphicsState()

        drawCameraGlyph(in: badgeRect.insetBy(dx: badgeRect.width * 0.22, dy: badgeRect.height * 0.22))
    }

    private func drawCameraGlyph(in rect: CGRect) {
        let bodyRect = CGRect(
            x: rect.minX,
            y: rect.minY + rect.height * 0.10,
            width: rect.width,
            height: rect.height * 0.62
        )
        let bodyPath = NSBezierPath(
            roundedRect: bodyRect,
            xRadius: bodyRect.width * 0.18,
            yRadius: bodyRect.width * 0.18
        )
        NSColor.white.setFill()
        bodyPath.fill()

        let topRect = CGRect(
            x: rect.minX + rect.width * 0.16,
            y: bodyRect.maxY - rect.height * 0.04,
            width: rect.width * 0.28,
            height: rect.height * 0.16
        )
        let topPath = NSBezierPath(
            roundedRect: topRect,
            xRadius: topRect.width * 0.30,
            yRadius: topRect.width * 0.30
        )
        topPath.fill()

        let lensRect = CGRect(
            x: bodyRect.midX - bodyRect.width * 0.19,
            y: bodyRect.midY - bodyRect.width * 0.19,
            width: bodyRect.width * 0.38,
            height: bodyRect.width * 0.38
        )
        let lensPath = NSBezierPath(ovalIn: lensRect)
        NSColor(srgbRed: 0.99, green: 0.60, blue: 0.25, alpha: 1.0).setFill()
        lensPath.fill()
    }

    private func drawCropCorners(around rect: CGRect) {
        let arm = min(rect.width, rect.height) * 0.20
        let path = NSBezierPath()
        path.lineWidth = side * 0.024
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.line(to: CGPoint(x: rect.minX + arm, y: rect.maxY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.line(to: CGPoint(x: rect.minX, y: rect.minY))
        path.line(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        NSColor(srgbRed: 0.99, green: 0.58, blue: 0.21, alpha: 1.0).setStroke()
        path.stroke()
    }

    private func drawCircle(center: CGPoint, radius: CGFloat, color: NSColor) {
        let circleRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let path = NSBezierPath(ovalIn: circleRect)
        color.setFill()
        path.fill()
    }
}

let outputDirPath = CommandLine.arguments.dropFirst().first ?? ""
guard !outputDirPath.isEmpty else {
    fputs("usage: generate-icon.swift <iconset-dir>\n", stderr)
    exit(1)
}

let outputDir = URL(fileURLWithPath: outputDirPath, isDirectory: true)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let iconFiles: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, size) in iconFiles {
    let destination = outputDir.appendingPathComponent(filename)
    try autoreleasepool {
        let renderer = IconRenderer(side: size)
        try renderer.writePNG(to: destination)
    }
}
