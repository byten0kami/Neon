import Foundation
import os.log

/// Safer wrapper around os_log/Logger to enforce unified logging and privacy
/// Safer wrapper around os_log/Logger to enforce unified logging and privacy
struct Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.neon.tracker"
    
    static let network = Logger(subsystem: subsystem, category: "network")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let security = Logger(subsystem: subsystem, category: "security")
    static let general = Logger(subsystem: subsystem, category: "general")
    
    // MARK: - Privacy Level
    
    enum Privacy {
        case `public`
        case `private`
        case sensitive
        case auto
    }
    
    // MARK: - Convenience Wrappers
    
    /// Log network activity
    static func network(_ message: String, privacy: Privacy = .public) {
        log(logger: network, message: message, privacy: privacy)
    }
    
    /// Log database/persistence activity
    static func database(_ message: String, privacy: Privacy = .public) {
        log(logger: database, message: message, privacy: privacy)
    }
    
    /// Log UI events
    static func ui(_ message: String, privacy: Privacy = .public) {
        log(logger: ui, message: message, privacy: privacy)
    }
    
    /// Log AI interactions
    static func ai(_ message: String, privacy: Privacy = .public) {
        log(logger: ai, message: message, privacy: privacy)
    }

    /// Log Security events
    static func security(_ message: String, privacy: Privacy = .public) {
        log(logger: security, message: message, privacy: privacy)
    }
    
    private static func log(logger: Logger, message: String, privacy: Privacy) {
        switch privacy {
        case .public:
            logger.info("\(message, privacy: .public)")
        case .private:
            logger.info("\(message, privacy: .private)")
        case .sensitive:
            logger.info("\(message, privacy: .private)") // Map sensitive to private for OSLog
        case .auto:
            logger.info("\(message, privacy: .auto)")
        }
    }
}
// Extension to support our custom privacy levels if we needed more granularity, 
// but wrapping OSLogPrivacy is safer.

