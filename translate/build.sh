#!/bin/sh
# Regenerate template.pot from the QML sources, update every <lang>.po from
# it, and compile them into contents/locale/<lang>/LC_MESSAGES/<domain>.mo.
# The source strings are English, so English needs no catalog.
#
# Requires gettext (xgettext, msgmerge, msgfmt).
set -e

DIR=$(cd "$(dirname "$0")" && pwd)
ROOT="$DIR/.."
DOMAIN="plasma_applet_id.adweb.todolist"

cd "$ROOT"
xgettext --from-code=UTF-8 --language=JavaScript \
	-ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
	--package-name="$DOMAIN" \
	--msgid-bugs-address=https://github.com/adweb-id/plasma-applet-todolist-p6 \
	-o "$DIR/template.pot" $(find contents -name '*.qml' | sort)

for po in "$DIR"/*.po; do
	lang=$(basename "$po" .po)
	msgmerge --quiet --update --backup=none "$po" "$DIR/template.pot"
	mkdir -p "contents/locale/$lang/LC_MESSAGES"
	msgfmt --check -o "contents/locale/$lang/LC_MESSAGES/$DOMAIN.mo" "$po"
	echo "$lang: $(msgfmt --statistics -o /dev/null "$po" 2>&1)"
done
