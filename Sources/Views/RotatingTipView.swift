import SwiftUI

struct RotatingTipView: View {
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @State private var currentIndex = 0

    private var tips: [String] { L10n.tips }

    private var safeIndex: Int {
        guard !tips.isEmpty else { return 0 }
        return currentIndex % tips.count
    }

    var body: some View {
        Group {
            if !tips.isEmpty {
                Text(tips[safeIndex])
                    .id("\(appLanguage)-\(safeIndex)")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .transition(.opacity)
            }
        }
        .opacity(0.45)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            advanceTip()
        }
        .task(id: currentIndex) {
            try? await Task.sleep(for: .seconds(7))
            guard !Task.isCancelled else { return }
            advanceTip()
        }
    }

    private func advanceTip() {
        guard !tips.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            currentIndex = (currentIndex + 1) % tips.count
        }
    }
}

#Preview {
    ZStack {
        AeroBackground()
        RotatingTipView()
            .padding()
    }
    .preferredColorScheme(.dark)
}
