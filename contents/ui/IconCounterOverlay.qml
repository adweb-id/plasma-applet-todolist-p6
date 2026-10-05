import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// A simple counter badge drawn in the corner of the panel icon.
// The Plasma 5 original used a ShaderEffect mask (unsupported in Qt6);
// this replaces it with a plain rounded Rectangle + Label.
Item {
	id: overlay

	property alias text: badgeLabel.text
	property color backgroundColor: Plasmoid.configuration.roundCounter ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
	property color textColor: Plasmoid.configuration.roundCounter ? Kirigami.Theme.backgroundColor : Kirigami.Theme.highlightColor
	property real heightRatio: Plasmoid.configuration.bigCounter ? 1.0 : 0.5

	Rectangle {
		id: badgeRect
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		height: Math.round(parent.height * overlay.heightRatio)
		width: Math.max(height, badgeLabel.implicitWidth + height * 0.3)
		color: overlay.backgroundColor
		radius: Plasmoid.configuration.roundCounter ? height / 2 : Math.max(2, height * 0.15)
		border.width: Math.max(1, Math.round(height * 0.08))
		border.color: Kirigami.Theme.backgroundColor

		PlasmaComponents3.Label {
			id: badgeLabel
			anchors.centerIn: parent
			height: Math.round(parent.height * 0.8)
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			fontSizeMode: Text.Fit
			font.pointSize: -1
			font.pixelSize: 1024
			minimumPixelSize: 5
			color: overlay.textColor
			font.weight: Font.Black
		}
	}
}
