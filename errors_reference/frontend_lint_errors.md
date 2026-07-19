# Frontend & Website Emulator Troubleshooting Reference

This guide outlines common issues encountered during frontend preview and responsive layout design when using the integrated Website Emulator.

## 1. CORS Block / Cross-Origin Request Blocked
* **The Error**: Resources fail to load, or JavaScript displays `Access-Control-Allow-Origin` console errors when fetching files.
* **The Cause**: Attempting to preview HTML pages directly from the `file://` protocol or fetching across local server boundaries.
* **The Fix**: Always serve pages using the integrated HTTP Emulator server via `<Space> + w`. It spins up `emulator.py` locally and loads pages within `http://localhost:8000/` which safely conforms to identical origins.

## 2. Broken Relative Asset Paths (CSS, JS, Images)
* **The Error**: Stylesheets are missing, or images fail to display when viewing via the Website Emulator.
* **The Cause**: Absolute paths (e.g., `/images/logo.png`) are resolved relative to the web root instead of the current project directory.
* **The Fix**: Always use relative paths (e.g., `./images/logo.png` or `../css/style.css`) to ensure assets resolve identically across local file systems, the background emulator server, and remote deployment directories.

## 3. Keyboard Input Interception in Viewports
* **The Error**: Pressing arrow keys or navigation hotkeys inside the emulator input bar modifies active text instead of navigating the responsive webpage.
* **The Cause**: Focus is inside the outer emulator wrapper's URL path input bar.
* **The Fix**:
  - Hit **`Escape`** to dismiss the auto-complete popup.
  - Click inside the iframe workspace viewport to focus your page.
  - Alternatively, click **Reload** to refresh the iframe and return standard focus to the nested browser window.

## 4. Cached Style Sheets Not Updating
* **The Error**: Editing a CSS file doesn't update the look inside the Website Emulator.
* **The Cause**: Browsers cache static files aggressively.
* **The Fix**:
  - Click the **Reload** button in the top menu.
  - Hold down **`Ctrl + F5`** (or `Cmd + Shift + R` on macOS) to force a hard cache clear.
