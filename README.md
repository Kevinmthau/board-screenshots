# Board Screenshot App

Small local web app for capturing PNG screenshots from an attached Board Android device.

## What it does

- Detects attached Android devices through `adb`.
- Captures screenshots with `adb exec-out screencap -p`.
- Saves images into `screenshots/`.
- Shows the latest capture and a small recent gallery in the browser.

## Run it

```bash
cd /Users/kevinthau/board-screenshot-app
npm start
```

Then open `http://127.0.0.1:4820`.

## Run it automatically on macOS

If this computer stays connected to a Board, the best setup is to run the server as a per-user `launchd` agent at login and use a small launcher to open the UI.

Install auto-start:

```bash
cd /Users/kevinthau/board-screenshot-app
npm run install:auto-start
```

Build a Dock-friendly launcher app in `dist/`:

```bash
cd /Users/kevinthau/board-screenshot-app
npm run build:launcher
```

Install the launcher into `~/Applications` so you can keep it in the Dock:

```bash
cd /Users/kevinthau/board-screenshot-app
npm run install:launcher
```

Open the app UI:

```bash
cd /Users/kevinthau/board-screenshot-app
npm run open
```

You can also double-click `Open Board Screenshots.command`.

Remove auto-start:

```bash
cd /Users/kevinthau/board-screenshot-app
npm run uninstall:auto-start
```

## Launcher app

- `npm run build:launcher` creates `dist/Board Screenshots.app` plus a matching icon preview PNG.
- `npm run install:launcher` copies the app bundle into `~/Applications/Board Screenshots.app`.
- Once the app exists, drag it into the Dock and use it like any other launcher app.
- The launcher calls the existing `scripts/open-ui.sh`, so it opens the browser UI and kickstarts the `launchd` server if needed.
- If you move this repo to a different folder later, rebuild or reinstall the launcher so it points at the new path.

## Notes

- The app auto-detects `adb` from the common macOS SDK path `~/Library/Android/sdk/platform-tools/adb`.
- If your `adb` binary lives somewhere else, start the app with `ADB_PATH=/path/to/adb npm start`.
- Screenshots are saved to `/Users/kevinthau/board-screenshot-app/screenshots`.
- LaunchAgent logs are written to `/Users/kevinthau/board-screenshot-app/logs`.
