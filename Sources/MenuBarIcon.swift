import AppKit

// Draws the app icon's camera (NE/XT punched out) as a template image,
// vector-drawn in the 1024 design space so it stays crisp on retina.
enum MenuBarIcon {
    static let image: NSImage = {
        let design = NSRect(x: 50, y: 175, width: 925, height: 674)
        let height: CGFloat = 15
        let size = NSSize(width: (height * design.width / design.height).rounded(), height: height)

        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current else { return false }
            let transform = NSAffineTransform()
            transform.scale(by: rect.height / design.height)
            transform.translateX(by: -design.minX, yBy: -design.minY)
            transform.concat()

            let midY: CGFloat = 512
            let body = NSRect(x: 50, y: 175, width: 645, height: 674)
            let bodyPath = NSBezierPath(roundedRect: body, xRadius: 90, yRadius: 90)

            let lens = NSBezierPath()
            lens.move(to: .init(x: 745, y: midY))
            lens.line(to: .init(x: 945, y: midY + 215))
            lens.line(to: .init(x: 945, y: midY - 215))
            lens.close()
            let roundedLens = NSBezierPath(
                cgPath: lens.cgPath
                    .copy(strokingWithWidth: 60, lineCap: .round, lineJoin: .round, miterLimit: 10)
                    .union(lens.cgPath)
            )

            NSColor.black.setFill()
            bodyPath.fill()
            roundedLens.fill()

            func line(_ s: String) -> NSAttributedString {
                let fontSize: CGFloat = 295
                var font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
                if let desc = font.fontDescriptor.withDesign(.rounded), let r = NSFont(descriptor: desc, size: fontSize) {
                    font = r
                }
                return NSAttributedString(string: s, attributes: [
                    .font: font,
                    .foregroundColor: NSColor.black,
                    .kern: 4,
                ])
            }

            ctx.compositingOperation = .destinationOut
            let ne = line("NE")
            let xt = line("XT")
            let gap: CGFloat = -295 * 0.33
            let totalH = ne.size().height + xt.size().height + gap
            let blockTop = midY + totalH / 2
            ne.draw(at: .init(x: body.midX - ne.size().width / 2, y: blockTop - ne.size().height))
            xt.draw(at: .init(x: body.midX - xt.size().width / 2, y: blockTop - ne.size().height - gap - xt.size().height))
            return true
        }
        image.isTemplate = true
        return image
    }()
}
