# Plasma 6 port — changes

This is a port of Chris Holland's (Zren) Plasma 5 "TodoList" widget to
Plasma 6 / Qt6. The original widget and its author are credited in `AUTHORS.md`.

Because several Plasma 5 APIs this widget relied on were removed or changed in
Plasma 6, this is a partial rewrite rather than a drop-in migration.

## What changed

- **Storage layer reimplemented.** The original persisted tasks through the
  Plasma 5 `org.kde.plasma.private.notes` `NoteManager` QML API, which no longer
  exists in Plasma 6 (the Notes widget became a compiled C++ applet). Tasks are
  now stored in the widget's own `plasmoid.configuration` (auto-persisted by
  Plasma), using the same `# heading` / `* [ ]` / `* [x]` markdown format as the
  original so behavior matches.
  - Removed as a consequence: the "Open in Text Editor" action, the shared
    "global note" file, and external file-change syncing. **Export to File…**
    and **Import from File…** replace them for backups.

- **Counter badge reimplemented.** The original used a Qt5 `ShaderEffect` with
  inline GLSL to mask the badge onto the icon; Qt6 does not support inline GLSL
  shaders. The badge is now drawn with a plain rounded `Rectangle` + `Label`.

- **QML API migration (Plasma 5 → 6 / Qt6):**
  - Root item is now `PlasmoidItem`.
  - Version-less imports; `org.kde.kirigami` added.
  - `units.*` → `Kirigami.Units.*`; `theme.*` → `Kirigami.Theme.*`.
  - `PlasmaCore.IconItem` → `Kirigami.Icon`.
  - Context menu `plasmoid.setAction`/`action` → `Plasmoid.contextualActions`.
  - Removed the `executable` DataEngine usage.
  - `Connections { onXChanged: ... }` → `function onXChanged()` (Qt6 syntax).
  - `metadata.desktop` → `metadata.json` (Plasma 6 schema).

## Added in the port

- Add, move and delete lists from each list's title.
- Undo after deleting a list, clearing completed items or importing.
- Clear Completed, Export to File… and Import from File… in the context menu.
- Mouse drag-to-reorder for items, using Kirigami's drag handle (the
  original's drag code did not work on Plasma 6).
- Indonesian translation; the old Plasma 5 translations were removed.

## License

GPL-2.0-or-later. See `LICENSE` and `AUTHORS.md`.
