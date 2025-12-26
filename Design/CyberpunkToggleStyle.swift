import SwiftUI

// MARK: - Cyberpunk Toggle Style

/// Custom toggle style for cyberpunk aesthetic
struct CyberpunkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Theme.green.opacity(0.3) : Theme.slate700)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(configuration.isOn ? Theme.green : Theme.slate600, lineWidth: 1)
                )
                .frame(width: 40, height: 20)
                .overlay(
                    Circle()
                        .fill(configuration.isOn ? Theme.green : Theme.slate500)
                        .frame(width: 16, height: 16)
                        .offset(x: configuration.isOn ? 10 : -10),
                    alignment: .center
                )
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isOn)
        }
        .buttonStyle(.plain)
    }
}
