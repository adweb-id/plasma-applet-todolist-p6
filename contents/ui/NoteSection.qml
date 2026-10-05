import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

ColumnLayout {
	id: container
	Layout.fillWidth: true
	Layout.fillHeight: true
	spacing: 0

	// Provided by FullRepresentation.
	property var noteItem
	property int sectionCount: 1

	property int contentHeight: textField.height + container.spacing + noteListView.contentHeight

	property var noteSection: noteItem.sectionList[index]

	readonly property int titlePixelSize: Math.round(Kirigami.Units.gridUnit * 1.1)

	MouseArea {
		id: labelMouseArea
		Layout.fillWidth: true
		Layout.preferredHeight: labelRow.height
		hoverEnabled: true

		RowLayout {
			id: labelRow
			anchors.left: parent.left
			anchors.right: parent.right
			spacing: Kirigami.Units.smallSpacing

			PlasmaComponents3.TextField {
				id: textField
				Layout.fillWidth: true
				text: noteSection ? noteSection.label : ''

				background: Item {}
				font.pointSize: -1
				font.pixelSize: container.titlePixelSize
				font.weight: Plasmoid.configuration.listTitleBold ? Font.Bold : Font.Normal
				padding: 0
				leftPadding: 0
				rightPadding: 0
				topPadding: 0
				bottomPadding: 0

				onEditingFinished: {
					if (noteSection) {
						noteSection.label = text
						text = Qt.binding(function() { return noteSection ? noteSection.label : '' })
					}
				}

				PlasmaComponents3.Label {
					id: textOutline
					anchors.fill: parent
					visible: Plasmoid.configuration.listTitleOutline
					text: parent.text
					font.pointSize: -1
					font.pixelSize: container.titlePixelSize
					font.weight: Plasmoid.configuration.listTitleBold ? Font.Bold : Font.Normal
					color: "transparent"
					style: Text.Outline
					styleColor: Kirigami.Theme.backgroundColor
					verticalAlignment: Text.AlignVCenter
				}
			}

			PlasmaComponents3.ToolButton {
				id: deleteSectionButton
				visible: container.sectionCount > 1 && labelMouseArea.containsMouse
				icon.name: "trash-empty"
				onClicked: noteItem.removeSection(index)

				QQC2.ToolTip.text: i18n("Delete this list")
				QQC2.ToolTip.visible: hovered
				QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
			}
		}
	}

	QQC2.ScrollView {
		Layout.fillWidth: true
		Layout.fillHeight: true

		NoteListView {
			id: noteListView
			model: noteSection ? noteSection.model : null
		}
	}
}
