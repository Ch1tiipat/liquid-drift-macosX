import Foundation

/// The shape of one JSONL line: key names and a few enum-like values. Never holds text from a
/// prompt, a reply or a tool. Values are kept only for whitelisted keys and only if they look
/// like an enum (letters, digits, "_" or "-", 40 characters at most).
struct LineShape: Equatable {
    var topKeys: [String] = []
    var messageKeys: [String] = []
    var payloadKeys: [String] = []
    var enums: [String: String] = [:]
    /// Block types inside message.content, for example "text", "tool_use", "tool_result".
    var contentTypes: [String] = []

    static let enumKeys: Set<String> = ["type", "subtype", "role", "stop_reason", "level", "operation", "status"]
    static let maxLineBytes = 4 * 1024 * 1024

    init?(line: Data) {
        guard line.count <= Self.maxLineBytes,
              let object = try? JSONSerialization.jsonObject(with: line),
              let top = object as? [String: Any] else { return nil }
        topKeys = top.keys.sorted()
        Self.collectEnums(from: top, prefix: "", into: &enums)
        // Codex lines nest their data under "payload"; Claude Code lines under "message".
        if let payload = top["payload"] as? [String: Any] {
            payloadKeys = payload.keys.sorted()
            Self.collectEnums(from: payload, prefix: "payload.", into: &enums)
        }
        if let message = top["message"] as? [String: Any] {
            messageKeys = message.keys.sorted()
            Self.collectEnums(from: message, prefix: "message.", into: &enums)
            if let blocks = message["content"] as? [[String: Any]] {
                contentTypes = blocks.compactMap { ($0["type"] as? String).flatMap(Self.enumValue) }
            }
        }
    }

    private static func collectEnums(from dict: [String: Any], prefix: String, into result: inout [String: String]) {
        for key in enumKeys {
            if let value = dict[key] as? String, let safe = enumValue(value) {
                result[prefix + key] = safe
            } else if dict.keys.contains(key), dict[key] is NSNull {
                result[prefix + key] = "null"
            }
        }
    }

    private static func enumValue(_ value: String) -> String? {
        guard !value.isEmpty, value.count <= 40,
              value.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) && $0.isASCII || $0 == "_" || $0 == "-" })
        else { return nil }
        return value
    }

    var summary: String {
        let e = enums.keys.sorted().map { "\($0)=\(enums[$0] ?? "")" }.joined(separator: ",")
        return "keys=[\(topKeys.joined(separator: ","))] message=[\(messageKeys.joined(separator: ","))] payload=[\(payloadKeys.joined(separator: ","))] enums=[\(e)] content=[\(contentTypes.joined(separator: ","))]"
    }
}
