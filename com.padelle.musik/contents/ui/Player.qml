import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    property var mpris2Model: Mpris.Mpris2Model {
        onRowsInserted: (_, rowIndex) => {
            selectPlayerSource(rowIndex);
        }

        // Use rowsChanged signal instead of sourcesChanged
        onRowsRemoved: () => {
            // When players are removed, also check what's still available
            initTimer.restart();
        }

        // We can also check when the model data changes
        onDataChanged: () => {
            checkPlayingPlayers();
        }
    }

    property string sourceName: "any"
    property bool prioritizePlayingSource: true

    // Match source name against player's desktopEntry or executable base name
    function playerMatches(player, name) {
        if (!name || name === "any") return true
        let clean = name.toLowerCase().trim()
        if (clean.endsWith(".desktop")) {
            clean = clean.substring(0, clean.length - 8)
        }
        const slash = clean.lastIndexOf("/")
        if (slash !== -1) {
            clean = clean.substring(slash + 1)
        }

        const desktopEntry = (player.desktopEntry || "").toLowerCase()
        const identity = (player.identity || "").toLowerCase()
        const idBase = identity.match(/([^\/\s]+)$/)?.[1] || identity

        return desktopEntry === clean || identity === clean || idBase === clean
    }

    readonly property bool ready: {
        if (!mpris2Model.currentPlayer) {
            return false
        }
        return playerMatches(mpris2Model.currentPlayer, sourceName)
    }

    // Initialization timer to select active source after shell restart
    property var initTimer: Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: {
            selectActiveSource();
        }
    }

    // Timer to periodically check for playing sources (can be adjusted or disabled)
    property var checkTimer: Timer {
        interval: 5000
        running: prioritizePlayingSource
        repeat: true
        onTriggered: {
            checkPlayingPlayers();
        }
    }

    // Check if any players have started playing
    function checkPlayingPlayers() {
        if (sourceName !== "any") {
            // When targeting a specific app, only seek that app if not already selected
            if (!ready || !playerMatches(mpris2Model.currentPlayer, sourceName)) {
                selectActiveSource();
            }
            return;
        }

        if (!prioritizePlayingSource) return;

        // Only look for playing sources if we don't already have one playing
        if (ready && mpris2Model.currentPlayer &&
            mpris2Model.currentPlayer.playbackStatus === Mpris.PlaybackStatus.Playing) {
            return;
        }

        selectActiveSource();
    }

    // Function to select a player when a new source is added
    function selectPlayerSource(rowIndex) {
        const CONTAINER_ROLE = Qt.UserRole + 1
        const player = mpris2Model.data(mpris2Model.index(rowIndex, 0), CONTAINER_ROLE)
        if (!player) return;

        // When a specific source is configured, lock onto it strictly
        if (sourceName !== "any") {
            if (playerMatches(player, sourceName)) {
                mpris2Model.currentIndex = rowIndex;
            }
            return;
        }

        // Automatic mode ("any"): prioritize playing sources
        if (player.playbackStatus === Mpris.PlaybackStatus.Playing) {
            mpris2Model.currentIndex = rowIndex;
            sourceName = player.desktopEntry || "any";
        }
    }

    // Function to scan all sources
    function selectActiveSource() {
        if (mpris2Model.rowCount() === 0) return;

        // Case 1: Strict target mode (sourceName is specific)
        if (sourceName !== "any") {
            for (let i = 0; i < mpris2Model.rowCount(); i++) {
                const CONTAINER_ROLE = Qt.UserRole + 1
                const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)
                if (player && playerMatches(player, sourceName)) {
                    mpris2Model.currentIndex = i;
                    return;
                }
            }
            // Strict target not found: do NOT fallback to other players
            return;
        }

        // Case 2: Automatic mode ("any")
        if (!prioritizePlayingSource) return;

        // First pass: find any actively playing player
        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const CONTAINER_ROLE = Qt.UserRole + 1
            const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)
            if (player && player.playbackStatus === Mpris.PlaybackStatus.Playing) {
                mpris2Model.currentIndex = i;
                return;
            }
        }

        // Fallback: pick first player
        mpris2Model.currentIndex = 0;
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