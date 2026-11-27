import Foundation
import ImageIO
import UIKit
import Vision

// MARK: - Parsed Result

struct ParsedSubscription: Sendable {
    var name: String?
    var iconName: String?
    var colorHex: String?
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
        return parseText(fullText)
    }

    /// Shared smart parser used by both Screenshot OCR and Voice Dictation.
    func parseText(_ text: String) -> ParsedSubscription {
        var result = ParsedSubscription()

        let dateExtraction = extractDateAndRanges(from: text)
        result.nextBillingDate = dateExtraction.date

        if let matchedService = matchService(in: text) {
            result.name = matchedService.name
            result.iconName = matchedService.iconName
            result.colorHex = matchedService.colorHex
        } else {
            result.name = extractFirstMeaningfulWord(from: text, excluding: dateExtraction.ranges)
        }

        result.price = extractPrice(from: text, excluding: dateExtraction.ranges)
        result.billingCycle = extractBillingCycle(from: text)
        result.isFreeTrial = detectFreeTrial(in: text)

        return result
    }

    // MARK: - 1. Service Match & Fallback Name

    private static let catalogAliases: [(keyword: String, catalogName: String)] = [
        ("youtube", "YouTube Premium"),
        ("chatgpt", "ChatGPT Plus"),
        ("duolingo", "Duolingo Super"),
        ("xbox", "Xbox Game Pass"),
        ("playstation", "PlayStation Plus"),
        ("ps plus", "PlayStation Plus"),
        ("canva", "Canva Pro"),
        ("adobe", "Adobe Creative Cloud"),
        ("amazon", "Amazon Prime")
    ]

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

        // Pass 4: Spoken/short aliases (e.g. "YouTube 79,99" -> "YouTube Premium")
        for alias in Self.catalogAliases {
            let escaped = NSRegularExpression.escapedPattern(for: alias.keyword)
            let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"
            if firstRegexMatch(pattern: pattern, in: text, options: [.caseInsensitive]) != nil,
               let item = serviceCatalog.first(where: { $0.name == alias.catalogName }) {
                return item
            }
        }

        return nil
    }

    private func extractFirstMeaningfulWord(from text: String, excluding dateRanges: [NSRange]) -> String? {
        let masked = maskRanges(dateRanges, in: text)
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols)
        let tokens = masked.components(separatedBy: separators)

        for rawToken in tokens {
            let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
            guard token.count >= 2 else { continue }

            let hasLetter = token.unicodeScalars.contains { CharacterSet.letters.contains($0) }
            guard hasLetter else { continue }

            let trLower = token.lowercased(with: Locale(identifier: "tr_TR"))
            let enLower = token.lowercased(with: Locale(identifier: "en_US"))

            if Self.ignoredNameTokens.contains(trLower) || Self.ignoredNameTokens.contains(enLower) {
                continue
            }

            return token.prefix(1).uppercased(with: Locale.current) + token.dropFirst()
        }

        return nil
    }

    private static let ignoredNameTokens: Set<String> = [
        "tl", "try", "usd", "eur", "gbp",
        "ay", "aylık", "yıl", "yıllık", "month", "monthly", "year", "yearly", "annual", "yr",
        "ücretsiz", "deneme", "free", "trial",
        "ocak", "şubat", "mart", "nisan", "mayıs", "haziran",
        "temmuz", "ağustos", "eylül", "ekim", "kasım", "aralık",
        "oca", "şub", "mar", "nis", "may", "haz", "tem", "ağu", "eyl", "eki", "kas", "ara",
        "january", "february", "march", "april", "june", "july",
        "august", "september", "october", "november", "december",
        "jan", "feb", "apr", "aug", "sep", "oct", "nov", "dec"
    ]

    // MARK: - 2. Price Extraction

    private func extractPrice(from text: String, excluding dateRanges: [NSRange]) -> Double? {
        // 1. Prefer explicit currency-tagged prices
        let currency = "(?:₺|US\\$|\\$|€|£|(?<![\\p{L}\\p{N}])(?:TL|TRY|USD|EUR)(?![\\p{L}\\p{N}]))"
        let number = "(?<![\\d.,/])(\\d{1,3}(?:[.,]\\d{3})*(?:[.,]\\d{1,2})?|\\d+(?:[.,]\\d{1,2})?)(?![\\d.,/])"
        let currencyPattern = "(?:\(currency)\\s*\(number)|\(number)\\s*\(currency))"

        if let regex = try? NSRegularExpression(pattern: currencyPattern, options: [.caseInsensitive]) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

            var taggedCandidates: [Double] = []
            for match in matches {
                for groupIndex in [1, 2] {
                    let range = match.range(at: groupIndex)
                    if range.location != NSNotFound {
                        let rawNumber = nsText.substring(with: range)
                        if let parsed = parseAmount(rawNumber) {
                            taggedCandidates.append(parsed)
                        }
                        break
                    }
                }
            }

            if let positive = taggedCandidates.first(where: { $0 > 0 }) ?? taggedCandidates.first {
                return positive
            }
        }

        // 2. Fallback for dictation without currency symbol (e.g. "Spotify, 24 Kasım, 10.99")
        let masked = maskRanges(dateRanges, in: text)
        let bareNumberPattern = "(?<![\\d.,:/-])(\\d+(?:[.,]\\d{1,2})?)(?![\\d.,:/-]|\\s*(?:GB|TB|MB)(?![\\p{L}\\p{N}]))"
        if let regex = try? NSRegularExpression(pattern: bareNumberPattern, options: [.caseInsensitive]) {
            let nsText = masked as NSString
            let matches = regex.matches(in: masked, range: NSRange(location: 0, length: nsText.length))

            var bareCandidates: [Double] = []
            for match in matches {
                let raw = nsText.substring(with: match.range(at: 1))
                if let parsed = parseAmount(raw) {
                    bareCandidates.append(parsed)
                }
            }

            // Pick the last spoken numeric amount (after ignoring date numbers)
            if let last = bareCandidates.last {
                return last
            }
        }

        return nil
    }

    private func parseAmount(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let dotCount = trimmed.filter { $0 == "." }.count
        let commaCount = trimmed.filter { $0 == "," }.count

        let normalized: String
        if dotCount > 0 && commaCount > 0 {
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
                normalized = trimmed.replacingOccurrences(of: ",", with: "")
            } else {
                normalized = trimmed.replacingOccurrences(of: ",", with: ".")
            }
        } else if dotCount == 1 {
            let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count == 2 && parts[1].count == 3 {
                normalized = trimmed.replacingOccurrences(of: ".", with: "")
            } else {
                normalized = trimmed
            }
        } else {
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

    private func extractDateAndRanges(from text: String) -> (date: Date?, ranges: [NSRange]) {
        if let detectorResult = detectDateWithDataDetector(in: text), detectorResult.date != nil {
            return detectorResult
        }
        return extractDateWithRegexFallback(in: text)
    }

    private func detectDateWithDataDetector(in text: String) -> (date: Date?, ranges: [NSRange])? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let nsText = text as NSString
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        let startOfToday = Calendar.current.startOfDay(for: .now)

        var candidates: [(date: Date, range: NSRange)] = []
        for match in matches {
            guard let date = match.date else { continue }
            let snippet = nsText.substring(with: match.range)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Ignore standalone clock strings such as status bar "09:41"
            if firstRegexMatch(pattern: "^\\d{1,2}:\\d{2}(?:\\s*[ap]m)?$", in: snippet, options: [.caseInsensitive]) != nil {
                continue
            }

            candidates.append((date, match.range))
        }

        guard !candidates.isEmpty else { return nil }
        let chosen = candidates.first(where: { $0.date >= startOfToday }) ?? candidates.first
        return (chosen?.date, candidates.map { $0.range })
    }

    private func extractDateWithRegexFallback(in text: String) -> (date: Date?, ranges: [NSRange]) {
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
                    return (date, [match.range])
                }
            }
        }

        // Month-name fallback across Turkish and English locales (with or without year, e.g. "24 Kasım", "15 December", "12 Aralık 2026")
        let candidatePatterns = [
            "(?<![\\p{L}\\d])\\d{1,2}\\s+[\\p{L}]{3,}(?:\\s+\\d{4})?(?!\\d)",
            "(?<![\\p{L}\\d])[\\p{L}]{3,}\\s+\\d{1,2}(?:,?\\s+\\d{4})?(?!\\d)"
        ]

        let nsText = text as NSString
        var matchedCandidates: [(text: String, range: NSRange)] = []
        for pattern in candidatePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
                for match in matches {
                    matchedCandidates.append((nsText.substring(with: match.range), match.range))
                }
            }
        }

        let yearFormats: [(locale: String, formats: [String])] = [
            ("tr_TR", ["d MMMM yyyy", "d MMM yyyy"]),
            ("en_US", ["MMMM d, yyyy", "MMM d, yyyy", "MMMM d yyyy", "MMM d yyyy", "d MMMM yyyy", "d MMM yyyy"])
        ]

        for (localeId, formats) in yearFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: localeId)
            formatter.isLenient = false

            for format in formats {
                formatter.dateFormat = format
                for candidate in matchedCandidates {
                    if let date = formatter.date(from: candidate.text) {
                        return (date, [candidate.range])
                    }
                }
            }
        }

        let currentYear = Calendar.current.component(.year, from: .now)
        let yearlessFormats: [(locale: String, formats: [String])] = [
            ("tr_TR", ["d MMMM", "d MMM"]),
            ("en_US", ["d MMMM", "d MMM", "MMMM d", "MMM d"])
        ]

        for (localeId, formats) in yearlessFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: localeId)
            formatter.isLenient = false
            formatter.defaultDate = Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))

            for format in formats {
                formatter.dateFormat = format
                for candidate in matchedCandidates {
                    if let parsedDate = formatter.date(from: candidate.text) {
                        let resolved = resolveYearForYearlessDate(parsedDate)
                        return (resolved, [candidate.range])
                    }
                }
            }
        }

        return (nil, [])
    }

    private func resolveYearForYearlessDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let currentYear = calendar.component(.year, from: .now)

        let components = DateComponents(year: currentYear, month: month, day: day)
        return calendar.date(from: components) ?? date
    }

    // MARK: - String & Regex Utilities

    private func maskRanges(_ ranges: [NSRange], in text: String) -> String {
        guard !ranges.isEmpty else { return text }
        let mutable = NSMutableString(string: text)
        for range in ranges where range.location != NSNotFound && range.location + range.length <= mutable.length {
            let spaces = String(repeating: " ", count: range.length)
            mutable.replaceCharacters(in: range, with: spaces)
        }
        return mutable as String
    }

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
