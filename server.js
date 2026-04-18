const http = require("http");
const fs = require("fs");
const fsp = require("fs/promises");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

const HOST = "127.0.0.1";
const PORT = Number(process.env.PORT || 4820);
const ROOT_DIR = __dirname;
const PUBLIC_DIR = path.join(ROOT_DIR, "public");
const SCREENSHOTS_DIR = expandHome(process.env.SCREENSHOTS_DIR) || path.join(ROOT_DIR, "screenshots");

const MIME_TYPES = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml"
};

function expandHome(inputPath) {
  if (!inputPath) {
    return null;
  }

  if (inputPath.startsWith("~/")) {
    return path.join(process.env.HOME || "", inputPath.slice(2));
  }

  return inputPath;
}

function resolveAdbPath() {
  const candidates = [
    process.env.ADB_PATH,
    process.env.ANDROID_SDK_ROOT && path.join(process.env.ANDROID_SDK_ROOT, "platform-tools", "adb"),
    process.env.ANDROID_HOME && path.join(process.env.ANDROID_HOME, "platform-tools", "adb"),
    "~/Library/Android/sdk/platform-tools/adb",
    "~/Android/Sdk/platform-tools/adb"
  ]
    .filter(Boolean)
    .map(expandHome);

  for (const candidate of candidates) {
    if (candidate && fs.existsSync(candidate)) {
      return candidate;
    }
  }

  const whichResult = spawnSync("which", ["adb"], { encoding: "utf8" });
  if (whichResult.status === 0) {
    const resolved = whichResult.stdout.trim();
    if (resolved) {
      return resolved;
    }
  }

  return null;
}

function parseDevices(rawOutput) {
  const lines = rawOutput
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line) => !line.startsWith("List of devices attached"));

  return lines.map((line) => {
    const [serial, state, ...parts] = line.split(/\s+/);
    const detailText = parts.join(" ");
    const details = {};

    for (const match of detailText.matchAll(/([a-zA-Z_]+):([^\s]+)/g)) {
      details[match[1]] = match[2];
    }

    const model = details.model ? details.model.replace(/_/g, " ") : null;
    const label = model || details.device || serial;

    return {
      serial,
      state,
      model,
      device: details.device || null,
      product: details.product || null,
      transportId: details.transport_id || null,
      label
    };
  });
}

function runProcess(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"]
    });

    const stdoutChunks = [];
    const stderrChunks = [];

    child.stdout.on("data", (chunk) => stdoutChunks.push(chunk));
    child.stderr.on("data", (chunk) => stderrChunks.push(chunk));
    child.on("error", reject);

    child.on("close", (code) => {
      const stdout = Buffer.concat(stdoutChunks);
      const stderr = Buffer.concat(stderrChunks).toString("utf8").trim();

      if (code !== 0) {
        const error = new Error(stderr || `${command} exited with code ${code}`);
        error.code = code;
        error.stderr = stderr;
        reject(error);
        return;
      }

      resolve(options.binary ? stdout : stdout.toString("utf8"));
    });
  });
}

async function listDevices() {
  const adbPath = resolveAdbPath();
  if (!adbPath) {
    throw new Error("Could not find adb. Install Android platform-tools or set ADB_PATH.");
  }

  const output = await runProcess(adbPath, ["devices", "-l"]);
  return {
    adbPath,
    devices: parseDevices(output)
  };
}

function ensurePng(buffer) {
  const pngSignature = "89504e470d0a1a0a";
  return buffer.subarray(0, 8).toString("hex") === pngSignature;
}

function sanitizeSegment(value) {
  return String(value || "device")
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/^-+|-+$/g, "") || "device";
}

async function captureScreenshot(serial) {
  const adbPath = resolveAdbPath();
  if (!adbPath) {
    throw new Error("Could not find adb. Install Android platform-tools or set ADB_PATH.");
  }

  const args = serial ? ["-s", serial, "exec-out", "screencap", "-p"] : ["exec-out", "screencap", "-p"];
  const imageBuffer = await runProcess(adbPath, args, { binary: true });

  if (!ensurePng(imageBuffer)) {
    throw new Error("adb returned data that does not look like a PNG screenshot.");
  }

  await fsp.mkdir(SCREENSHOTS_DIR, { recursive: true });

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const filename = `board-${sanitizeSegment(serial)}-${timestamp}.png`;
  const absolutePath = path.join(SCREENSHOTS_DIR, filename);

  await fsp.writeFile(absolutePath, imageBuffer);

  return {
    filename,
    url: `/screenshots/${encodeURIComponent(filename)}`,
    capturedAt: new Date().toISOString(),
    sizeBytes: imageBuffer.length,
    serial: serial || null
  };
}

async function getScreenshotList() {
  await fsp.mkdir(SCREENSHOTS_DIR, { recursive: true });
  const entries = await fsp.readdir(SCREENSHOTS_DIR, { withFileTypes: true });

  const screenshots = await Promise.all(
    entries
      .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".png"))
      .map(async (entry) => {
        const absolutePath = path.join(SCREENSHOTS_DIR, entry.name);
        const stats = await fsp.stat(absolutePath);

        return {
          filename: entry.name,
          url: `/screenshots/${encodeURIComponent(entry.name)}`,
          sizeBytes: stats.size,
          modifiedAt: stats.mtime.toISOString()
        };
      })
  );

  return screenshots.sort((left, right) => right.modifiedAt.localeCompare(left.modifiedAt));
}

async function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];

    req.on("data", (chunk) => chunks.push(chunk));
    req.on("error", reject);
    req.on("end", () => {
      if (chunks.length === 0) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString("utf8")));
      } catch (error) {
        reject(new Error("Request body must be valid JSON."));
      }
    });
  });
}

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(statusCode, {
    "Content-Type": MIME_TYPES[".json"],
    "Content-Length": Buffer.byteLength(body),
    "Cache-Control": "no-store"
  });
  res.end(body);
}

function sendText(res, statusCode, body) {
  res.writeHead(statusCode, {
    "Content-Type": "text/plain; charset=utf-8",
    "Content-Length": Buffer.byteLength(body)
  });
  res.end(body);
}

async function sendFile(res, filePath) {
  const extension = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[extension] || "application/octet-stream";
  const data = await fsp.readFile(filePath);

  res.writeHead(200, {
    "Content-Type": contentType,
    "Content-Length": data.length,
    "Cache-Control": extension === ".png" ? "no-store" : "public, max-age=300"
  });
  res.end(data);
}

function normalizeScreenshotPath(urlPath) {
  const prefix = "/screenshots/";
  const relative = decodeURIComponent(urlPath.slice(prefix.length));
  const normalized = path.normalize(relative);

  if (
    !relative ||
    normalized.startsWith("..") ||
    path.isAbsolute(normalized)
  ) {
    return null;
  }

  return path.join(SCREENSHOTS_DIR, normalized);
}

async function handleApiRequest(req, res, urlPath) {
  if (req.method === "GET" && urlPath === "/api/health") {
    sendJson(res, 200, {
      ok: true
    });
    return;
  }

  if (req.method === "GET" && urlPath === "/api/status") {
    const screenshots = await getScreenshotList();

    try {
      const { adbPath, devices } = await listDevices();
      sendJson(res, 200, {
        ok: true,
        adbPath,
        screenshotsDir: SCREENSHOTS_DIR,
        devices,
        latestScreenshot: screenshots[0] || null
      });
      return;
    } catch (error) {
      sendJson(res, 200, {
        ok: false,
        adbPath: resolveAdbPath(),
        screenshotsDir: SCREENSHOTS_DIR,
        error: error.message,
        devices: [],
        latestScreenshot: screenshots[0] || null
      });
      return;
    }
  }

  if (req.method === "GET" && urlPath === "/api/devices") {
    const result = await listDevices();
    sendJson(res, 200, result);
    return;
  }

  if (req.method === "GET" && urlPath === "/api/screenshots") {
    const screenshots = await getScreenshotList();
    sendJson(res, 200, {
      screenshots
    });
    return;
  }

  if (req.method === "POST" && urlPath === "/api/screenshot") {
    const body = await readJsonBody(req);
    let targetSerial = body.serial || null;

    if (!targetSerial) {
      const { devices } = await listDevices();
      const onlineDevices = devices.filter((device) => device.state === "device");

      if (onlineDevices.length === 0) {
        sendJson(res, 400, {
          ok: false,
          error: "No ready Android device is attached."
        });
        return;
      }

      if (onlineDevices.length > 1) {
        sendJson(res, 400, {
          ok: false,
          error: "More than one device is attached. Choose a device first."
        });
        return;
      }

      targetSerial = onlineDevices[0] ? onlineDevices[0].serial : null;
    }

    const screenshot = await captureScreenshot(targetSerial);
    sendJson(res, 200, {
      ok: true,
      screenshot
    });
    return;
  }

  sendJson(res, 404, {
    ok: false,
    error: "Not found."
  });
}

const server = http.createServer(async (req, res) => {
  try {
    const requestUrl = new URL(req.url, `http://${req.headers.host || `${HOST}:${PORT}`}`);
    const urlPath = requestUrl.pathname;

    if (urlPath.startsWith("/api/")) {
      await handleApiRequest(req, res, urlPath);
      return;
    }

    if (req.method === "GET" && urlPath.startsWith("/screenshots/")) {
      const absolutePath = normalizeScreenshotPath(urlPath);
      if (!absolutePath || !fs.existsSync(absolutePath)) {
        sendText(res, 404, "Screenshot not found.");
        return;
      }

      await sendFile(res, absolutePath);
      return;
    }

    const requestedFile = urlPath === "/" ? "index.html" : urlPath.slice(1);
    const staticPath = path.resolve(PUBLIC_DIR, requestedFile);
    if (
      !staticPath.startsWith(`${PUBLIC_DIR}${path.sep}`) &&
      staticPath !== path.join(PUBLIC_DIR, "index.html")
    ) {
      sendText(res, 404, "Not found.");
      return;
    }

    if (!fs.existsSync(staticPath)) {
      sendText(res, 404, "Not found.");
      return;
    }

    await sendFile(res, staticPath);
  } catch (error) {
    sendJson(res, 500, {
      ok: false,
      error: error.message
    });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Board Screenshot App running at http://${HOST}:${PORT}`);
  console.log(`Screenshots will be saved to ${SCREENSHOTS_DIR}`);
});
