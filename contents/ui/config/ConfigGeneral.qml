import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes

Kirigami.FormLayout {
	id: page

	// Standard Plasma config convention: cfg_<key> aliases are auto-synced
	// with plasmoid.configuration.<key>.
	property alias cfg_icon: iconField.text
	property alias cfg_hidden: hiddenBox.checked
	property alias cfg_showBackground: showBackgroundBox.checked
	property alias cfg_deleteOnComplete: deleteOnCompleteBox.checked
	property alias cfg_strikeoutCompleted: strikeoutBox.checked
	property alias cfg_fadeCompleted: fadeBox.checked
	property alias cfg_listTitleBold: titleBoldBox.checked
	property alias cfg_listTitleOutline: titleOutlineBox.checked
	property alias cfg_showCounter: counterCombo.currentValue
	property alias cfg_bigCounter: bigCounterBox.checked
	property alias cfg_roundCounter: roundCounterBox.checked
	property alias cfg_showCompletedItems: showCompletedBox.checked

	RowLayout {
		Kirigami.FormData.label: i18n("Icon:")
		QQC2.TextField {
			id: iconField
			Layout.preferredWidth: Kirigami.Units.gridUnit * 12
			placeholderText: "korg-todo"
		}
		QQC2.Button {
			icon.name: iconField.text.trim() || "korg-todo"
			text: i18n("Choose…")
			onClicked: page.iconDialog.open()
		}
		QQC2.ToolButton {
			icon.name: "edit-undo"
			enabled: iconField.text !== ""
			onClicked: iconField.text = ""
			QQC2.ToolTip.text: i18n("Use the default icon")
			QQC2.ToolTip.visible: hovered
		}
	}

	// KDE's searchable icon picker.
	readonly property var iconDialog: KIconThemes.IconDialog {
		onIconNameChanged: iconName => { if (iconName) iconField.text = iconName }
	}

	Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Desktop Widget") }

	QQC2.CheckBox {
		id: hiddenBox
		text: i18n("Hide")
	}
	QQC2.CheckBox {
		id: showBackgroundBox
		text: i18n("Show background")
	}

	Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Completed Items") }

	QQC2.CheckBox {
		id: showCompletedBox
		text: i18n("Show completed items")
	}
	QQC2.CheckBox {
		id: deleteOnCompleteBox
		text: i18n("Delete on complete")
	}
	QQC2.CheckBox {
		id: strikeoutBox
		text: i18n("Strikeout")
	}
	QQC2.CheckBox {
		id: fadeBox
		text: i18n("Faded")
	}

	Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("List Title Style") }

	QQC2.CheckBox {
		id: titleBoldBox
		text: i18n("Bold")
	}
	QQC2.CheckBox {
		id: titleOutlineBox
		text: i18n("Show outline")
	}

	Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Panel Counter") }

	QQC2.ComboBox {
		id: counterCombo
		Kirigami.FormData.label: i18n("Show counter:")
		textRole: "text"
		valueRole: "value"
		model: [
			{ value: "Never", text: i18n("Never") },
			{ value: "Incomplete", text: i18n("When incomplete items are left") },
			{ value: "Always", text: i18n("Always") },
		]
		// Initialize selection from the stored config value.
		Component.onCompleted: {
			for (var i = 0; i < model.length; i++) {
				if (model[i].value === plasmoid.configuration.showCounter) {
					currentIndex = i
					break
				}
			}
		}
	}
	QQC2.CheckBox {
		id: bigCounterBox
		text: i18n("Use big counter")
	}
	QQC2.CheckBox {
		id: roundCounterBox
		text: i18n("Use round counter")
	}
}
