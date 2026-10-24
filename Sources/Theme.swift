import AppKit

public struct AureloTheme {
    // Graphite & Mint Palette
    // Deep graphite background with subtle cold tint
    public static let bgDark = NSColor(calibratedRed: 0.071, green: 0.075, blue: 0.086, alpha: 1.0) // #121316
    public static let bgGlass = NSColor(calibratedRed: 0.071, green: 0.075, blue: 0.086, alpha: 0.88)
    public static let surface = NSColor(calibratedRed: 0.106, green: 0.114, blue: 0.129, alpha: 1.0) // #1B1D21
    public static let surfaceHover = NSColor(calibratedRed: 0.141, green: 0.149, blue: 0.169, alpha: 1.0) // #24262B
    public static let border = NSColor(calibratedRed: 0.180, green: 0.192, blue: 0.216, alpha: 1.0) // #2E3137
    public static let borderFocus = NSColor(calibratedRed: 0.0, green: 0.96, blue: 0.627, alpha: 0.5)

    // Mint Emerald Accents
    public static let mint = NSColor(calibratedRed: 0.0, green: 0.961, blue: 0.627, alpha: 1.0) // #00F5A0
    public static let mintMuted = NSColor(calibratedRed: 0.063, green: 0.725, blue: 0.506, alpha: 1.0) // #10B981
    public static let mintSubtle = NSColor(calibratedRed: 0.0, green: 0.961, blue: 0.627, alpha: 0.15)
    public static let mintGlow = NSColor(calibratedRed: 0.0, green: 0.961, blue: 0.627, alpha: 0.35)

    // Text hierarchy
    public static let textPrimary = NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
    public static let textSecondary = NSColor(calibratedRed: 0.62, green: 0.65, blue: 0.71, alpha: 1.0)
    public static let textMuted = NSColor(calibratedRed: 0.42, green: 0.45, blue: 0.50, alpha: 1.0)

    // Functional colors
    public static let redDanger = NSColor(calibratedRed: 0.95, green: 0.28, blue: 0.32, alpha: 1.0)
    public static let blueInfo = NSColor(calibratedRed: 0.25, green: 0.62, blue: 0.98, alpha: 1.0)

    // Standard corner radius
    public static let radiusCard: CGFloat = 12.0
    public static let radiusButton: CGFloat = 8.0
    public static let radiusTray: CGFloat = 16.0
}
