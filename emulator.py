"""
Website Emulator Server Module.
Provides a local HTTP development server designed to emulate responsive devices
and serve HTML files from the workspace directory.
"""

import http.server
import socketserver
import sys
import os
import socket

PORT = 8000  # pylint: disable=invalid-name
DIRECTORY = "."

if len(sys.argv) > 1:
    try:
        PORT = int(sys.argv[1])  # pylint: disable=invalid-name
    except ValueError:
        pass

if len(sys.argv) > 2:
    DIRECTORY = sys.argv[2]
    if os.path.exists(DIRECTORY):
        os.chdir(DIRECTORY)

# Define the HTML template for our website emulator UI
EMULATOR_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Website Emulator - Standard Vim Workspace</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #1a1a1a;
            color: #f0f0f0;
            height: 100vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        /* Top Navigation Bar */
        .navbar {
            background-color: #262626;
            border-bottom: 1px solid #333333;
            padding: 10px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 15px;
            z-index: 100;
        }
        .logo-section {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .logo-text {
            font-weight: 700;
            font-size: 1rem;
            letter-spacing: 0.5px;
            color: #007acc;
            text-transform: uppercase;
        }
        .active-file-display {
            font-size: 0.85rem;
            color: #888;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .controls-section {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        /* Style controls */
        select, button, input {
            background-color: #333333;
            color: #ffffff;
            border: 1px solid #444444;
            padding: 6px 12px;
            border-radius: 4px;
            font-size: 0.85rem;
            outline: none;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        select:hover, button:hover {
            background-color: #444444;
            border-color: #007acc;
        }
        input {
            width: 240px;
            cursor: text;
        }
        input:focus {
            border-color: #007acc;
            background-color: #3b3b3b;
        }
        /* Main Workspace */
        .workspace {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: #0f0f0f;
            padding: 40px;
            overflow: auto;
            position: relative;
        }
        /* Device Container Wrapper */
        .device-container {
            background-color: #ffffff;
            border: 12px solid #262626;
            border-radius: 16px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7);
            transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
            display: flex;
            flex-direction: column;
            position: relative;
            overflow: visible; /* To let dimensions tag hang out */
        }
        /* Emulator Iframe */
        iframe {
            background-color: #ffffff;
            border: none;
            width: 100%;
            height: 100%;
            transition: all 0.2s ease;
        }
        /* Device Dimensions Tag */
        .device-info-tag {
            position: absolute;
            bottom: -35px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 0.75rem;
            color: #888;
            background: #262626;
            padding: 4px 12px;
            border-radius: 4px;
            border: 1px solid #333;
            white-space: nowrap;
        }
        /* Quick status pill */
        .status-pill {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: #4caf50;
        }
        /* Buttons with accent colors */
        .btn-primary {
            background-color: #007acc;
            border-color: #0062a3;
        }
        .btn-primary:hover {
            background-color: #008be6;
            border-color: #007acc;
        }
        .btn-rotate {
            display: none;
        }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="logo-section">
            <span class="status-pill"></span>
            <span class="logo-text">Vim Emulator</span>
            <span class="active-file-display">| <span id="current-url">Loading...</span></span>
        </div>

        <div class="controls-section">
            <input type="text" id="url-bar" value="" placeholder="Enter filename (e.g., index.html)">
            <button class="btn-primary" onclick="navigateUrl()">Go</button>
            <button onclick="reloadFrame()">Reload</button>

            <select id="device-select" onchange="updateDevice()">
                <option value="responsive">Responsive Mode</option>
                <option value="iphone14">iPhone 14 Pro (393 x 852)</option>
                <option value="galaxys20">Galaxy S20 (360 x 800)</option>
                <option value="ipadair">iPad Air (820 x 1180)</option>
                <option value="macbook">MacBook Air (1280 x 800)</option>
                <option value="desktop">Full HD Desktop (1920 x 1080)</option>
            </select>

            <button id="orient-btn" class="btn-rotate" onclick="toggleOrientation()">Rotate</button>
            <button onclick="toggleDarkMode()">Invert Colors (Dark Mode)</button>
        </div>
    </div>

    <div class="workspace">
        <div class="device-container" id="device-container">
            <iframe id="emulator-iframe" src=""></iframe>
            <div class="device-info-tag" id="device-info-tag">Responsive Mode</div>
        </div>
    </div>

    <script>
        const iframe = document.getElementById('emulator-iframe');
        const container = document.getElementById('device-container');
        const infoTag = document.getElementById('device-info-tag');
        const urlBar = document.getElementById('url-bar');
        const currentUrlDisplay = document.getElementById('current-url');
        const orientBtn = document.getElementById('orient-btn');

        let currentDevice = 'responsive';
        let isLandscape = false;
        let isDarkMode = false;

        // Parse initial page query parameter
        const urlParams = new URLSearchParams(window.location.search);
        let targetPage = urlParams.get('page') || 'index.html';

        // Set initial iframe src and UI states
        iframe.src = '/' + targetPage;
        urlBar.value = targetPage;
        currentUrlDisplay.textContent = targetPage;

        // Update path bar on iframe load
        iframe.addEventListener('load', () => {
            try {
                const relativePath = iframe.contentWindow.location.pathname.substring(1);
                if (relativePath) {
                    urlBar.value = relativePath;
                    currentUrlDisplay.textContent = relativePath;
                }
            } catch (e) {
                // Ignore cross-origin security issues if they navigate outside
            }
        });

        function navigateUrl() {
            let path = urlBar.value.trim();
            if (path.startsWith('/')) {
                path = path.substring(1);
            }
            iframe.src = '/' + path;
            currentUrlDisplay.textContent = path;
        }

        urlBar.addEventListener('keypress', function (e) {
            if (e.key === 'Enter') {
                navigateUrl();
            }
        });

        function reloadFrame() {
            iframe.contentWindow.location.reload();
        }

        const devices = {
            responsive: { width: '100%', height: '100%', canRotate: false },
            iphone14: { width: '393px', height: '852px', canRotate: true },
            galaxys20: { width: '360px', height: '800px', canRotate: true },
            ipadair: { width: '820px', height: '1180px', canRotate: true },
            macbook: { width: '1280px', height: '800px', canRotate: false },
            desktop: { width: '1920px', height: '1080px', canRotate: false }
        };

        function updateDevice() {
            const val = document.getElementById('device-select').value;
            currentDevice = val;
            const device = devices[val];

            if (device.canRotate) {
                orientBtn.style.display = 'inline-block';
            } else {
                orientBtn.style.display = 'none';
                isLandscape = false;
            }

            applyDimensions();
        }

        function toggleOrientation() {
            isLandscape = !isLandscape;
            applyDimensions();
        }

        function applyDimensions() {
            const device = devices[currentDevice];
            let w = device.width;
            let h = device.height;

            if (isLandscape && device.canRotate) {
                w = device.height;
                h = device.width;
            }

            container.style.width = w;
            container.style.height = h;

            if (currentDevice === 'responsive') {
                container.style.width = '100%';
                container.style.height = '100%';
                container.style.border = 'none';
                container.style.borderRadius = '0';
                infoTag.textContent = 'Responsive Mode (100% x 100%)';
            } else {
                container.style.border = '12px solid #262626';
                container.style.borderRadius = '16px';
                infoTag.textContent = `${currentDevice.toUpperCase()} (${w} x ${h})`;
            }
        }

        function toggleDarkMode() {
            isDarkMode = !isDarkMode;
            if (isDarkMode) {
                iframe.style.filter = 'invert(1) hue-rotate(180deg)';
            } else {
                iframe.style.filter = 'none';
            }
        }

        // Initialize view
        applyDimensions();
    </script>
</body>
</html>
"""

class EmulatorRequestHandler(http.server.SimpleHTTPRequestHandler):
    """
    HTTP request handler that intercepts emulator page requests
    and falls back to standard file serving for other resources.
    """
    def do_GET(self):
        # Serve the emulator page when /__emulator__ is requested
        if self.path == '/__emulator__' or self.path.startswith('/__emulator__?'):
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(EMULATOR_HTML.encode('utf-8'))
        else:
            # Fall back to standard file server
            super().do_GET()

def is_port_in_use(port):
    """
    Checks if the specified port is already open/in use on localhost.
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def run():
    """
    Initializes and runs the emulator TCPServer on the configured port.
    """
    if is_port_in_use(PORT):
        print(f"Port {PORT} is already in use. Assuming server is already running.")
        return

    # Use standard TCPServer with address reuse
    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("", PORT), EmulatorRequestHandler) as httpd:
            print(f"Serving Website Emulator at http://localhost:{PORT}/__emulator__")
            print(f"Local files served from {os.getcwd()}")
            httpd.serve_forever()
    except Exception as e:  # pylint: disable=broad-exception-caught
        print(f"Error starting server: {e}")

if __name__ == '__main__':
    run()
