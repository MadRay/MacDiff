import Foundation

/// Utilities for detecting and normalising JSON content before diffing.
enum JSONNormalizer {

    // MARK: - Public API

    /// Attempts to normalise `text` as JSON.
    ///
    /// - Returns: A tuple where `normalized` is the pretty-printed,
    ///   key-sorted JSON string (or the original `text` on failure),
    ///   and `wasJSON` is `true` only when the input was valid JSON.
    static func process(_ text: String) -> (normalized: String, wasJSON: Bool) {
        guard let data = text.data(using: .utf8) else { return (text, false) }
        return normalise(data: data, original: text)
    }

    /// Convenience overload that reads a file URL directly.
    static func process(url: URL) -> (normalized: String, wasJSON: Bool) {
        guard let data = try? Data(contentsOf: url),
              let raw  = String(data: data, encoding: .utf8)
        else { return ("", false) }

        let result = normalise(data: data, original: raw)
        return result
    }

    // MARK: - Private helpers

    private static func normalise(data: Data, original: String) -> (normalized: String, wasJSON: Bool) {
        // Quick early-exit: JSON must start with '{' or '[' (ignoring whitespace)
        guard looksLikeJSON(original) else { return (original, false) }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
            let prettyData = try JSONSerialization.data(withJSONObject: obj, options: options)
            guard let prettyString = String(data: prettyData, encoding: .utf8) else {
                return (original, false)
            }
            return (prettyString, true)
        } catch {
            // Not valid JSON — pass through as plain text
            return (original, false)
        }
    }

    /// Returns `true` if the trimmed string starts with `{` or `[`,
    /// which is a cheap guard before attempting full JSON parsing.
    private static func looksLikeJSON(_ text: String) -> Bool {
        guard let first = text.first(where: { !$0.isWhitespace }) else { return false }
        return first == "{" || first == "["
    }
}
