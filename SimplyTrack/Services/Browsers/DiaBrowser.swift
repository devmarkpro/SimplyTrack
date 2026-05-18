//
//  DiaBrowser.swift
//  SimplyTrack
//

import Foundation
import os.log

/// Dia-specific implementation of browser interface.
/// Handles URL detection for the Dia browser by The Browser Company.
/// Dia exposes a custom AppleScript interface with tab and URL support.
class DiaBrowser: BaseBrowser {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DiaBrowser")

    init() {
        super.init(bundleId: "company.thebrowser.dia", displayName: "Dia")
    }

    /// Dia-specific AppleScript for URL retrieval
    override var currentURLScript: String {
        return """
                tell application "Dia"
                    if (count of windows) > 0 then
                        return URL of active tab of window 1
                    end if
                end tell
            """
    }

    /// Checks if Dia is currently in incognito mode.
    /// Dia doesn't expose a private browsing property in its AppleScript dictionary,
    /// so we use the accessibility API to check the window's AXIdentifier which
    /// contains "bigIncognitoBrowserWindow" for private windows.
    override func isInPrivateBrowsingMode() -> Bool {
        let script = """
                tell application "System Events"
                    tell process "Dia"
                        if (count of windows) > 0 then
                            return value of attribute "AXIdentifier" of front window
                        end if
                    end tell
                end tell
            """

        let scriptResult = executeAppleScript(script)

        if let error = scriptResult.error {
            if scriptResult.errorCode == -1719 {
                logger.debug("Dia System Events transient error (invalid index): \(error.description)")
            } else if scriptResult.errorCode == -1743 || scriptResult.errorCode == -1744 {
                PermissionManager.shared.handleSystemEventsPermissionResult(success: false)
            } else if scriptResult.errorCode == -25211 {
                PermissionManager.shared.handleAccessibilityPermissionResult(success: false)
            } else {
                logger.error("Dia System Events AppleScript error: \(error.description)")
            }
            return false
        }

        if scriptResult.result != nil {
            PermissionManager.shared.handleSystemEventsPermissionResult(success: true)
            PermissionManager.shared.handleAccessibilityPermissionResult(success: true)
        }

        guard let identifier = scriptResult.result else {
            return false
        }

        return identifier.contains("Incognito")
    }
}
