import AVFoundation
import Speech
import SwiftUI

@MainActor
final class SpeechManager: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String? = nil

    @AppStorage("appLanguage") private var appLanguage = "tr"

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStoppingManually = false
    private var isRequestingPermissions = false

    func requestPermissionsAndStart() {
        guard !isRecording, !isRequestingPermissions else { return }

        errorMessage = nil
        isRequestingPermissions = true

        Task {
            defer { isRequestingPermissions = false }

            let speechStatus = await requestSpeechAuthorization()
            guard speechStatus == .authorized else {
                errorMessage = L10n.speechPermissionDenied
                isRecording = false
                return
            }

            let micGranted = await AVAudioApplication.requestRecordPermission()
            guard micGranted else {
                errorMessage = L10n.microphonePermissionDenied
                isRecording = false
                return
            }

            startRecording()
        }
    }

    func stopRecording() {
        isStoppingManually = true
        tearDownSession(deactivateAudioSession: true)
    }

    // MARK: - Private Recording Flow

    private func startRecording() {
        tearDownSession(deactivateAudioSession: false)

        let localeIdentifier = appLanguage == "tr" ? "tr-TR" : "en-US"
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)),
              recognizer.isAvailable else {
            errorMessage = L10n.speechRecognizerUnavailable
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                tearDownSession(deactivateAudioSession: true)
                errorMessage = L10n.speechAudioError
                return
            }

            Self.installAudioTap(on: inputNode, format: recordingFormat, request: request)

            audioEngine.prepare()
            try audioEngine.start()

            transcript = ""
            errorMessage = nil
            isStoppingManually = false
            isRecording = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let formattedText = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                let hasError = error != nil

                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if let formattedText {
                        self.transcript = formattedText
                    }

                    if hasError || isFinal {
                        let wasManualStop = self.isStoppingManually
                        self.tearDownSession(deactivateAudioSession: true)

                        if hasError && !wasManualStop && self.transcript.isEmpty {
                            self.errorMessage = L10n.speechAudioError
                        }
                    }
                }
            }
        } catch {
            tearDownSession(deactivateAudioSession: true)
            errorMessage = L10n.speechAudioError
        }
    }

    private func tearDownSession(deactivateAudioSession: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        if deactivateAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        isRecording = false
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private nonisolated static func installAudioTap(
        on inputNode: AVAudioInputNode,
        format: AVAudioFormat,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }
}
