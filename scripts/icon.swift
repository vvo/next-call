// Generates AppIcon.icns source PNG. Run: swift scripts/icon.swift, then scripts/make-icns.sh
import AppKit

let size: CGFloat = 1024
let midY = size / 2

let body = NSRect(x: 50, y: 175, width: 645, height: 674)
let bodyPath = NSBezierPath(roundedRect: body, xRadius: 90, yRadius: 90)

let lensApexX: CGFloat = 745
let lensRight: CGFloat = 945
let lensHalfH: CGFloat = 215
let lens = NSBezierPath()
lens.move(to: .init(x: lensApexX, y: midY))
lens.line(to: .init(x: lensRight, y: midY + lensHalfH))
lens.line(to: .init(x: lensRight, y: midY - lensHalfH))
lens.close()
let roundedLens = NSBezierPath(
    cgPath: lens.cgPath
        .copy(strokingWithWidth: 60, lineCap: .round, lineJoin: .round, miterLimit: 10)
        .union(lens.cgPath)
)

let shape = NSBezierPath()
shape.append(bodyPath)
shape.append(roundedLens)

func line(_ s: String, _ fontSize: CGFloat) -> NSAttributedString {
    var font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    if let desc = font.fontDescriptor.withDesign(.rounded), let r = NSFont(descriptor: desc, size: fontSize) {
        font = r
    }
    return NSAttributedString(string: s, attributes: [
        .font: font,
        .foregroundColor: NSColor.white,
        .kern: 4,
    ])
}

let fontSize: CGFloat = 295
let textCx = body.midX
let ne = line("NE", fontSize)
let xt = line("XT", fontSize)
let gap = -fontSize * 0.33
let totalH = ne.size().height + xt.size().height + gap
let blockTop = midY + totalH / 2

let img = NSImage(size: .init(width: size, height: size))
img.lockFocus()

NSGradient(
    starting: NSColor(srgbRed: 0.22, green: 0.45, blue: 1.00, alpha: 1),
    ending: NSColor(srgbRed: 0.05, green: 0.11, blue: 0.48, alpha: 1)
)!.draw(in: shape, angle: -70)

ne.draw(at: .init(x: textCx - ne.size().width / 2, y: blockTop - ne.size().height))
xt.draw(at: .init(x: textCx - xt.size().width / 2, y: blockTop - ne.size().height - gap - xt.size().height))

img.unlockFocus()

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "icon-1024.png"))
print("wrote icon-1024.png")
