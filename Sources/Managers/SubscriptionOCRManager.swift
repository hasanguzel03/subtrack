import Foundation
import ImageIO
import UIKit
import Vision

// MARK: - Parsed Result

struct ParsedSubscription: Sendable {
    var name: String?
    var iconName: String?
    var price: Double?
    var billingCycle: String = "monthly"
    var nextBillingDate: Date?
    var isFreeTrial: Bool = false
}

// MARK: - OCR Error

enum SubscriptionOCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to read image data."
        }
    }
}

// MARK: - SubscriptionOCRManager

final class SubscriptionOCRManager: Sendable {
    static let shared = SubscriptionOCRManager()

    private init() {}

    func recognizeText(from image: UIImage) async throws -> ParsedSubscription {
        guard let cgImage = image.cgImage else {
            throw SubscriptionOCRError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let lines: [String] = try await Task.detached(priority: .userInitiated) {
            try autoreleasepool {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["tr-TR", "en-US"]

                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: orientation,
                    options: [:]
                )
                try handler.perform([request])

                let observations = request.results ?? []
                return observations.compactMap { $0.topCandidates(1).first?.string }
            }
        }.value

        let fullText = lines.joined(separator: "\n")
        return parseSubscription(from: fullText)
    }

    func parseSubscription(from text: String) -> ParsedSubscription {
        var result = ParsedSubscription()

        let matchedService = matchService(in: text)
        result.name = matchedService?.name
        result.iconName = matchedService?.iconName
        result.price = extractPrice(from: text)
        result.billingCycle = extractBillingCycle(from: text)
        result.isFreeTrial = detectFreeTrial(in: text)
        result.nextBillingDate = extractDate(from: text)

        return result
    }

    // MARK: - 1. Service Match

    private func matchService(in text: String) -> ServiceCatalogItem? {
        let sortedCatalog = serviceCatalog.sorted { $0.name.count > $1.name.count }

        // Pass 1: Word-boundary match for exact catalog names
        for item in sortedCatalog {
            let escaped = NSRegularExpression.escapedPattern(for: item.name)
            let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"
            if firstRegexMatch(pattern: pattern, in: text, options: [.caseInsensitive]) != nil {
                return item
            }
        }

        // Pass 2: Substring fallback for longer multi-word or glued OCR names
        for item in sortedCatalog where item.name.count >= 5 {
            if text.localizedCaseInsensitiveContains(item.name) {
                return item
            }
        }

        // Pass 3: Strip trailing '+' (e.g. "iCloud" -> "iCloud+", "Disney" -> "Disney+")
        for item in sortedCatalog where item.name.hasSuffix("+") {
            let baseName = String(item.name.dropLast())
            let escaped = NSRegularExpression.escapedPattern(for: baseName)
            let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"
            if firstRegexMatch(pattern: pattern, in: text, options: [.caseInsensitive]) != nil {
                return item
            }
        }

        return nil
    }

    // MARK: - 2. Price Extraction

    private func extractPrice(from text: String) -> Double? {
        let currency = "(?:₺|US\\$|\\$|€|£|(?<![\\p{L}\\p{N}])(?:TL|TRY|USD|EUR)(?![\\p{L}\\p{N}]))"
        let number = "(?<![\\d.,])(\\d{1,3}(?:[.,]\\d{3})*(?:[.,]\\d{1,2})?|\\d+(?:[.,]\\d{1,2})?)(?![\\d.,])"
        let pattern = "(?:\(currency)\\s*\(number)|\(number)\\s*\(currency))"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var candidates: [Double] = []
        for match in matches {
            for groupIndex in [1, 2] {
                let range = match.range(at: groupIndex)
                if range.location != NSNotFound {
                    let rawNumber = nsText.substring(with: range)
                    if let parsed = parseAmount(rawNumber) {
                        candidates.append(parsed)
                    }
                    break
                }
            }
        }

        return candidates.first(where: { $0 > 0 }) ?? candidates.first
    }

    private func parseAmount(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let dotCount = trimmed.filter { $0 == "." }.count
        let commaCount = trimmed.filter { $0 == "," }.count

        let normalized: String
        if dotCount > 0 && commaCount > 0 {
            // Both separators present: the last one is the decimal separator
            if let lastDot = trimmed.lastIndex(of: "."),
               let lastComma = trimmed.lastIndex(of: ",") {
                if lastComma > lastDot {
                    normalized = trimmed
                        .replacingOccurrences(of: ".", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                } else {
                    normalized = trimmed.replacingOccurrences(of: ",", with: "")
                }
            } else {
                normalized = trimmed
            }
        } else if commaCount == 1 {
            let parts = trimmed.split(separator: ",", omittingEmptySubsequences: false)
            if parts.count == 2 && parts[1].count == 3 {
                // Thousands separator (e.g. "1,200")
                normalized = trimmed.replacingOccurrences(of: ",", with: "")
            } else {
                normalized = trimmed.replacingOccurrences(of: ",", with: ".")
            }
        } else if dotCount == 1 {
            let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count == 2 && parts[1].count == 3 {
                // Thousands separator (e.g. "1.200")
                normalized = trimmed.replacingOccurrences(of: ".", with: "")
            } else {
                normalized = trimmed
            }
        } else {
            // Multiple of the same separator (e.g. "1.200.000")
            normalized = trimmed
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
        }

        return Double(normalized)
    }

    // MARK: - 3. Billing Cycle

    private func extractBillingCycle(from text: String) -> String {
        let trLower = text.lowercased(with: Locale(identifier: "tr_TR"))
        let enLower = text.lowercased(with: Locale(identifier: "en_US"))

        let turkishYearly = ["yıllık", "/yıl"]
        if turkishYearly.contains(where: { trLower.contains($0) }) {
            return "yearly"
        }

        if firstRegexMatch(pattern: "(?<![\\p{L}])yıl(?![\\p{L}])", in: trLower) != nil {
            return "yearly"
        }

        let englishYearly = ["annual", "yearly", "/yr", "/year"]
        if englishYearly.contains(where: { enLower.contains($0) }) {
            return "yearly"
        }

        return "monthly"
    }

    // MARK: - 4. Free Trial

    private func detectFreeTrial(in text: String) -> Bool {
        let trLower = text.lowercased(with: Locale(identifier: "tr_TR"))
        let enLower = text.lowercased(with: Locale(identifier: "en_US"))

        if trLower.contains("ücretsiz deneme") || trLower.contains("deneme") {
            return true
        }

        if enLower.contains("free trial") || enLower.contains("trial") {
            return true
        }

        return false
    }

    // MARK: - 5. Date Extraction

    private func extractDate(from text: String) -> Date? {
        if let detected = detectDateWithDataDetector(in: text) {
            return detected
        }
        return extractDateWithRegexFallback(in: text)
    }

    private func detectDateWithDataDetector(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let nsText = text as NSString
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let startOfToday = Calendar.current.startOfDay(for: .now)

        var candidates: [Date] = []
        for match in matches {
            guard let date = match.date else { continue }
            let snippet = nsText.substring(with: match.range)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Ignore standalone clock strings such as status bar "09:41"
            if firstRegexMatch(pattern: "^\\d{1,2}:\\d{2}(?:\\s*[ap]m)?$", in: snippet, options: [.caseInsensitive]) != nil {
                continue
            }

            candidates.append(date)
        }

        return candidates.first(where: { $0 >= startOfToday }) ?? candidates.first
    }

    private func extractDateWithRegexFallback(in text: String) -> Date? {
        // Numeric dd.MM.yyyy / dd/MM/yyyy / dd-MM-yyyy
        let numericPattern = "(?<!\\d)(\\d{1,2})[./-](\\d{1,2})[./-](\\d{2,4})(?!\\d)"
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            let calendar = Calendar.current

            for match in matches {
                guard let day = Int(nsText.substring(with: match.range(at: 1))),
                      let month = Int(nsText.substring(with: match.range(at: 2))),
                      var year = Int(nsText.substring(with: match.range(at: 3))),
                      (1...31).contains(day),
                      (1...12).contains(month) else {
                    continue
                }

                if year < 100 {
                    year += 2000
                }

                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = day

                if let date = calendar.date(from: components) {
                    return date
                }
            }
        }

        // Month-name fallback across Turkish and English locales (e.g. "12 Aralık 2026", "Dec 12, 2026")
        let candidatePatterns = [
            "(?<![\\p{L}\\d])\\d{1,2}\\s+[\\p{L}]{3,}\\s+\\d{4}(?!\\d)",
            "(?<![\\p{L}\\d])[\\p{L}]{3,}\\s+\\d{1,2},?\\s+\\d{4}(?!\\d)"
        ]

        var dateStrings: [String] = []
        let nsText = text as NSString
        for pattern in candidatePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
                for match in matches {
                    dateStrings.append(nsText.substring(with: match.range))
                }
            }
        }

        let localeFormats: [(locale: String, formats: [String])] = [
            ("tr_TR", ["d MMMM yyyy", "d MMM yyyy"]),
            ("en_US", ["MMMM d, yyyy", "MMM d, yyyy", "MMMM d yyyy", "MMM d yyyy", "d MMMM yyyy", "d MMM yyyy"])
        ]

        for (localeId, formats) in localeFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: localeId)
            formatter.isLenient = false

            for format in formats {
                formatter.dateFormat = format
                for candidate in dateStrings {
                    if let date = formatter.date(from: candidate) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Regex Utility

    private func firstRegexMatch(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        let nsText = text as NSString
        return regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length))
    }
}

// MARK: - UIImage.Orientation Mapping

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
