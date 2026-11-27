import Foundation

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

// MARK: - SubscriptionTextParser

final class SubscriptionTextParser: Sendable {
    static let shared = SubscriptionTextParser()

    private init() {}

    /// Parses spoken dictation text into subscription fields.
    func parseText(_ text: String) -> ParsedSubscription {
        var result = ParsedSubscription()

        // 1. Extract date first and remove matched date phrases from text
        let dateExtraction = extractDateAndRanges(from: text)
        result.nextBillingDate = dateExtraction.date
        let textWithoutDate = maskRanges(dateExtraction.ranges, in: text)

        if let matchedService = matchService(in: text) {
            result.name = matchedService.name
            result.iconName = matchedService.iconName
            result.colorHex = matchedService.colorHex
        } else {
            result.name = extractFirstMeaningfulWord(from: textWithoutDate)
        }

        result.price = extractPrice(from: textWithoutDate)
        result.billingCycle = extractBillingCycle(from: text)
        result.isFreeTrial = detectFreeTrial(in: text)

        return result
    }

    // MARK: - 1. Service Match & Fallback Name

    private static let catalogAliases: [(keyword: String, catalogName: String)] = [
        ("youtube", "YouTube Premium"),
        ("chatgpt", "ChatGPT Plus"),
        ("gemini", "Gemini"),
        ("claude", "Claude"),
        ("xbox", "Xbox Game Pass"),
        ("playstation", "PlayStation Plus"),
        ("ps plus", "PlayStation Plus"),
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

        // Pass 2: Substring fallback for longer multi-word names
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

    private func extractFirstMeaningfulWord(from textWithoutDate: String) -> String? {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols)
        let tokens = textWithoutDate.components(separatedBy: separators)

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

    private func extractPrice(from textWithoutDate: String) -> Double? {
        let normalized = normalizeSpokenNumbers(in: textWithoutDate)

        // Extract all numbers using (\d+(?:\.\d{1,2})?)
        let pattern = "(\\d+(?:\\.\\d{1,2})?)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let nsText = normalized as NSString
        let matches = regex.matches(in: normalized, range: NSRange(location: 0, length: nsText.length))

        var candidates: [(raw: String, value: Double)] = []
        for match in matches {
            let raw = nsText.substring(with: match.range(at: 1))
            if let value = Double(raw), value > 0 {
                candidates.append((raw, value))
            }
        }

        // Prefer decimal amounts (e.g. 10.99, 229.99) first; otherwise pick the last positive number
        if let decimalMatch = candidates.last(where: { $0.raw.contains(".") }) {
            return decimalMatch.value
        }
        return candidates.last?.value
    }

    private func normalizeSpokenNumbers(in text: String) -> String {
        var normalized = text

        // Remove storage unit quantities so e.g. "50 GB" isn't mistaken for price
        normalized = replacingRegex(
            pattern: "(?<![\\d.,])\\d+\\s*(?:GB|TB|MB)(?![\\p{L}\\p{N}])",
            in: normalized,
            with: " ",
            options: [.caseInsensitive]
        )

        // Handle thousands dot + comma decimal (e.g. "1.299,90" -> "1299.90")
        normalized = replacingRegex(
            pattern: "(?<!\\d)(\\d{1,3})\\.(\\d{3}),(\\d{1,2})(?!\\d)",
            in: normalized,
            with: "$1$2.$3"
        )

        // Handle standalone thousands dot without decimals (e.g. "1.200" -> "1200")
        normalized = replacingRegex(
            pattern: "(?<![\\d.])(\\d{1,3})\\.(\\d{3})(?![\\d.])",
            in: normalized,
            with: "$1$2"
        )

        // Replace spoken currency cents (e.g. "229 lira 99 kuruş" -> "229.99")
        normalized = replacingRegex(
            pattern: "(\\d+)\\s*(?:lira|tl|dolar|dollars?|euro|sterlin|pounds?)\\s*(\\d{1,2})(?:\\s*(?:kuruş|kurus|sent|cents?))?(?![\\p{L}\\d])",
            in: normalized,
            with: "$1.$2",
            options: [.caseInsensitive]
        )

        // Replace spoken decimal words (" nokta ", " virgül ", " point ") with "."
        normalized = replacingRegex(
            pattern: "\\s+(?:nokta|virg[uü]l|point)\\s+",
            in: normalized,
            with: ".",
            options: [.caseInsensitive]
        )

        // Replace commas between digits ("10,99" -> "10.99")
        normalized = replacingRegex(
            pattern: "(\\d),(\\d)",
            in: normalized,
            with: "$1.$2"
        )

        // Collapse spaces around dots between digits ("10 . 99" -> "10.99")
        normalized = replacingRegex(
            pattern: "(\\d)\\s*\\.\\s*(\\d)",
            in: normalized,
            with: "$1.$2"
        )

        // Join space-separated two-digit cents (e.g. "10 99" -> "10.99")
        normalized = replacingRegex(
            pattern: "(?<![\\d.])(\\d+)\\s+(\\d{2})(?![\\d.])",
            in: normalized,
            with: "$1.$2"
        )

        return normalized
    }

    private func replacingRegex(
        pattern: String,
        in text: String,
        with template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
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
            let rawSnippet = nsText.substring(with: match.range)
            let snippet = rawSnippet.trimmingCharacters(in: .whitespacesAndNewlines)

            if firstRegexMatch(pattern: "^\\d{1,2}:\\d{2}(?:\\s*[ap]m)?$", in: snippet, options: [.caseInsensitive]) != nil {
                continue
            }

            // Prevent NSDataDetector from swallowing a trailing 1-2 digit price after "27 Kasım" / "Nov 27"
            var effectiveRange = match.range
            if let trimmedMatch = firstRegexMatch(
                pattern: "^\\s*(\\d{1,2}\\s+[\\p{L}]{3,}|[\\p{L}]{3,}\\s+\\d{1,2})\\s+\\d{1,2}\\s*$",
                in: rawSnippet
            ) {
                let prefixRange = trimmedMatch.range(at: 1)
                effectiveRange = NSRange(location: match.range.location + prefixRange.location, length: prefixRange.length)
            }

            candidates.append((date, effectiveRange))
        }

        guard !candidates.isEmpty else { return nil }
        let chosen = candidates.first(where: { $0.date >= startOfToday }) ?? candidates.first
        return (chosen?.date, candidates.map { $0.range })
    }

    private func extractDateWithRegexFallback(in text: String) -> (date: Date?, ranges: [NSRange]) {
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
