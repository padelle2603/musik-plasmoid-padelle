# MusiK Plasmoid (Fork)

This repository is a personal fork of [Rudraksh88/musik-plasmoid](https://github.com/Rudraksh88/musik-plasmoid) maintained by Padelle for KDE Plasma 6, packaged under the identifier `com.padelle.musik`.

For comprehensive upstream documentation, original features, screenshots, and visualizer customization details, please refer directly to the **[Upstream README](https://github.com/Rudraksh88/musik-plasmoid#readme)**.

---

## Modifications in this Fork

This fork adapts MusiK to strictly track a single chosen application and isolate its audio output:

- **PipeWire Audio Stream Isolation:** The visualizer backend queries `pw-dump` for active audio streams belonging to the target application and records exclusively from that node using `pw-record --target <node_id>`. It no longer captures or mixes the global system monitor.
- **Strict Player Exclusivity:** The widget locks onto the selected MPRIS target. It will not automatically jump to other applications when they begin playing, nor fallback to an arbitrary player when idle.
- **Removal of "any" Fallback:** Removed the hardcoded `"any"` fallback and preloaded sources. When no target is configured or when the configured app is closed, the widget and visualizer remain silent and idle.
- **Application Import:** Added an **"Import..."** button in the settings dialog allowing users to pick an executable or `.desktop` file (automatically extracting the binary from the `Exec=` line).
- **Source Entry Removal:** Added a **"Remove"** button in settings to delete unwanted or obsolete entries from the saved sources list.
- **Package ID Rebranding:** Rebranded the package identifier to `com.padelle.musik` to avoid collision with upstream installations.

---

## Installation

### Requirements

- **KDE Plasma 6**
- **Python 3** with `numpy` (`python3-numpy` / `python-numpy`)
- **PipeWire** (`pw-dump`, `pw-record`)

### Commands

1. **Clone the repository:**
   ```bash
   git clone https://github.com/padelle2603/musik-plasmoid-padelle.git
   cd musik-plasmoid-padelle
   ```

2. **Install the plasmoid:**
   ```bash
   kpackagetool6 -i com.padelle.musik/ --type Plasma/Applet
   ```

3. **Update an existing installation:**
   ```bash
   kpackagetool6 -u com.padelle.musik/ --type Plasma/Applet
   ```

4. **Uninstall:**
   ```bash
   kpackagetool6 -r com.padelle.musik --type Plasma/Applet
   ```

---

## Acknowledgments & Credits

- Upstream project: [Rudraksh88/musik-plasmoid](https://github.com/Rudraksh88/musik-plasmoid) by **Rudraksh Tripathi**.
- Original base work: [plasmusic-toolbar](https://github.com/ccatterina/plasmusic-toolbar) by **ccatterina**.

Grateful to both authors for their foundational work. For upstream support, donations, or original assets, please visit [Rudraksh88/musik-plasmoid](https://github.com/Rudraksh88/musik-plasmoid).

---

## License

This project is licensed under the **GNU General Public License v3.0**.  
See the [**LICENSE**](LICENSE) file for the full license text.
