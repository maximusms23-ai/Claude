-- safari_current_page.applescript — shortcuts-forge Helper (AppleScript)
--
-- Zweck:
--     Liefert URL und Titel des vordersten Safari-Tabs, getrennt durch TAB.
--     Referenz fuer klassische App-Automation aus Kurzbefehlen heraus.
--
-- Usage (aus Kurzbefehl via "Run Shell Script" oder Terminal):
--     osascript "$HOME/Documents/Tom-Shortcuts/helpers/applescript/safari_current_page.applescript"
--
-- Output:
--     https://example.org<TAB>Beispiel-Seite
--
-- Hinweis:
--     Erster Aufruf triggert einmalig den macOS-Automation-Consent
--     (Shortcuts/Terminal -> Safari steuern). Read-only, keine Seiten-Aenderung.

on run
	if application "Safari" is not running then
		error "Safari laeuft nicht" number 1
	end if
	tell application "Safari"
		if (count of windows) is 0 then
			error "Kein Safari-Fenster offen" number 2
		end if
		set theTab to current tab of front window
		set theURL to URL of theTab
		set theTitle to name of theTab
	end tell
	return theURL & tab & theTitle
end run
