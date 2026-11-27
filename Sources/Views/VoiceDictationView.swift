import SwiftUI

struct VoiceDictationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguage = "tr"

    @StateObject private var speechManager = SpeechManager()
    @State private var exampleIndex = 0
    @State private var isPulsing = false

    let onComplete: (ParsedSubscription) -> Void

    private var examples: [(brand: String, colorHex: String, price: String)] {
        L10n.dictationExamples
    }

    private var formattedTodayDate: String {
        let formatter = DateFormatter()
        if appLanguage == "tr" {
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = "d MMMM"
        } else {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: .now)
    }

    private var safeExampleIndex: Int {
        guard !examples.isEmpty else { return 0 }
        return exampleIndex % examples.count
    }

    private var hasTranscript: Bool {
        !speechManager.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            // Fullscreen soft blur + dark/lavender translucent tint
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            (colorScheme == .dark
                ? Color(hex: 0x12071F).opacity(0.55)
                : Color(hex: 0xEDE5F8).opacity(0.60))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar (Close button)
                HStack {
                    Spacer()
                    Button {
                        speechManager.stopRecording()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(colorScheme == .dark ? 0.2 : 0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Center area: format hint + rotating brand examples OR live transcript
                centerContent
                    .padding(.horizontal, 28)

                Spacer()

                // Bottom area: Aero Mic button + pulsing ring + optional Done button
                bottomControls
                    .padding(.bottom, 44)
            }
        }
        .presentationBackground(.clear)
        .onAppear {
            speechManager.requestPermissionsAndStart()
        }
        .onDisappear {
            speechManager.stopRecording()
        }
        .onChange(of: speechManager.isRecording) { _, recording in
            if recording {
                isPulsing = true
            } else {
                isPulsing = false
            }
        }
    }

    // MARK: - Center Content

    @ViewBuilder
    private var centerContent: some View {
        if hasTranscript {
            Text(speechManager.transcript)
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: speechManager.transcript)
        } else if let error = speechManager.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "mic.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(error)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .aeroCard()
        } else {
            VStack(spacing: 16) {
                Text(L10n.dictationFormatHint)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.primary.opacity(0.45))

                if !examples.isEmpty {
                    let current = examples[safeExampleIndex]
                    (
                        Text(current.brand)
                            .foregroundColor(Color(hex: current.colorHex).opacity(0.75))
                        +
                        Text(", \(formattedTodayDate), \(current.price)")
                            .foregroundColor(Color.primary.opacity(0.45))
                    )
                    .id("\(appLanguage)-\(safeExampleIndex)")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                }
            }
            .task(id: exampleIndex) {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.45)) {
                    exampleIndex = (exampleIndex + 1) % max(examples.count, 1)
                }
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 18) {
            if speechManager.isRecording {
                Text(L10n.listening)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            ZStack {
                // Aero Microphone Button with Pulsing Ring (always centered)
                Button {
                    handleMicTap()
                } label: {
                    ZStack {
                        if speechManager.isRecording {
                            Circle()
                                .stroke(Color(hex: 0xA855F7).opacity(0.45), lineWidth: 2)
                                .frame(width: 84, height: 84)
                                .scaleEffect(isPulsing ? 1.28 : 1.0)
                                .opacity(isPulsing ? 0.0 : 0.85)
                                .animation(
                                    .easeInOut(duration: 1.4).repeatForever(autoreverses: false),
                                    value: isPulsing
                                )

                            Circle()
                                .fill(Color(hex: 0xA855F7).opacity(0.18))
                                .frame(width: 84, height: 84)
                                .scaleEffect(isPulsing ? 1.12 : 0.96)
                                .animation(
                                    .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                                    value: isPulsing
                                )
                        }

                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 74, height: 74)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(colorScheme == .dark ? 0.35 : 0.75),
                                                .white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )

                        Image(systemName: "mic.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(speechManager.isRecording ? Color(hex: 0xA855F7) : Color.primary)
                    }
                    .frame(width: 96, height: 96)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)

                if hasTranscript {
                    HStack {
                        Spacer()
                        Button {
                            finishDictation()
                        } label: {
                            Text(L10n.done)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(colorScheme == .dark ? 0.25 : 0.65), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.25), value: hasTranscript)
        }
    }

    // MARK: - Actions

    private func handleMicTap() {
        if speechManager.isRecording {
            if hasTranscript {
                finishDictation()
            } else {
                speechManager.stopRecording()
            }
        } else {
            speechManager.requestPermissionsAndStart()
        }
    }

    private func finishDictation() {
        let spokenText = speechManager.transcript
        speechManager.stopRecording()

        let parsed = SubscriptionTextParser.shared.parseText(spokenText)
        onComplete(parsed)
        dismiss()
    }
}

#Preview {
    VoiceDictationView { _ in }
        .preferredColorScheme(.dark)
}
