# New MD File Here - macOS Quick Action

This Quick Action adds a **New MD File Here** option to your Finder right-click menu. Right-click in the background of any Finder window (no file needs to be selected), choose it, type a name, and a new `.md` file is created in that folder with `hello gorgeous` inside it.

It's the Markdown equivalent of Finder's built-in "New Folder" — a single right-click to start a new note, instead of creating a blank file in an editor and renaming it.

## How it works

Right-clicking an empty Finder window and choosing the action runs an AppleScript that:

1. Asks Finder for the folder currently in view (`insertion location` — the same folder "New Folder" would use).
2. Shows a small dialog with a text field followed by a fixed, non-editable `.md` label, so you only ever type the name, never the extension.
3. If a file with that name already exists, auto-numbers it (`notes.md` → `notes 2.md` → `notes 3.md` …), the same way Finder itself handles duplicate names — it never overwrites.
4. Writes `hello gorgeous` into the new file and reveals it, selected, in Finder.

### Why it's two pieces, not one script

A Finder Service's "Run AppleScript" action doesn't get a proper main-thread run loop, so it can't reliably show its own GUI dialog — attempting to does one of two bad things: throws `NSWindow should only be instantiated on the main thread!`, or silently hangs forever. The dialog is therefore a small compiled helper app (`Contents/Resources/ArtemisHelper.app` inside the `.workflow`, built from `artemis-helper.applescript` in this repo), which gets a real window-server context the same way any ordinary Mac app does. The outer Service script just launches it and reads its answer back.

Getting that helper to actually take keyboard focus on its own (rather than sitting there until you click its Dock icon) needs `NSRunningApplication`'s `activateWithOptions:` with an explicit integer bitmask (`3`, i.e. `NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps`) — the named constants don't reliably bridge through AppleScriptObjC, so this uses the raw value instead. Running with `NSApplicationActivationPolicyAccessory` also means no Dock icon appears at all.

## Requirements and compatibility

No external dependencies — everything here is AppleScript and Automator, both built into macOS. Built and tested on an Apple Silicon Mac running a recent macOS.

## Installation

Download `New-MD-File-Here-Automator-quick-action.workflow.zip`, unzip it anywhere, then **double-click `New MD File Here.workflow`** and confirm the install when macOS asks.

Double-clicking matters. It runs Automator's installer, which does two things: copies the bundle into `~/Library/Services`, *and* registers the action's display flag. If you skip the double-click and drag the bundle into `~/Library/Services` yourself, only the first half happens, and you get an action that is installed and registered but never appears in any menu. See Troubleshooting below if that's already happened to you.

If you're updating an already-installed copy to a newer version of this repo, the installer silently does nothing the second time — it detects the existing bundle identifier and skips reinstalling, so double-clicking again won't pick up your changes. Replace the files directly in `~/Library/Services/New MD File Here.workflow/Contents/` instead, then `touch` the `.workflow` bundle, run `/System/Library/CoreServices/pbs -flush`, and `killall Finder`.

The repo also includes the unzipped `Info.plist` and `document.wflow`, plus `artemis-helper.applescript` (the source compiled into the bundled dialog helper app), if you'd rather adapt this for a different file type or default content.

### Where it appears

The action declares `NSSendFileTypes: public.folder` and a `fileSystemObject` input type, which is what makes it eligible for the **Quick Actions** submenu, not just the full **Services** menu — a "no input" Service (no declared file type at all) gets a working menu item under Services but never gets offered in Quick Actions, even with its display flag correctly set. Right-click Finder's background (on a folder, on the Desktop, in any view) and it shows up under both **Quick Actions** and **Services → General → New MD File Here**. The script ignores whatever Finder actually hands it as input and always asks Finder directly for the current window's folder (`insertion location`), so right-clicking a specific folder still creates the new file as a sibling, the same way "New Folder" behaves.

## Troubleshooting: installed but not showing in the right-click menu

If the Quick Action doesn't appear in Finder, the cause is almost always a
missing display flag rather than anything wrong with the workflow itself.

macOS keeps a per-service on/off record in `~/Library/Preferences/pbs.plist`
under `NSServicesStatus`. Double-clicking the `.workflow` lets Automator write
that record for you. **Copying the bundle straight into `~/Library/Services`
by hand does not**, and the result is an action that is correctly installed,
correctly registered, and completely invisible.

First check whether the flag exists:

```bash
defaults read pbs NSServicesStatus
```

If there is no entry for this action, that's the problem. Either reinstall by
double-clicking the `.workflow` file, or write the entry directly:

```bash
TMP=$(mktemp -d)
cp ~/Library/Preferences/pbs.plist "$TMP/pbs.plist.bak"   # backup
defaults export pbs "$TMP/pbs.plist"

K="com.dinidh.automator.new-md-file-here - New MD File Here - runWorkflowAsService"
PB=/usr/libexec/PlistBuddy
$PB -c "Add :NSServicesStatus:'$K' dict" "$TMP/pbs.plist"
$PB -c "Add :NSServicesStatus:'$K':presentation_modes dict" "$TMP/pbs.plist"
for m in ContextMenu ServicesMenu TouchBar; do
  $PB -c "Add :NSServicesStatus:'$K':presentation_modes:$m bool true" "$TMP/pbs.plist"
done

defaults import pbs "$TMP/pbs.plist"
/System/Library/CoreServices/pbs -flush
killall Finder
```

Note that `defaults write -dict-add` will not work for this key: it tries to
parse the leading identifier as a plist on its own and fails, which is why
the export/edit/import dance is needed.

### Two places that will *not* help

- **System Settings → General → Login Items & Extensions → Extensions.**
  Automator Quick Actions are legacy Services, not app extensions, so they are
  never listed here.
- **The "Customise…" button** at the bottom of the Quick Actions submenu opens
  that same pane, so it only ever shows Apple's built-in Quick Actions.

Where these *are* listed and can be toggled: **System Settings → Keyboard →
Keyboard Shortcuts… → Services**.

## License

Licensed under the GNU Affero General Public License v3.0. See the LICENSE file for details.
