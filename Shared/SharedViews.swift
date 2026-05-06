import SwiftUI

/// A coloured badge displaying a TCL line code.
struct LineTag: View {
    let line: String

    private var color: Color {
        switch line.first?.uppercased() {
        case "A": return .red
        case "B": return .blue
        case "C": return .cyan
        case "T": return .green
        case "M": return Color(red: 0.5, green: 0, blue: 0.5)
        default:  return .orange
        }
    }

    var body: some View {
        Text(line)
            .font(.caption2).fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color, in: RoundedRectangle(cornerRadius: 4))
            .minimumScaleFactor(0.7)
    }
}
