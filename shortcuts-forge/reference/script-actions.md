# Ground-Truth: Skript-Actions (runshellscript / runapplescript)

**Quelle:** Cherri-Compiler-Output, kompiliert + verifiziert 2026-07-19.
**Zweck:** Der shortcuts-playground Builder-Agent kennt für `is.workflow.actions.runshellscript` und `is.workflow.actions.runapplescript` keine Parameter-Struktur aus seiner KB. Dieses File liefert die exakte, funktionierende Action-Struktur. Headless-Builds (`tom-shortcut build`) verweisen den Agent per Prompt hierauf.

**Hinweis:** Bewusst als Markdown, nicht als `.xml` — der PostToolUse-Validator des Plugins würde eine Shortcut-artige XML-Datei als unvollständigen Shortcut ablehnen (fehlende Comments/Icon/InputClasses). Die Snippets hier sind **nur die Action-Dicts**, einzubetten in einen sonst vollständigen Shortcut nach Plugin-Konvention.

## Parameter

| Key | Pflicht | Bedeutung |
|---|---|---|
| `Script` | ja | Shell-Kommando bzw. AppleScript-Quelltext als String |
| `Input` | nein | `WFTextTokenAttachment` auf `ShortcutInput` (`ExtensionInput`) — weglassen, wenn keine Eingabe gebraucht wird. Wenn gesetzt: Workflow braucht `WFWorkflowHasShortcutInputVariables=true` + gefüllte `WFWorkflowInputContentItemClasses` |
| `Shell` | nein | nur runshellscript; Default `/bin/zsh` |
| `InputMode` | nein | nur runshellscript; Default `to stdin`, Alternative `as arguments` |

## Run Shell Script

```xml
<dict>
	<key>WFWorkflowActionIdentifier</key>
	<string>is.workflow.actions.runshellscript</string>
	<key>WFWorkflowActionParameters</key>
	<dict>
		<key>Input</key>
		<dict>
			<key>Value</key>
			<dict>
				<key>Type</key>
				<string>ExtensionInput</string>
				<key>VariableName</key>
				<string>ShortcutInput</string>
			</dict>
			<key>WFSerializationType</key>
			<string>WFTextTokenAttachment</string>
		</dict>
		<key>Script</key>
		<string>echo tom | $HOME/Documents/Tom-Shortcuts/helpers/python/text_tools.py --mode upper</string>
	</dict>
</dict>
```

## Run AppleScript

```xml
<dict>
	<key>WFWorkflowActionIdentifier</key>
	<string>is.workflow.actions.runapplescript</string>
	<key>WFWorkflowActionParameters</key>
	<dict>
		<key>Input</key>
		<dict>
			<key>Value</key>
			<dict>
				<key>Type</key>
				<string>ExtensionInput</string>
				<key>VariableName</key>
				<string>ShortcutInput</string>
			</dict>
			<key>WFSerializationType</key>
			<string>WFTextTokenAttachment</string>
		</dict>
		<key>Script</key>
		<string>tell application "Safari" to get URL of current tab of front window</string>
	</dict>
</dict>
```

## Output der Action nutzen

Das Ergebnis (stdout) referenziert man wie jede Action-Output-Variable: `OutputUUID` an der Skript-Action setzen und in Folge-Actions per `attachmentsByRange`-Token einbinden (siehe Plugin-KB `VARIABLES.md`).
