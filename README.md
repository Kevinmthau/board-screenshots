# Board Screenshot App

Small local web app for capturing PNG screenshots from an attached Board Android device.

## What it does

- Detects attached Android devices through `adb`.
- Captures screenshots with `adb exec-out screencap -p`.
- Saves images into a local screenshots folder.
- Shows the latest capture and a small recent gallery in the browser.

## Run from the repo

```bash
cd /path/to/board-screenshots
npm start
```

Then open `http://127.0.0.1:4820`.

In repo mode:

- screenshots are saved into `./screenshots`
- the UI is served from `./public`
- `adb` is detected from `ADB_PATH`, Android SDK locations, or `PATH`

## Install on your own Mac

If this Mac stays connected to a Board, install the app bundle and the launch agent:

```bash
cd /path/to/board-screenshots
npm run install:launcher
npm run install:auto-start
```

That installs `~/Applications/Board Screenshots.app` and runs the server automatically at login.

You can then:

- open `Board Screenshots.app` from Finder
- drag it into the Dock
- double-click `Open Board Screenshots.command` while working from the repo

## Build a handoff installer for another Mac

Create a distributable installer folder:

```bash
cd /path/to/board-screenshots
npm run build:installer
```

That generates:

- `dist/Board Screenshots.app`
- `dist/Board Screenshots Installer/`

The installer folder includes:

- `Board Screenshots.app`
- `Install Board Screenshots.command`
- `Uninstall Board Screenshots.command`
- `README.txt`

Send the entire `dist/Board Screenshots Installer` folder to the other Mac. On that Mac, they just double-click `Install Board Screenshots.command`.

## Packaged app behavior

The built macOS app bundle includes:

- the app server and static UI files
- a bundled `adb` binary
- a bundled `node` runtime from the machine that built the installer

When the packaged app runs:

- screenshots are saved in `~/Library/Application Support/Board Screenshots/screenshots`
- logs are written to `~/Library/Application Support/Board Screenshots/logs`
- the launch agent is installed at `~/Library/LaunchAgents/com.board-screenshots.app.plist`

If the target Mac cannot use the bundled `node` binary, the installer will try to download a matching Node runtime during install. If that download fails, install Node manually and rerun the installer.

## Notes

- `npm install` is not required for this repo. The app uses only built-in Node modules.
- `npm run build:launcher` and `npm run build:installer` require macOS tools `swift` and `iconutil`.
- `npm run build:installer` also requires a working `adb` on the build machine so it can bundle it into the packaged app.
