import QtQuick 2.15
import Qt5Compat.GraphicalEffects

// Album cover that crossfades with a subtle scale-up whenever the art changes,
// instead of popping in abruptly on song change. Double-buffered: the incoming
// art loads into the hidden image, then fades in over the outgoing one.
//
// Motion: opacity crossfade + scale 0.94 -> 1, easing cubic-bezier(0.22,1,0.36,1)
// (same focus-pull family as the song-title reveal, for a cohesive swap).
Item {
    id: root

    property url source
    property url fallback
    property real radius: 0

    readonly property url _target: (source && String(source).length) ? source : fallback

    // Which image currently holds the visible art; the other is the loader.
    property bool _frontIsA: true
    property bool _pending: false
    property bool _primed: false

    on_TargetChanged: if (_primed) _begin()
    Component.onCompleted: {
        imgA.source = _target
        imgA.opacity = 1
        imgB.opacity = 0
        _frontIsA = true
        _primed = true
    }

    // Load the new art into the back image; reveal once it has decoded.
    function _begin() {
        crossfade.stop()
        var back = _frontIsA ? imgB : imgA
        var front = _frontIsA ? imgA : imgB
        front.opacity = 1            // normalise in case a swap was mid-flight
        back.opacity = 0
        back.source = _target
        _pending = true
        if (back.status === Image.Ready)
            _reveal()
    }

    function _reveal() {
        if (!_pending)
            return
        _pending = false
        var back = _frontIsA ? imgB : imgA
        var front = _frontIsA ? imgA : imgB
        back.scale = 0.94
        back.opacity = 0
        fadeIn.target = back
        zoomIn.target = back
        fadeOut.target = front
        crossfade.restart()
    }

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle { width: imgA.width; height: imgA.height; radius: root.radius }
        }
        onStatusChanged: if (status === Image.Ready && root._pending && !root._frontIsA) root._reveal()
    }

    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        opacity: 0
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle { width: imgB.width; height: imgB.height; radius: root.radius }
        }
        onStatusChanged: if (status === Image.Ready && root._pending && root._frontIsA) root._reveal()
    }

    ParallelAnimation {
        id: crossfade
        onFinished: {
            // The freshly revealed image is now the front.
            root._frontIsA = !root._frontIsA
            var back = root._frontIsA ? imgB : imgA
            back.opacity = 0
            back.scale = 1
        }

        NumberAnimation {
            id: fadeIn
            property: "opacity"; to: 1; duration: 520
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
        NumberAnimation {
            id: zoomIn
            property: "scale"; to: 1; duration: 620
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
        NumberAnimation {
            id: fadeOut
            property: "opacity"; to: 0; duration: 420
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
        }
    }
}
