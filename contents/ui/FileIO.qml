import org.kde.plasma.plasma5support as Plasma5Support

Plasma5Support.DataSource {
	id: fileIO
	engine: "executable"
	connectedSources: []
	property var jobs: []
	property bool running: false

	onNewData: (sourceName, data) => {
		disconnectSource(sourceName)
		var job = jobs.shift()
		running = false
		job.callback(data["exit code"], data["stdout"] || "", data["stderr"] || "")
		startNext()
	}

	function startNext() {
		if (!running && jobs.length > 0) {
			running = true
			connectSource(jobs[0].command)
		}
	}

	function run(command, callback) {
		jobs.push({ command: command, callback: callback })
		startNext()
	}

	function shellQuote(str) {
		return "'" + String(str).replace(/'/g, "'\\''") + "'"
	}

	function urlToPath(url) {
		var str = url.toString()
		return str.startsWith("file://") ? decodeURIComponent(str.substring(7)) : str
	}

	function localPath(path) {
		if (path.startsWith("~/")) {
			return '"$HOME"/' + shellQuote(path.substring(2))
		}
		if (path.startsWith("/")) {
			return shellQuote(path)
		}
		throw new Error("Expected an absolute local path or ~/path")
	}

	function readOrCreate(path, text, callback) {
		var quoted
		try {
			quoted = localPath(path)
		} catch (error) {
			callback(1, "", error.message)
			return
		}
		// noclobber prevents a newly created file from overwriting an existing one.
		run("if [ ! -e " + quoted + " ]; then (set -C; printf '%s' "
			+ shellQuote(text) + " > " + quoted + ") || exit; fi; cat -- " + quoted, callback)
	}

	function read(path, callback) {
		var quoted
		try {
			quoted = localPath(path)
		} catch (error) {
			callback(1, "", error.message)
			return
		}
		run("cat -- " + quoted, callback)
	}

	function write(path, text, callback) {
		var quoted
		try {
			quoted = localPath(path)
		} catch (error) {
			callback(1, "", error.message)
			return
		}
		// Replace atomically so an interrupted write cannot leave a truncated list.
		run("target=$(readlink -m -- " + quoted + ") || exit; "
			+ "tmp=$(mktemp -- \"$target.XXXXXX\") || exit; "
			+ "trap 'rm -f -- \"$tmp\"' EXIT; "
			+ "if [ -e \"$target\" ]; then chmod --reference=\"$target\" -- \"$tmp\" || exit; fi; "
			+ "printf '%s' " + shellQuote(text)
			+ " > \"$tmp\" && mv -fT -- \"$tmp\" \"$target\"", callback)
	}
}
