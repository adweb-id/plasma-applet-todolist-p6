# Translations

The widget's strings are written in English, so English needs no catalog.
Available translations:

- `id.po`: Indonesian

## Updating

After changing any `i18n(...)` string in the QML, run:

```sh
sh translate/build.sh
```

This regenerates `template.pot`, updates every `<lang>.po` from it, and
compiles them into `contents/locale/<lang>/LC_MESSAGES/plasma_applet_id.adweb.todolist.mo`.
New or changed strings show up untranslated (or marked fuzzy) in the `.po`
files: translate them and run the script again.

## Adding a language

```sh
msginit --no-translator --locale=<lang> -i translate/template.pot -o translate/<lang>.po
```

Translate the `msgstr` entries, then run `sh translate/build.sh`.
