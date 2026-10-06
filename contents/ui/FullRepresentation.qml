import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

FocusScope {
	id: fullRepresentation

	// Shared data object, provided by main.qml.
	property var noteItem

	property bool isDesktopContainment: false
	property bool popupOpen: true

	// Each list has a fixed width. In the panel popup the width is locked to
	// listWidth × number of lists, so it doesn't keep a stale saved size and
	// can't be stretched. On the desktop the widget stays freely resizable.
	readonly property int listWidth: Kirigami.Units.gridUnit * 18
	readonly property int fixedWidth: listWidth * noteItem.numSections

	Layout.minimumWidth: isDesktopContainment ? Kirigami.Units.gridUnit * 10 * noteItem.numSections : fixedWidth
	Layout.maximumWidth: isDesktopContainment ? -1 : fixedWidth
	Layout.minimumHeight: Kirigami.Units.gridUnit * 10
	Layout.preferredWidth: fixedWidth
	Layout.preferredHeight: Math.min(Math.max(Kirigami.Units.gridUnit * 20, maxContentHeight), Screen.desktopAvailableHeight)

	property int maxContentHeight: 0
	function updateMaxContentHeight() {
		var maxHeight = 0
		for (var i = 0; i < notesRepeater.count; i++) {
			var item = notesRepeater.itemAt(i)
			if (item) {
				maxHeight = Math.max(maxHeight, item.contentHeight)
			}
		}
		maxContentHeight = maxHeight
	}

	RowLayout {
		id: notesRow
		anchors.fill: parent

		opacity: Plasmoid.configuration.hidden ? 0 : 1
		visible: opacity > 0

		Behavior on opacity {
			NumberAnimation { duration: 400 }
		}

		Repeater {
			id: notesRepeater
			model: fullRepresentation.noteItem.numSections

			NoteSection {
				id: container
				noteItem: fullRepresentation.noteItem
				sectionCount: notesRepeater.count
				popupOpen: fullRepresentation.popupOpen

				onContentHeightChanged: {
					fullRepresentation.updateMaxContentHeight()
				}
			}
		}
	}
}
