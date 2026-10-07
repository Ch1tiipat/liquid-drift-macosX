import Foundation

enum AgentState: String {
    case working, waitingForUser, done, idle, unknown
}

protocol SessionClassifier {
    var state: AgentState { get }
    /// Returns the new state if this line changes it.
    mutating func feed(_ shape: LineShape) -> AgentState?
}

/// Option B classifier for Codex transcript lines, built from the S-006 Codex runs.
/// Working starts at `task_started`, except the one written while a session opens (right after
/// `session_meta`): that one waits for the first user message after `turn_context`.
/// User messages before `turn_context` are session context, not a prompt.
struct CodexClassifier: SessionClassifier {
    /// Keys every line carried in the S-006 runs (fingerprint).
    static let requiredKeys: Set<String> = ["timestamp", "type", "payload"]
    /// event_msg payload types seen in the S-006 runs. A new one gives unknown, not a guess.
    static let knownEvents: Set<String> = [
        "task_started", "task_complete", "turn_aborted", "item_completed", "token_count", "thread_settings_applied"
    ]

    private(set) var state: AgentState = .idle
    private var turnOpen = false
    private var lastType: String?

    mutating func feed(_ shape: LineShape) -> AgentState? {
        let old = state
        guard old != .unknown else { return nil }
        state = next(shape)
        return state == old ? nil : state
    }

    private mutating func next(_ shape: LineShape) -> AgentState {
        guard Self.requiredKeys.isSubset(of: shape.topKeys), let type = shape.enums["type"] else { return .unknown }
        let payloadType = shape.enums["payload.type"]
        defer { lastType = type }
        switch type {
        case "session_meta":
            turnOpen = false
            return .idle
        case "turn_context":
            turnOpen = true
            return state
        case "response_item":
            guard let payloadType else { return .unknown }
            if turnOpen, payloadType == "message", shape.enums["payload.role"] == "user" {
                turnOpen = false
                return .working
            }
            return state
        case "event_msg":
            guard let payloadType, Self.knownEvents.contains(payloadType) else { return .unknown }
            switch payloadType {
            case "task_started": return lastType == "session_meta" ? state : .working
            case "task_complete": return .done
            case "turn_aborted": return .idle
            default: return state
            }
        default:
            return state // other line types do not change the state
        }
    }
}

/// Option B classifier for Claude Code session lines. Reads only key names and enum-like values.
/// Any missing key it depends on gives .unknown, never a guess.
struct ClaudeClassifier: SessionClassifier {
    /// Keys every user and assistant line carried in the S-006 runs (fingerprint).
    static let requiredConversationKeys: Set<String> = ["type", "message", "timestamp", "sessionId", "uuid"]

    private(set) var state: AgentState = .idle

    mutating func feed(_ shape: LineShape) -> AgentState? {
        let old = state
        // Once a line fails the fingerprint, the file stays unknown: a half-understood format is not trusted.
        guard old != .unknown else { return nil }
        state = Self.next(after: state, shape: shape)
        return state == old ? nil : state
    }

    static func next(after current: AgentState, shape: LineShape) -> AgentState {
        guard let type = shape.enums["type"] else { return .unknown }
        switch type {
        case "user", "assistant":
            guard requiredConversationKeys.isSubset(of: shape.topKeys) else { return .unknown }
            guard let role = shape.enums["message.role"], role == type else { return .unknown }
            if type == "user" { return .working }
            // A missing stop_reason key is a format change, not "still streaming".
            guard shape.messageKeys.contains("stop_reason") else { return .unknown }
            switch shape.enums["message.stop_reason"] {
            case "tool_use", "null": return .working
            case "end_turn", "stop_sequence": return .done
            default: return .unknown
            }
        case "cost-state":
            // Seen only in the last lines of a file when the session exits (S-006 runs: 6 of 6 files),
            // also after Esc or a closed window, where no Stop line or hook came.
            return .idle
        default:
            return current // bookkeeping lines do not change the state
        }
    }
}
