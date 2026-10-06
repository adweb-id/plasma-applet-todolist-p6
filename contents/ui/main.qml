import QtCore
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
	id: root

	NoteItem {
		id: noteItemObj
	}

	// Fall back to the default icon when the setting is empty.
	Plasmoid.icon: (Plasmoid.configuration.icon || "").trim() || "korg-todo"

	toolTipMainText: i18n("TodoList")
	toolTipSubText: noteItemObj.hasIncomplete
		? i18np("%1 item left", "%1 items left", noteItemObj.incompleteCount)
		: i18n("All done")

	compactRepresentation: MouseArea {
		id: compactRoot

		readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
			|| Plasmoid.location === PlasmaCore.Types.RightEdge
			|| Plasmoid.location === PlasmaCore.Types.BottomEdge
			|| Plasmoid.location === PlasmaCore.Types.LeftEdge)

		Layout.minimumWidth: {
			switch (Plasmoid.formFactor) {
			case PlasmaCore.Types.Vertical:
				return 0
			case PlasmaCore.Types.Horizontal:
				return height
			default:
				return Kirigami.Units.gridUnit * 3
			}
		}

		Layout.minimumHeight: {
			switch (Plasmoid.formFactor) {
			case PlasmaCore.Types.Vertical:
				return width
			case PlasmaCore.Types.Horizontal:
				return 0
			default:
				return Kirigami.Units.gridUnit * 3
			}
		}

		// Keep the compact icon square on a panel (don't let it stretch to
		// fill the panel length). Restores the original's iconSizeHints cap.
		Layout.maximumWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? compactRoot.height : -1
		Layout.maximumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? compactRoot.width : -1

		Kirigami.Icon {
			id: icon
			anchors.fill: parent
			source: Plasmoid.icon
		}

		IconCounterOverlay {
			anchors.fill: parent
			text: noteItemObj.hasIncomplete ? noteItemObj.incompleteCount : "✓"
			visible: {
				if (Plasmoid.configuration.showCounter === 'Never') {
					return false
				} else if (Plasmoid.configuration.showCounter === 'Incomplete') {
					return noteItemObj.hasIncomplete
				} else { // 'Always'
					return true
				}
			}
			heightRatio: Plasmoid.configuration.bigCounter ? 1 : 0.5
		}

		onClicked: root.expanded = !root.expanded
	}

	fullRepresentation: FullRepresentation {
		noteItem: noteItemObj
		isDesktopContainment: Plasmoid.location === PlasmaCore.Types.Floating
		// Popup open (always true on the desktop, where there is no popup).
		popupOpen: root.expanded || isDesktopContainment
		Plasmoid.backgroundHints: (Plasmoid.location === PlasmaCore.Types.Floating && !Plasmoid.configuration.showBackground)
			? PlasmaCore.Types.NoBackground
			: PlasmaCore.Types.DefaultBackground
	}

	Plasmoid.contextualActions: [
		PlasmaCore.Action {
			text: i18n("Add List")
			icon.name: "list-add"
			onTriggered: noteItemObj.addSection()
		},
		PlasmaCore.Action {
			text: i18n("Clear Completed")
			icon.name: "edit-clear-all"
			onTriggered: {
				noteItemObj.clearCompleted()
				root.expanded = true // show the result and its Undo
			}
		},
		PlasmaCore.Action {
			text: i18n("Export to File…")
			icon.name: "document-export"
			onTriggered: exportDialog.open()
		},
		PlasmaCore.Action {
			text: i18n("Import from File…")
			icon.name: "document-import"
			onTriggered: importDialog.open()
		},
		PlasmaCore.Action {
			text: i18n("Delete on Complete")
			// Not a checkbox: show a check icon when on, like the other items' icons.
			icon.name: Plasmoid.configuration.deleteOnComplete ? "checkmark" : ""
			onTriggered: Plasmoid.configuration.deleteOnComplete = !Plasmoid.configuration.deleteOnComplete
		},
		PlasmaCore.Action {
			text: i18n("Hide")
			// Not a checkbox: show a check icon when on, like the other items' icons.
			icon.name: Plasmoid.configuration.hidden ? "checkmark" : ""
			visible: Plasmoid.location === PlasmaCore.Types.Floating
			onTriggered: Plasmoid.configuration.hidden = !Plasmoid.configuration.hidden
		}
	]

	// ---- Export / import ----
	// Runs shell commands to write and read files (QML can't write files).
	Plasma5Support.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		property var callbacks: ({})
		onNewData: (sourceName, data) => {
			var callback = callbacks[sourceName]
			delete callbacks[sourceName]
			disconnectSource(sourceName)
			if (callback) {
				callback(data["exit code"], data["stdout"] || "", data["stderr"] || "")
			}
		}
		function run(cmd, callback) {
			callbacks[cmd] = callback
			connectSource(cmd)
		}
	}

	function shellQuote(str) {
		return "'" + String(str).replace(/'/g, "'\\''") + "'"
	}
	function urlToPath(url) {
		var str = url.toString()
		return str.startsWith("file://") ? decodeURIComponent(str.substring(7)) : str
	}

	FileDialog {
		id: exportDialog
		title: i18n("Export Tasks")
		fileMode: FileDialog.SaveFile
		defaultSuffix: "md"
		nameFilters: [i18n("Markdown files (*.md)"), i18n("Text files (*.txt)"), i18n("All files (*)")]
		currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		onAccepted: {
			var path = root.urlToPath(selectedFile)
			var text = noteItemObj.serializeTodoModel()
			executable.run("printf '%s' " + root.shellQuote(text) + " > " + root.shellQuote(path), function(code, out, err) {
				if (code === 0) {
					noteItemObj.notify(i18n("Exported tasks to %1", path), 'positive')
				} else {
					noteItemObj.notify(i18n("Could not export: %1", err.trim()), 'error')
				}
				root.expanded = true
			})
		}
	}

	FileDialog {
		id: importDialog
		title: i18n("Import Tasks")
		fileMode: FileDialog.OpenFile
		nameFilters: [i18n("Markdown files (*.md)"), i18n("Text files (*.txt)"), i18n("All files (*)")]
		currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		onAccepted: {
			var path = root.urlToPath(selectedFile)
			executable.run("cat -- " + root.shellQuote(path), function(code, out, err) {
				if (code !== 0) {
					noteItemObj.notify(i18n("Could not import: %1", err.trim()), 'error')
				} else if (out.trim() === "") {
					noteItemObj.notify(i18n("The file is empty"), 'error')
				} else {
					noteItemObj.importText(out)
				}
				root.expanded = true
			})
		}
	}
}
