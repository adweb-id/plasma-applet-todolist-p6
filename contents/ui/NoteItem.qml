import QtQuick
import org.kde.plasma.plasmoid

Item {
	id: noteItem

	// Persist the serialized markdown in the plasmoid config (Plasma 6 has no
	// NoteManager). Guard against the save->configChanged->load feedback loop.
	property bool internalSave: false
	property bool saveOnChange: true

	function saveNote(str) {
		if (!str) {
			str = serializeTodoModel()
		}
		internalSave = true
		Plasmoid.configuration.noteText = str
		internalSave = false
	}

	function loadNote() {
		var savingOnChange = saveOnChange
		saveOnChange = false
		todoData = deserializeTodoModel(Plasmoid.configuration.noteText || '')
		numSections = Math.max(1, todoData.length)
		updateAllModels()
		saveOnChange = savingOnChange
	}

	Timer {
		id: deboucedSaveNoteTimer
		interval: 1000
		onTriggered: saveNote()
	}
	function deboucedSaveNote() {
		if (saveOnChange) {
			deboucedSaveNoteTimer.restart()
		}
	}

	// Message shown at the bottom of the popup, with an optional Undo.
	// type: 'info', 'positive' or 'error'.
	property string bannerText: ''
	property string bannerType: 'info'
	property bool canUndo: false
	property string undoSnapshot: ''

	Timer {
		id: bannerTimer
		interval: 10000
		onTriggered: noteItem.clearBanner()
	}

	function notify(text, type) {
		canUndo = false
		undoSnapshot = ''
		bannerType = type || 'info'
		bannerText = text
		bannerTimer.restart()
	}
	// Like notify(), but Undo restores `snapshot` (serialized lists).
	function notifyUndo(text, snapshot) {
		notify(text, 'info')
		undoSnapshot = snapshot
		canUndo = true
	}
	function clearBanner() {
		bannerTimer.stop()
		bannerText = ''
		canUndo = false
		undoSnapshot = ''
	}
	function undo() {
		if (canUndo) {
			restoreText(undoSnapshot)
		}
		clearBanner()
	}

	// Replace all lists with serialized `str` and save it.
	function restoreText(str) {
		deboucedSaveNoteTimer.stop()
		saveNote(str || '')
		loadNote()
	}

	function importText(str) {
		var before = serializeTodoModel()
		restoreText(str)
		notifyUndo(i18n("Tasks imported"), before)
	}

	function clearCompleted() {
		var before = serializeTodoModel()
		updateTodoData()
		var removed = 0
		for (var s = 0; s < todoData.length; s++) {
			var items = todoData[s].items
			var kept = items.filter(function(item) { return item.status !== 'completed' })
			removed += items.length - kept.length
			todoData[s].items = kept
		}
		if (removed === 0) {
			notify(i18n("No completed items to clear"), 'info')
			return
		}
		updateAllModels()
		saveNote()
		notifyUndo(i18np("Cleared 1 completed item", "Cleared %1 completed items", removed), before)
	}

	Connections {
		target: Plasmoid.configuration
		function onNoteTextChanged() {
			if (!internalSave) {
				loadNote()
			}
		}
	}

	function repeat(s, n) {
		var out = ''
		for (var i = 0; i < n; i++) {
			out += s
		}
		return out
	}

	function serializeTodoModel() {
		var out = ''

		for (var sectionIndex = 0; sectionIndex < numSections; sectionIndex++) {
			var noteSection = sectionList[sectionIndex]
			if (!noteSection) {
				continue
			}
			if (noteSection.label || sectionIndex > 0) { // Don't add heading if the first label is empty
				if (sectionIndex > 0) { // Don't add "top margin" for first heading
					out += '\n'
				}
				out += '# ' + rtrim(noteSection.label) + '\n\n'
			}
			var todoModel = noteSection.model
			for (var i = 0; i < todoModel.count; i++) {
				var todoItem = todoModel.get(i)
				if (i == todoModel.count-1 && isEmptyItem(todoItem)) {
					break
				}
				var line = ''
				line += repeat('    ', todoItem.indent)
				line += '* '
				line += todoItem.status == 'completed' ? '[x]' : '[ ]'
				line += ' '
				var indent = line.length
				var todoItemlines = todoItem.title.split('\n')
				line += todoItemlines[0]
				for (var j = 1; j < todoItemlines.length; j++) {
					line += '\n' + repeat(' ', indent) + todoItemlines[j]
				}
				out += line + '\n'
			}
		}
		return out
	}

	function isEmptyItem(todoItem) {
		return todoItem.title == ''
	}

	function newTodoItem() {
		return {
			title: '',
			status: 'needsAction',
			notes: '',
			indent: 0,
			isVisible: true,
		}
	}

	function isNewItem(line) {
		if (line.indexOf('*') == -1) {
			return false
		}
		for (var i = 0; i < line.indexOf('*'); i++) {
			if (!(line[i] === ' ' || line[i] === '\t')) {
				return false
			}
		}
		return true
	}

	function isHeading(line) {
		return line.indexOf('#') == 0
	}

	function getStartIndex(line, startIndex) {
		for (var i = startIndex; i < line.length; i++) {
			if (line[i] === ' ' || line[i] === '\t') {
				continue
			} else {
				startIndex = i
				break
			}
		}
		return startIndex
	}

	function _addSectionTo(out) {
		out.push({
			label: '',
			items: [],
		})
	}

	function rtrim(s) { // trim spaces, tabs, and newlines
		if (s && s.length > 0) {
			for (var i = s.length-1; i >= 0; i--) {
				if (!(s[i] == ' ' || s[i] == '\t' || s[i] == '\n')) {
					return s.substr(0, i+1)
				}
			}
			return ''
		} else {
			return s
		}
	}
	function trimLastNewline(s) {
		if (s && s[s.length-1] == '\n') {
			return s.substr(0, s.length-1) // trim ending \n
		} else {
			return s
		}
	}
	function deserializeTodoModel(s) {
		var sectionIndex = 0
		var out = []
		_addSectionTo(out)

		s = trimLastNewline(s)

		var lines = s.split('\n')
		var todoItem
		for (var j = 0; j < lines.length; j++) {
			var line = lines[j]
			var newItem = isNewItem(line)
			if (newItem) {
				if (todoItem) {
					out[sectionIndex].items.push(todoItem)
				}
				todoItem = newTodoItem()
				todoItem.indent = line.indexOf('*') / 4
				var checkboxIndex = line.indexOf('[')

				if (checkboxIndex >= 0) {
					todoItem.status = (line[checkboxIndex + 1] == 'x') ? 'completed' : 'needsAction'
					todoItem.title = line.substr(checkboxIndex + 'x] '.length + 1)
				} else { // Does not have [x]
					todoItem.status = 'needsAction'
					todoItem.title = line.substr(line.indexOf('*') + ' '.length + 1)
				}
			} else if (isHeading(line)) {
				if (todoItem) {
					todoItem.title = trimLastNewline(todoItem.title)
					if (todoItem.title) {
						out[sectionIndex].items.push(todoItem)
						todoItem = null
					}
				}
				var startIndex = getStartIndex(line, 1)
				if (!(sectionIndex == 0 && out[sectionIndex].items.length == 0)) { // Not the first heading
					_addSectionTo(out)
					sectionIndex += 1
				}
				out[sectionIndex].label = rtrim(line.substr(startIndex))
			} else if (todoItem) {
				var startIndex2 = getStartIndex(line, 0)
				var lineContents = line.substr(startIndex2)
				lineContents = rtrim(lineContents)
				todoItem.title += '\n' + lineContents
			}
		}
		if (todoItem) {
			out[sectionIndex].items.push(todoItem)
		}
		return out
	}

	readonly property bool hasIncomplete: incompleteCount > 0
	property int incompleteCount: 0
	function updateIncompleteCount() {
		var n = 0
		for (var i = 0; i < numSections; i++) {
			var noteSection = sectionList[i]
			if (noteSection) {
				n += noteSection.model.incompleteCount
			}
		}
		incompleteCount = n
	}

	property var todoData: []
	function updateAllModels() {
		for (var i = 0; i < numSections; i++) {
			updateSectionModel(i)
		}
	}
	function updateSectionModel(sectionIndex) {
		if (sectionList[sectionIndex]) {
			sectionList[sectionIndex].setData(todoData[sectionIndex])
		}
	}

	function updateTodoData() {
		todoData = deserializeTodoModel(serializeTodoModel())
	}

	function moveSection(sectionIndex, insertIndex) {
		updateTodoData() // First make sure todoData is updated
		var arr = todoData.splice(sectionIndex, 1)
		todoData.splice(insertIndex, 0, arr[0])
		updateAllModels()
	}

	function addSection() {
		updateTodoData() // First make sure todoData is updated
		_addSectionTo(todoData)
		numSections += 1
	}

	// Insert a new empty list so it appears at `insertIndex`, pushing the
	// existing lists at/after that position to the right.
	function insertSection(insertIndex) {
		updateTodoData() // First make sure todoData is updated
		todoData.splice(insertIndex, 0, { label: '', items: [] })
		numSections += 1
		updateAllModels()
	}

	function removeSection(sectionIndex) {
		var before = serializeTodoModel()
		updateTodoData() // First make sure todoData is updated
		var label = todoData[sectionIndex] ? todoData[sectionIndex].label : ''
		todoData.splice(sectionIndex, 1)
		numSections -= 1
		updateAllModels()
		saveNote()
		notifyUndo(label ? i18n("Deleted list \"%1\"", label) : i18n("Deleted list"), before)
	}

	property var sectionList: { return {} }
	property int numSections: 1

	Repeater {
		model: noteItem.numSections
		Item {
			id: noteSectionItem
			property string label: ''
			onLabelChanged: noteItem.deboucedSaveNote()

			function setData(sectionData) {
				if (sectionData) {
					label = sectionData.label
					model.setData(sectionData.items)
				}
			}

			property alias model: sectionModel
			TodoModel {
				id: sectionModel
				owner: noteItem
				onUpdate: {
					sectionModel.updateVisibleItems()
					noteItem.deboucedSaveNote()
				}
			}

			Component.onCompleted: {
				noteItem.sectionList[index] = noteSectionItem
				noteItem.updateSectionModel(index)
				noteSectionItem.model.incompleteCountChanged.connect(noteItem.updateIncompleteCount)
				noteItem.updateIncompleteCount()
			}
			Component.onDestruction: {
				delete noteItem.sectionList[index]
			}
		}
	}

	Connections {
		target: Plasmoid.configuration
		function onShowCompletedItemsChanged() {
			for (var i = 0; i < noteItem.numSections; i++) {
				if (noteItem.sectionList[i]) {
					noteItem.sectionList[i].model.updateVisibleItems()
				}
			}
		}
	}

	Component.onCompleted: {
		loadNote()
	}
	Component.onDestruction: {
		saveNote()
	}
}
