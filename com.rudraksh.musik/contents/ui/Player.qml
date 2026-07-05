import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    property var mpris2Model: Mpris.Mpris2Model {
        // A new player appeared. Seed its status so its initial state isn't
        // mistaken for a transition; then — once past the initial seed —
        // treat a brand-new already-playing source as a deliberate start.
        onRowsInserted: (parent, first, last) => {
            for (let i = first; i <= last; i++) {
                const p = root._containerAt(i);
                if (!p) continue;
                root._lastStatus[root._key(p)] = p.playbackStatus;
                if (root._seeded && p.playbackStatus === Mpris.PlaybackStatus.Playing)
                    root._switchTo(i, p);
            }
        }

        // A player vanished — make sure we still point at a valid one.
        onRowsRemoved: () => {
            root.ensureValidCurrent();
        }

        // Any player's data changed. Only switch on a real Paused->Playing
        // edge (the user resuming a track), so a browser tab stuck in a stale
        // "Playing" state can't repeatedly steal the selection.
        onDataChanged: () => {
            root._scanTransitions();
        }
    }

    property string sourceName: "any"
    property bool prioritizePlayingSource: true // New property to control priority behavior

    // Edge-detection state: last seen playbackStatus per player, so we can tell
    // a fresh "resume" (Paused -> Playing) from a player that has simply been
    // Playing all along. Keyed by a stable per-instance id.
    property var _lastStatus: ({})
    // True once the initial status of every player has been recorded; before
    // this we must not treat pre-existing Playing players as transitions.
    property bool _seeded: false

    readonly property bool ready: {
        if (!mpris2Model.currentPlayer) {
            return false
        }
        return mpris2Model.currentPlayer.desktopEntry === sourceName || sourceName === "any";
    }

    // Initialization timer to select active source after shell restart
    property var initTimer: Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            root._seedStatuses();
            root._seeded = true;
            selectActiveSource();
        }
    }

    // Periodic safety net: only recovers when we've lost a valid current
    // player; it never steals away from one that's still alive.
    property var checkTimer: Timer {
        interval: 5000
        running: prioritizePlayingSource
        repeat: true
        onTriggered: {
            ensureValidCurrent();
        }
    }

    function _containerAt(i) {
        if (i < 0 || i >= mpris2Model.rowCount())
            return null;
        return mpris2Model.data(mpris2Model.index(i, 0), Qt.UserRole + 1);
    }

    // Stable-ish identity for a player instance (instancePid is CONSTANT, so it
    // survives metadata/status churn and tells two browser tabs apart well
    // enough for edge detection).
    function _key(p) {
        return (p.instancePid !== undefined ? p.instancePid : "?") + "|"
             + (p.desktopEntry || "") + "|" + (p.identity || "");
    }

    // Record the current status of every player without switching — primes
    // edge detection so pre-existing Playing players aren't seen as resumes.
    function _seedStatuses() {
        root._lastStatus = ({});
        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const p = _containerAt(i);
            if (p)
                root._lastStatus[_key(p)] = p.playbackStatus;
        }
    }

    // Point the active selection at row `rowIndex`.
    function _switchTo(rowIndex, p) {
        if (mpris2Model.currentIndex === rowIndex)
            return;
        console.log("Switching to (re)started source:", p.desktopEntry || p.identity);
        mpris2Model.currentIndex = rowIndex;
        sourceName = p.desktopEntry;
    }

    // Scan all players; switch to the first that has just transitioned into
    // Playing. Always refreshes the recorded statuses.
    function _scanTransitions() {
        if (!prioritizePlayingSource) {
            _seedStatuses();
            return;
        }
        let switched = false;
        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const p = _containerAt(i);
            if (!p)
                continue;
            const key = _key(p);
            const prev = root._lastStatus[key];
            const now = p.playbackStatus;
            root._lastStatus[key] = now;
            if (root._seeded && !switched
                    && now === Mpris.PlaybackStatus.Playing
                    && prev !== Mpris.PlaybackStatus.Playing) {
                _switchTo(i, p);
                switched = true;
            }
        }
    }

    // Ensure we point at a usable player without stealing from a valid current
    // one (used on removal, popup open, and the periodic safety net).
    function ensureValidCurrent() {
        if (!prioritizePlayingSource)
            return;
        if (mpris2Model.currentPlayer)
            return;
        selectActiveSource();
    }

    // Function to scan all sources and find any actively playing source
    function selectActiveSource() {
        if (!prioritizePlayingSource || mpris2Model.rowCount() === 0) return;

        // First pass: look for playing sources
        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const CONTAINER_ROLE = Qt.UserRole + 1
            const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)

            if (player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                console.log("Found playing source:", player.desktopEntry);
                mpris2Model.currentIndex = i;
                // Update the source name to the playing source
                sourceName = player.desktopEntry;
                return;
            }
        }

        // Second pass: if no playing source, try to find the configured source
        if (sourceName !== "any") {
            for (let i = 0; i < mpris2Model.rowCount(); i++) {
                const CONTAINER_ROLE = Qt.UserRole + 1
                const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)

                if (player.desktopEntry === sourceName) {
                    console.log("Using configured source:", player.desktopEntry);
                    mpris2Model.currentIndex = i;
                    return;
                }
            }
        }

        // Last resort: if we're using "any" and no playing source was found, use the first source
        if (sourceName === "any" && mpris2Model.rowCount() > 0) {
            console.log("Using first available source");
            mpris2Model.currentIndex = 0;
        }
    }

    readonly property string artists: ready ? mpris2Model.currentPlayer.artist : ""
    readonly property string title: ready ? mpris2Model.currentPlayer.track : ""
    readonly property int playbackStatus: ready ? mpris2Model.currentPlayer.playbackStatus : Mpris.PlaybackStatus.Unknown
    readonly property int shuffle: ready ? mpris2Model.currentPlayer.shuffle : Mpris.ShuffleStatus.Unknown
    readonly property string artUrl: ready ? mpris2Model.currentPlayer.artUrl : ""
    readonly property int loopStatus: ready ? mpris2Model.currentPlayer.loopStatus : Mpris.LoopStatus.Unknown
    readonly property double songPosition: ready ? mpris2Model.currentPlayer.position : 0
    readonly property double songLength: ready ? mpris2Model.currentPlayer.length : 0
    readonly property real volume: ready ? mpris2Model.currentPlayer.volume : 0

    readonly property bool canGoNext: ready ? mpris2Model.currentPlayer.canGoNext : false
    readonly property bool canGoPrevious: ready ? mpris2Model.currentPlayer.canGoPrevious : false
    readonly property bool canPlay: ready ? mpris2Model.currentPlayer.canPlay : false
    readonly property bool canPause: ready ? mpris2Model.currentPlayer.canPause : false
    readonly property bool canSeek: ready ? mpris2Model.currentPlayer.canSeek : false

    // To know whether Shuffle and Loop can be changed we have to check if the property is defined,
    // unlike the other commands, LoopStatus and Shuffle hasn't a specific propety such as
    // CanPause, CanSeek, etc.
    readonly property bool canChangeShuffle: ready ? mpris2Model.currentPlayer.shuffle != undefined : false
    readonly property bool canChangeLoopStatus: ready ? mpris2Model.currentPlayer.loopStatus != undefined : false

    function playPause() {
        mpris2Model.currentPlayer?.PlayPause();
    }

    function setPosition(position) {
        mpris2Model.currentPlayer.position = position;
    }

    function next() {
        mpris2Model.currentPlayer?.Next();
    }

    function previous() {
        mpris2Model.currentPlayer?.Previous();
    }

    function updatePosition() {
        mpris2Model.currentPlayer?.updatePosition();
    }

    function setVolume(volume) {
        mpris2Model.currentPlayer.volume = volume
    }

    function setShuffle(shuffle) {
        mpris2Model.currentPlayer.shuffle = shuffle
    }

    function setLoopStatus(loopStatus) {
        mpris2Model.currentPlayer.loopStatus = loopStatus
    }
}