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

    property string sourceName: ""

    // Match source name against player's desktopEntry or executable base name
    function playerMatches(player, name) {
        if (!player || !name) return false
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
        if (!mpris2Model.currentPlayer || !sourceName) {
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

    // Timer to periodically seek target player if not yet available
    property var checkTimer: Timer {
        interval: 3000
        running: !ready && sourceName.length > 0
        repeat: true
        onTriggered: {
            selectActiveSource();
        }
    }

    function checkPlayingPlayers() {
        if (!ready && sourceName.length > 0) {
            selectActiveSource();
        }
    }

    // Function to select a player when a new source is added
    function selectPlayerSource(rowIndex) {
        if (!sourceName) return;
        const CONTAINER_ROLE = Qt.UserRole + 1
        const player = mpris2Model.data(mpris2Model.index(rowIndex, 0), CONTAINER_ROLE)
        if (player && playerMatches(player, sourceName)) {
            mpris2Model.currentIndex = rowIndex;
        }
    }

    // Function to scan all sources for the target app
    function selectActiveSource() {
        if (!sourceName || mpris2Model.rowCount() === 0) return;

        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const CONTAINER_ROLE = Qt.UserRole + 1
            const player = mpris2Model.data(mpris2Model.index(i, 0), CONTAINER_ROLE)
            if (player && playerMatches(player, sourceName)) {
                mpris2Model.currentIndex = i;
                return;
            }
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