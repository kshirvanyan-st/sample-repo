import GrainfallCore
import SwiftUI

enum Theme {
    static let background = Color(rgba: Palette.background)
    static let panel = Color(red: 0.12, green: 0.13, blue: 0.21)
    static let sand = Color(rgba: Palette.shades(.sand)[0])
    static let text = Color(red: 0.92, green: 0.92, blue: 0.95)
    static let dim = Color(red: 0.62, green: 0.64, blue: 0.74)

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .monospaced) }
    static let body = Font.system(.body, design: .rounded).weight(.semibold)
}

extension Color {
    init(rgba c: RGBA) {
        self.init(red: Double(c.r) / 255, green: Double(c.g) / 255, blue: Double(c.b) / 255)
    }
}

extension Material {
    var color: Color { Color(rgba: Palette.shades(self)[0]) }

    var displayName: String {
        switch self {
        case .sand: return String(localized: "Sand")
        case .water: return String(localized: "Water")
        case .lava: return String(localized: "Lava")
        case .stone: return String(localized: "Stone")
        case .steam: return String(localized: "Steam")
        case .plant: return String(localized: "Plant")
        case .fire: return String(localized: "Fire")
        case .dirt: return String(localized: "Dirt")
        case .wall: return String(localized: "Wall")
        case .gate: return String(localized: "Gate")
        case .empty: return ""
        }
    }

    /// SF Symbol shown next to cup counters, so cups aren't identified by colour alone (PRD §6).
    var symbol: String {
        switch self {
        case .water: return "drop.fill"
        case .lava, .fire: return "flame.fill"
        case .stone: return "square.stack.3d.down.right.fill"
        case .plant: return "leaf.fill"
        case .steam: return "cloud.fill"
        default: return "circle.grid.3x3.fill"
        }
    }
}

/// Chunky pill button used across menus.
struct PixelButtonStyle: ButtonStyle {
    var tint: Color = Theme.sand
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .foregroundStyle(prominent ? Theme.background : Theme.text)
            .background(prominent ? tint : Theme.panel, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(prominent ? 0 : 0.6), lineWidth: 2))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StarsView: View {
    let stars: Int
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(i < stars ? Theme.sand : Theme.dim.opacity(0.5))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(stars) of 3 stars"))
    }
}
