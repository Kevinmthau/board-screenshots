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

## Notes

- The app auto-detects `adb` from the common macOS SDK path `~/Library/Android/sdk/platform-tools/adb`.
- If your `adb` binary lives somewhere else, start the app with `ADB_PATH=/path/to/adb npm start`.
- Screenshots are saved to `/Users/kevinthau/board-screenshot-app/screenshots`.
