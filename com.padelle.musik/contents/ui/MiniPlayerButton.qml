import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// Lightweight replacement for PlasmaComponents3.ToolButton in the mini
// player. The themed ToolButton brings quirks that clash with the player UI:
// an over-rounded highlight, no hover fade, and it swallows the hover event
// so the plasmoid's big hover background vanishes when the cursor enters
// directly onto a button. This is a plain MouseArea + icon with a subtle,
// low-radius, fading highlight. `hovered` is exposed so the parent can keep
// the big background lit while a button is hovered.
Item {
    id: control

    property url iconSource
    property real size: Kirigami.Units.iconSizes.medium
    property real iconScale: 0.65
    // re-expose to avoid colliding with Item.enabled semantics on the area
    property bool active: true
    // mirrors the scrolling-text behaviour: icons brighten with the whole
    // plasmoid, not just this button
    property bool hoveredOnPlasmoid: false
    property alias hovered: area.containsMouse
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    Layout.preferredWidth: size
    Layout.preferredHeight: size

    Rectangle {
        id: highlight
        anchors.fill: parent
        radius: 50
        color: Kirigami.Theme.textColor
        opacity: !control.active ? 0.0
                 : area.pressed ? 0.16
                 : area.containsMouse ? 0.16
                 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Kirigami.Icon {
        id: icon
        anchors.centerIn: parent
        width: Math.round(control.size * control.iconScale)
        height: width
        source: control.iconSource
        // Same look as the scrolling text in the mini player
        color: 'white'
        // smooth: true
        antialiasing: true
        opacity: !control.active ? 0.18
                 : control.hoveredOnPlasmoid ? 0.45 : 0.35
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        scale: area.pressed && control.active ? 0.88 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        layer.enabled: true
        layer.smooth: false
        layer.textureSize: Qt.size(Math.ceil(width * 3), Math.ceil(height * 3))
        layer.effect: MultiEffect {
            brightness: 0.8
            contrast: 0.07
            saturation: 1.0
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: control.active
        onClicked: control.clicked()
    }
}
