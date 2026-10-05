import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
	id: root

	NoteItem {
		id: noteItemObj
	}

	Plasmoid.icon: Plasmoid.configuration.icon

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
			text: i18n("Delete on Complete")
			checkable: true
			checked: Plasmoid.configuration.deleteOnComplete
			onTriggered: Plasmoid.configuration.deleteOnComplete = !Plasmoid.configuration.deleteOnComplete
		},
		PlasmaCore.Action {
			text: i18n("Hide")
			checkable: true
			checked: Plasmoid.configuration.hidden
			visible: Plasmoid.location === PlasmaCore.Types.Floating
			onTriggered: Plasmoid.configuration.hidden = !Plasmoid.configuration.hidden
		}
	]
}
