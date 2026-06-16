import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects

// Wraps a single text element (e.g. a ScrollingText) and plays a
// blur + glide + opacity reveal whenever `trigger` changes — used for the
// full-player song-change transition.
//
// Motion contract: animate-text "focus-blur-resolve" (Apple-style focus pull),
// adapted from a vertical glide to a horizontal one so the direction can carry
// meaning: previous track glides left, next track glides right.
//   enter  blur 16px -> 0, opacity 0 -> 1, x offset -> 0
//   easing cubic-bezier(0.22, 1, 0.36, 1)
//
// `dir`:  +1 = enter from the right, glide left   (previous track)
//         -1 = enter from the left,  glide right  (next track)
//          0 = no glide, pure blur+fade           (external / first load)
Item {
    id: wrap

    // Change this to fire the reveal (bind to the song title / artists).
    property var trigger
    property int dir: 0
    property real glideDistance: 32

    // Skip the animation for the very first value so the widget doesn't
    // flourish on initial open.
    property bool _primed: false

    default property alias content: holder.data

    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignHCenter

    // Animated state
    property real animX: 0
    property real animBlur: 0
    property real animOpacity: 1

    Item {
        id: holder
        anchors.fill: parent
        opacity: wrap.animOpacity
        transform: Translate { x: wrap.animX }

        // Only pay for the blur pass while a transition is running; at rest the
        // text renders crisp with no extra layer.
        layer.enabled: revealAnim.running
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: wrap.animBlur
        }
    }

    onTriggerChanged: {
        if (!_primed) {            // ignore the initial binding
            _primed = true
            return
        }
        revealAnim.stop()
        animX = wrap.dir * wrap.glideDistance
        animBlur = 1.0
        animOpacity = 0.0
        revealAnim.start()
    }

    ParallelAnimation {
        id: revealAnim
        NumberAnimation {
            target: wrap; property: "animX"; to: 0; duration: 760
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
        NumberAnimation {
            target: wrap; property: "animBlur"; to: 0; duration: 620
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
        NumberAnimation {
            target: wrap; property: "animOpacity"; to: 1; duration: 520
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
    }
}
