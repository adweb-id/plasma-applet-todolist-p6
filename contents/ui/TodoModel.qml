import QtQuick
import org.kde.plasma.plasmoid

ListModel {
	id: todoModel
	signal update()

	// Set by NoteItem's Repeater so we can reach its helper functions.
	// Named 'owner' (not 'noteItem') to avoid shadowing the outer `id: noteItem`
	// in the binding `owner: noteItem`, which would otherwise self-reference.
	property var owner

	property int incompleteCount: 0

	function insertItem(index, todoObj) {
		insert(index, todoObj)
		update()
	}

	function removeItem(index) {
		remove(index, 1)
		update()
	}

	function setData(todoData) {
		clear()
		for (var i = 0; i < todoData.length; i++) {
			append(todoData[i])
		}
		update()
	}

	function addTemplateIfNeeded() {
		if (count == 0 || !owner.isEmptyItem(get(count-1))) {
			append(owner.newTodoItem())
		}
	}

	function updateVisibleItems() {
		var newIncompleteCount = 0
		for (var i = 0; i < count; i++) {
			var todoItem = get(i)
			var incomplete = todoItem.status == 'needsAction'
			var shouldBeVisible = Plasmoid.configuration.showCompletedItems || incomplete
			var isPlaceholder = !todoItem.title
			if (incomplete && !isPlaceholder) {
				newIncompleteCount += 1
			}
			setProperty(i, 'isVisible', shouldBeVisible)
		}
		todoModel.incompleteCount = newIncompleteCount
		addTemplateIfNeeded()
	}
}
