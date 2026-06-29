import SwiftUI
import UIKit

// Light haptics (custom, no notifications/alerts).
enum GlyphHaptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    static func win() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
}

// All icons are custom Canvas/Shape drawings. No SF Symbols, no emoji.

// The app's rune mark — a diamond with an angular glyph, used in splash/settings.
struct GlyphMark: View {
    var size: CGFloat
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w * 0.5, cy = h * 0.5
            // outer ring
            ctx.stroke(Path(ellipseIn: CGRect(x: cx - w*0.40, y: cy - h*0.40, width: w*0.80, height: h*0.80)),
                       with: .color(GlyphTheme.violet), lineWidth: max(1.5, w*0.025))
            // diamond
            var dia = Path()
            dia.move(to: CGPoint(x: cx, y: cy - h*0.30))
            dia.addLine(to: CGPoint(x: cx + w*0.26, y: cy))
            dia.addLine(to: CGPoint(x: cx, y: cy + h*0.30))
            dia.addLine(to: CGPoint(x: cx - w*0.26, y: cy))
            dia.closeSubpath()
            ctx.stroke(dia, with: .color(GlyphTheme.ember), style: StrokeStyle(lineWidth: max(1.5, w*0.028), lineJoin: .round))
            // inner glyph zigzag
            var g = Path()
            g.move(to: CGPoint(x: cx - w*0.10, y: cy + h*0.12))
            g.addLine(to: CGPoint(x: cx + w*0.10, y: cy + h*0.12))
            g.addLine(to: CGPoint(x: cx - w*0.08, y: cy - h*0.02))
            g.addLine(to: CGPoint(x: cx + w*0.10, y: cy - h*0.02))
            g.addLine(to: CGPoint(x: cx - w*0.10, y: cy - h*0.14))
            ctx.stroke(g, with: .color(GlyphTheme.textPrimary),
                       style: StrokeStyle(lineWidth: max(1.5, w*0.03), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// Tab: Levels — a 2x2 grid of cells.
struct GlyphGridIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let s = w * 0.34
            let gap = w * 0.08
            let originX = (w - (s*2 + gap)) / 2
            let originY = (h - (s*2 + gap)) / 2
            for r in 0..<2 {
                for c in 0..<2 {
                    let rect = CGRect(x: originX + CGFloat(c)*(s+gap), y: originY + CGFloat(r)*(s+gap), width: s, height: s)
                    ctx.stroke(Path(roundedRect: rect, cornerRadius: s*0.22), with: .color(color), lineWidth: max(1.4, w*0.06))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// Tab: Guide — a simple book.
struct GlyphBookIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let left = Path(roundedRect: CGRect(x: w*0.14, y: h*0.22, width: w*0.36, height: h*0.56), cornerRadius: w*0.04)
            let right = Path(roundedRect: CGRect(x: w*0.50, y: h*0.22, width: w*0.36, height: h*0.56), cornerRadius: w*0.04)
            ctx.stroke(left, with: .color(color), lineWidth: max(1.3, w*0.05))
            ctx.stroke(right, with: .color(color.opacity(0.8)), lineWidth: max(1.3, w*0.05))
            var spine = Path(); spine.move(to: CGPoint(x: w*0.5, y: h*0.22)); spine.addLine(to: CGPoint(x: w*0.5, y: h*0.78))
            ctx.stroke(spine, with: .color(color), lineWidth: max(1.3, w*0.05))
        }
        .frame(width: size, height: size)
    }
}

// Tab: Settings — gear.
struct GlyphGearIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w*0.5, cy = h*0.5
            let outer = min(w, h)*0.36
            let teeth = 8
            var gear = Path()
            for i in 0..<(teeth*2) {
                let a = Double(i)/Double(teeth*2) * 2 * .pi
                let rr = (i % 2 == 0) ? outer : outer*0.72
                let pt = CGPoint(x: cx + CGFloat(rr)*CGFloat(cos(a)), y: cy + CGFloat(rr)*CGFloat(sin(a)))
                if i == 0 { gear.move(to: pt) } else { gear.addLine(to: pt) }
            }
            gear.closeSubpath()
            ctx.stroke(gear, with: .color(color), lineWidth: max(1.3, w*0.05))
            let ir = outer*0.40
            ctx.stroke(Path(ellipseIn: CGRect(x: cx-ir, y: cy-ir, width: ir*2, height: ir*2)),
                       with: .color(color), lineWidth: max(1.3, w*0.05))
        }
        .frame(width: size, height: size)
    }
}

struct GlyphUndoIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w*0.52, cy = h*0.54
            let r = min(w, h)*0.30
            var arc = Path()
            arc.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                       startAngle: .degrees(200), endAngle: .degrees(20), clockwise: false)
            ctx.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: max(1.6, w*0.08), lineCap: .round))
            let sx = cx + r*CGFloat(cos(200 * Double.pi/180))
            let sy = cy + r*CGFloat(sin(200 * Double.pi/180))
            var head = Path()
            head.move(to: CGPoint(x: sx - w*0.02, y: sy - h*0.14))
            head.addLine(to: CGPoint(x: sx - w*0.10, y: sy))
            head.addLine(to: CGPoint(x: sx + w*0.06, y: sy + h*0.04))
            ctx.stroke(head, with: .color(color), style: StrokeStyle(lineWidth: max(1.6, w*0.08), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct GlyphResetIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w*0.5, cy = h*0.52
            let r = min(w, h)*0.30
            var arc = Path()
            arc.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                       startAngle: .degrees(300), endAngle: .degrees(210), clockwise: true)
            ctx.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: max(1.6, w*0.08), lineCap: .round))
            let sx = cx + r*CGFloat(cos(300 * Double.pi/180))
            let sy = cy + r*CGFloat(sin(300 * Double.pi/180))
            var head = Path()
            head.move(to: CGPoint(x: sx + w*0.12, y: sy - h*0.04))
            head.addLine(to: CGPoint(x: sx, y: sy - h*0.14))
            head.addLine(to: CGPoint(x: sx - w*0.06, y: sy + h*0.0))
            ctx.stroke(head, with: .color(color), style: StrokeStyle(lineWidth: max(1.6, w*0.08), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct GlyphCheckIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var p = Path()
            p.move(to: CGPoint(x: w*0.24, y: h*0.54))
            p.addLine(to: CGPoint(x: w*0.42, y: h*0.72))
            p.addLine(to: CGPoint(x: w*0.78, y: h*0.30))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: max(1.8, w*0.12), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct GlyphLockIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let body = Path(roundedRect: CGRect(x: w*0.26, y: h*0.46, width: w*0.48, height: h*0.36), cornerRadius: w*0.07)
            ctx.fill(body, with: .color(color))
            var shackle = Path()
            shackle.addArc(center: CGPoint(x: w*0.5, y: h*0.46), radius: w*0.15,
                           startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            ctx.stroke(shackle, with: .color(color), lineWidth: max(1.5, w*0.07))
        }
        .frame(width: size, height: size)
    }
}

// A five-point star, filled (earned) or outlined (empty). No SF Symbols/emoji.
struct GlyphStarIcon: View {
    var size: CGFloat
    var filled: Bool
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w * 0.5, cy = h * 0.54
            let outer = min(w, h) * 0.46
            let inner = outer * 0.42
            var p = Path()
            for i in 0..<10 {
                let a = -Double.pi / 2 + Double(i) * (Double.pi / 5)
                let rr = (i % 2 == 0) ? outer : inner
                let pt = CGPoint(x: cx + CGFloat(rr) * CGFloat(cos(a)),
                                 y: cy + CGFloat(rr) * CGFloat(sin(a)))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            if filled {
                ctx.fill(p, with: .color(color))
            } else {
                ctx.stroke(p, with: .color(color),
                           style: StrokeStyle(lineWidth: max(1, w * 0.08), lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

// A row of up to 3 stars; `count` are filled.
struct GlyphStarRow: View {
    var count: Int
    var size: CGFloat
    var filledColor: Color = GlyphTheme.ember
    var emptyColor: Color = GlyphTheme.textFaint
    var spacing: CGFloat = 3
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { i in
                GlyphStarIcon(size: size, filled: i < count,
                              color: i < count ? filledColor : emptyColor)
            }
        }
    }
}

struct GlyphChevronIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var p = Path()
            p.move(to: CGPoint(x: w*0.38, y: h*0.24))
            p.addLine(to: CGPoint(x: w*0.66, y: h*0.5))
            p.addLine(to: CGPoint(x: w*0.38, y: h*0.76))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: max(1.4, w*0.09), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
