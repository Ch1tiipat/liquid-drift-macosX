import Foundation

/// Decides which paths the spike may read or watch: the dummy scratch folder, the Claude Code
/// session folder computed from it, and single Codex transcript files below ~/.codex/sessions.
/// Comparison is an exact path-prefix match on symlink-resolved paths, never a substring match.
struct PathGuard {
    let scratch: String
    /// Session folders computed from the scratch path that exist on disk (resolved).
    let sessionDirs: [String]

    init?(scratchArgument: String) {
        guard let resolved = Self.resolve(scratchArgument),
              let tmp = Self.resolve(NSTemporaryDirectory()) else { return nil }
        let url = URL(fileURLWithPath: resolved)
        // The scratch folder must be a direct child of $TMPDIR whose name starts with "s006-".
        guard url.lastPathComponent.hasPrefix("s006-"),
              url.deletingLastPathComponent().path == tmp else { return nil }
        scratch = resolved
        let candidates = [scratchArgument, resolved].map(Self.claudeProjectDir(forWorkingDirectory:))
        var found: [String] = []
        for candidate in candidates {
            if let dir = Self.resolve(candidate), !found.contains(dir) { found.append(dir) }
        }
        sessionDirs = found
    }

    /// Claude Code project folder name: every character other than a letter or digit becomes "-"
    /// (documented rule, checked against a real run in S-006).
    static func claudeProjectDir(forWorkingDirectory cwd: String) -> String {
        let trimmed = cwd.hasSuffix("/") ? String(cwd.dropLast()) : cwd
        let encoded = String(trimmed.unicodeScalars.map {
            CharacterSet.alphanumerics.contains($0) && $0.isASCII ? Character($0) : "-"
        })
        return NSHomeDirectory() + "/.claude/projects/" + encoded
    }

    /// realpath(3): resolves symlinks; nil if the path does not exist.
    static func resolve(_ path: String) -> String? {
        guard let raw = realpath(path, nil) else { return nil }
        defer { free(raw) }
        return String(cString: raw)
    }

    /// One Codex transcript file: a .jsonl file below the resolved ~/.codex/sessions folder.
    /// Callers also check that the session's cwd is the scratch folder (see Hook).
    func allowsCodexTranscript(_ path: String) -> Bool {
        guard path.hasSuffix(".jsonl"),
              let root = Self.resolve(NSHomeDirectory() + "/.codex/sessions"),
              let resolved = Self.resolveFileOrParent(path) else { return false }
        return resolved.hasPrefix(root + "/")
    }

    /// The file may not exist yet when a hook names it; then resolve its folder and keep the name.
    static func resolveFileOrParent(_ path: String) -> String? {
        if let resolved = resolve(path) { return resolved }
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        guard !name.isEmpty, name != "..", name != ".",
              let parent = resolve(url.deletingLastPathComponent().path) else { return nil }
        return parent + "/" + name
    }

    func allows(_ path: String) -> Bool {
        guard let resolved = Self.resolve(path) else { return false }
        return ([scratch] + sessionDirs).contains { root in
            resolved == root || resolved.hasPrefix(root + "/")
        }
    }
}
