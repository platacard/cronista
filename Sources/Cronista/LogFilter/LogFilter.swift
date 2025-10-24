import Foundation

/// The entity to redact all known secret patterns from a log
class LogFilter {
    private var compiledPatterns: [Regex<Substring>] = []

    init() {
        loadPatterns()
    }

    func loadPatterns() {
        guard let fileURL = Bundle.module.url(forResource: "rules", withExtension: "json") else {
            print("⚠️ 'rules.json' not found in app bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(Rules.self, from: data)

            for (_, patternString) in decoded.rules.sorted(by: >) {
                if let regex = try? Regex<Substring>(patternString, as: Substring.self) {
                    compiledPatterns.append(regex)
                }
            }
        } catch {
            print("❌ Failed to load or decode regex rules: \(error)")
        }
    }

    func sanitize(_ text: String) -> String {
        var sanitized = text
        for pattern in compiledPatterns {
            sanitized = sanitized.replacing(pattern, with: "[REDACTED]")
        }
        return sanitized
    }
}

struct Rules: Decodable {
    let rules: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rules = try container.decode([String: String].self)
    }
}
