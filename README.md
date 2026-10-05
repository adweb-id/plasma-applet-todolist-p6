# TodoList — Plasma 6 port

A KDE Plasma **6** widget showing a todo list of checkable items, organized into
lists with headings. This is a **Plasma 6 / Qt6 port** of Chris Holland's
(Zren) original Plasma 5 widget.

> This is a port, not original work. See [`AUTHORS.md`](AUTHORS.md) for
> attribution and [`PORTING.md`](PORTING.md) for what changed.

- **Original:** https://github.com/Zren/plasma-applet-todolist (KDE Store:
  https://store.kde.org/p/1152230)
- **License:** GPL-2.0-or-later (see [`LICENSE`](LICENSE))

## Features

- Multiple lists/sections with headings
- Checkable items with indent levels (Tab / Shift+Tab)
- Incomplete-item counter badge on the panel icon
- Strikeout / fade completed items, optional "delete on complete"
- Configurable counter, title style, and background

Reorder items with **Ctrl+↑ / Ctrl+↓**.

## Install

### From the packaged widget

```sh
kpackagetool6 --type Plasma/Applet --install .
# or, to update an installed copy:
kpackagetool6 --type Plasma/Applet --upgrade .
```

Then right-click your panel or desktop → **Add Widgets…** → search **TodoList**.

### Notes vs. the Plasma 5 original

Some Plasma 5 features were dropped because the underlying APIs were removed in
Plasma 6 (notably the Notes `NoteManager` storage and the shader-based badge).
Tasks are now stored in the widget's own configuration. Mouse drag-to-reorder
and the delete-confirmation dialog were also dropped; see `PORTING.md`.

## Credits

- Original widget: **Chris Holland (Zren)**
- Counter badge derived from KDE's task manager: **Kai Uwe Broulik**
- Plasma 6 port: this repository
