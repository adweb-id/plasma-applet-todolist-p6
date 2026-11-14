import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

ListView {
	id: taskListView
	Layout.fillWidth: true
	Layout.fillHeight: true

	cacheBuffer: 10000000
	spacing: Kirigami.Units.smallSpacing
	clip: true

	QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

	// Kirigami reparents the draggable row; keep a delegate in the layout.
	delegate: Item {
		id: delegateRoot
		width: taskListView.width
		implicitHeight: taskRow.implicitHeight

		TodoItemDelegate {
			id: taskRow
			width: taskListView.width
			listView: taskListView
			currentItem: delegateRoot.ListView.isCurrentItem
		}
	}

	remove: Transition {
		NumberAnimation { property: "opacity"; to: 0; duration: 400 }
	}
	add: Transition {
		NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 400 }
	}
	displaced: Transition {
		NumberAnimation { properties: "x,y"; duration: 200 }
	}

	Timer {
		id: deboucedPositionViewAtEnd
		interval: 1000
		onTriggered: taskListView.positionViewAtEnd()
	}

	onCountChanged: {
		deboucedPositionViewAtEnd.restart()
	}
}
