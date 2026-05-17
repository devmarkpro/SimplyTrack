//
//  DiaBrowser.swift
//  SimplyTrack
//

import Foundation

/// Dia-specific implementation of browser interface.
/// Handles URL detection for the Dia browser by The Browser Company.
/// Dia exposes a custom AppleScript interface with tab and URL support.
class DiaBrowser: BaseBrowser {

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

        guard let identifier = scriptResult.result else {
            return false
        }

        return identifier.contains("Incognito")
    }
}
