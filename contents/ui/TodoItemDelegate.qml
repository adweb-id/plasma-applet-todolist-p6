import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

MouseArea {
	id: todoItemDelegate
	implicitHeight: todoItemRow.implicitHeight
	hoverEnabled: true

	property var todoModel: ListView.view.model
	readonly property bool isCompleted: model.status == 'completed'

	function setComplete(completed) {
		var newStatus = completed ? 'completed' : 'needsAction'
		if (model.status != newStatus) {
			todoModel.setProperty(index, 'status', newStatus)
			todoModel.update()
		}
		if (Plasmoid.configuration.deleteOnComplete) {
			deleteItem()
		}
	}
	function setTitle(title) {
		if (model.title != title) {
			todoModel.setProperty(index, 'title', title)
			todoModel.update()
		}
	}
	function setIndent(indent) {
		if (model.indent != indent) {
			todoModel.setProperty(index, 'indent', Math.max(0, indent))
			todoModel.update()
		}
	}
	function deleteItem() {
		todoModel.removeItem(index)
	}

	RowLayout {
		id: todoItemRow
		anchors.left: parent.left
		anchors.right: parent.right
		spacing: Kirigami.Units.smallSpacing

		Item {
			id: indentItem
			Layout.preferredWidth: checkbox.width * model.indent
			visible: model.indent > 0
		}

		PlasmaComponents3.CheckBox {
			id: checkbox
			Layout.alignment: Qt.AlignTop
			checked: todoItemDelegate.isCompleted
			onClicked: setComplete(checked)
		}

		PlasmaComponents3.TextArea {
			id: textArea
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignTop

			textMargin: 0
			wrapMode: TextEdit.Wrap

			focus: todoItemDelegate.ListView.isCurrentItem
			onActiveFocusChanged: {
				if (activeFocus) {
					todoItemDelegate.ListView.view.currentIndex = index
				}
			}

			Timer {
				id: delayedSelect
				property int cursorPos: -1
				interval: 100
				onTriggered: {
					textArea.forceActiveFocus()
					textArea.cursorPosition = delayedSelect.cursorPos
				}
			}

			onLinkActivated: (link) => {
				Qt.openUrlExternally(link)
			}

			property bool isEditing: activeFocus
			textFormat: TextEdit.RichText
			text: renderText(model.title)
			onTextChanged: {
				if (isEditing && textFormat == TextEdit.PlainText) {
					setTitle(text)
				}
			}
			onIsEditingChanged: updateText()

			function updateText() {
				if (isEditing) {
					var cursor = cursorPosition
					textFormat = TextEdit.PlainText
					text = model.title
					cursorPosition = cursor
				} else {
					text = renderText(model.title)
					textFormat = TextEdit.RichText
				}
			}

			function renderText(text) {
				if (typeof text === 'undefined') {
					return ''
				}
				var out = text

				// Escape HTML
				out = out.replace(/[ -香<>\&]/gim, function(i) {
					return '&#' + i.charCodeAt(0) + ';'
				})

				// Render links
				var rUrl = /(http|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:\/~+#-]*[\w@?^=%&amp;\/~+#-])?/gi
				out = out.replace(rUrl, function(m) {
					return '<a href="' + m + '">' + m + '</a>' + ' '
				})
				out = '<style>a { color: ' + Kirigami.Theme.highlightColor + '; }</style>' + out

				// Render new lines
				out = out.replace(/\n/g, '<br>')

				return out
			}

			font.strikeout: !isEditing && todoItemDelegate.isCompleted && Plasmoid.configuration.strikeoutCompleted

			readonly property bool shouldFade: !isEditing && todoItemDelegate.isCompleted && Plasmoid.configuration.fadeCompleted
			opacity: shouldFade ? 0.6 : 1

			Keys.onPressed: (event) => {
				if (event.key == Qt.Key_Tab) {
					setIndent(model.indent + 1)
					event.accepted = true
				} else if (event.key == Qt.Key_Backtab) {
					setIndent(model.indent - 1)
					event.accepted = true
				} else if (event.key == Qt.Key_Return && event.modifiers == Qt.NoModifier) {
					event.accepted = true
					todoItemDelegate.ListView.view.currentIndex = index + 1
				} else if ((event.key == Qt.Key_Return && event.modifiers == Qt.ControlModifier)
						|| (event.key == Qt.Key_Return && event.modifiers == Qt.AltModifier)) {
					event.accepted = true
					setComplete(!todoItemDelegate.isCompleted)
				} else if (event.key == Qt.Key_Up && event.modifiers == Qt.ControlModifier) {
					event.accepted = true
					if (index > 0) {
						delayedSelect.cursorPos = cursorPosition
						todoModel.move(index, index-1, 1)
						delayedSelect.restart()
					}
				} else if (event.key == Qt.Key_Down && event.modifiers == Qt.ControlModifier) {
					event.accepted = true
					if (index < todoModel.count-1) {
						delayedSelect.cursorPos = cursorPosition
						todoModel.move(index, index+1, 1)
						delayedSelect.restart()
					}
				}
			}
		}

		PlasmaComponents3.ToolButton {
			id: removeButton
			Layout.alignment: Qt.AlignTop
			visible: !Plasmoid.configuration.deleteOnComplete
			icon.name: 'trash-empty'
			opacity: textArea.activeFocus || todoItemDelegate.containsMouse || hovered ? 1 : 0

			onClicked: deleteItem()
		}
	}
}
