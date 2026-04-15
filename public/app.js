const state = {
  devices: [],
  screenshots: [],
  latestScreenshot: null
};

const elements = {
  adbPath: document.querySelector("#adbPath"),
  captureButton: document.querySelector("#captureButton"),
  deviceSelect: document.querySelector("#deviceSelect"),
  downloadLink: document.querySelector("#downloadLink"),
  gallery: document.querySelector("#gallery"),
  messageBox: document.querySelector("#messageBox"),
  previewEmpty: document.querySelector("#previewEmpty"),
  previewImage: document.querySelector("#previewImage"),
  previewMeta: document.querySelector("#previewMeta"),
  refreshButton: document.querySelector("#refreshButton"),
  saveFolder: document.querySelector("#saveFolder"),
  statusText: document.querySelector("#statusText")
};

function formatBytes(sizeBytes) {
  if (!Number.isFinite(sizeBytes)) {
    return "Unknown size";
  }

  const units = ["B", "KB", "MB", "GB"];
  let value = sizeBytes;
  let unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }

  return `${value.toFixed(value >= 10 || unitIndex === 0 ? 0 : 1)} ${units[unitIndex]}`;
}

function formatTimestamp(value) {
  if (!value) {
    return "Unknown time";
  }

  return new Date(value).toLocaleString();
}

function setMessage(text, tone = "info") {
  elements.messageBox.textContent = text;
  elements.messageBox.classList.toggle("error", tone === "error");
}

function renderDevices() {
  const previousSelection = elements.deviceSelect.value;
  elements.deviceSelect.innerHTML = "";

  if (state.devices.length === 0) {
    const option = document.createElement("option");
    option.value = "";
    option.textContent = "No attached devices found";
    elements.deviceSelect.append(option);
    elements.deviceSelect.disabled = true;
    elements.captureButton.disabled = true;
    return;
  }

  const chooseOption = document.createElement("option");
  chooseOption.value = "";
  chooseOption.textContent = state.devices.length === 1 ? "Use the attached device" : "Choose a device";
  elements.deviceSelect.append(chooseOption);

  for (const device of state.devices) {
    const option = document.createElement("option");
    option.value = device.serial;
    option.textContent = `${device.label} (${device.serial})`;
    if (device.state !== "device") {
      option.textContent += ` - ${device.state}`;
      option.disabled = true;
    }
    elements.deviceSelect.append(option);
  }

  const onlineDevices = state.devices.filter((device) => device.state === "device");
  if (onlineDevices.length === 1) {
    elements.deviceSelect.value = onlineDevices[0].serial;
  } else if (previousSelection) {
    elements.deviceSelect.value = previousSelection;
  }

  elements.deviceSelect.disabled = false;
  elements.captureButton.disabled = onlineDevices.length === 0;
}

function renderLatest() {
  const screenshot = state.latestScreenshot;
  const frame = elements.previewImage.parentElement;

  if (!screenshot) {
    frame.classList.remove("has-image");
    elements.previewImage.removeAttribute("src");
    elements.downloadLink.classList.add("hidden");
    elements.previewMeta.textContent = "No screenshots captured in this session.";
    return;
  }

  frame.classList.add("has-image");
  elements.previewImage.src = `${screenshot.url}?t=${Date.now()}`;
  elements.downloadLink.href = screenshot.url;
  elements.downloadLink.download = screenshot.filename;
  elements.downloadLink.classList.remove("hidden");

  const timestamp = screenshot.capturedAt || screenshot.modifiedAt;
  elements.previewMeta.textContent = `${screenshot.filename} • ${formatBytes(screenshot.sizeBytes)} • ${formatTimestamp(timestamp)}`;
}

function renderGallery() {
  elements.gallery.innerHTML = "";

  if (state.screenshots.length === 0) {
    const empty = document.createElement("p");
    empty.textContent = "No saved screenshots yet.";
    elements.gallery.append(empty);
    return;
  }

  for (const screenshot of state.screenshots.slice(0, 12)) {
    const link = document.createElement("a");
    link.className = "thumb";
    link.href = screenshot.url;
    link.target = "_blank";
    link.rel = "noreferrer";

    const frame = document.createElement("div");
    frame.className = "thumb-frame";

    const image = document.createElement("img");
    image.src = `${screenshot.url}?t=${Date.now()}`;
    image.alt = screenshot.filename;

    const label = document.createElement("div");
    label.className = "thumb-label";
    label.textContent = `${screenshot.filename} • ${formatTimestamp(screenshot.modifiedAt || screenshot.capturedAt)}`;

    frame.append(image);
    link.append(frame, label);
    elements.gallery.append(link);
  }
}

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  const payload = await response.json();

  if (!response.ok || payload.ok === false) {
    throw new Error(payload.error || `Request failed for ${url}`);
  }

  return payload;
}

async function refreshStatus() {
  try {
    const status = await fetch("/api/status").then((response) => response.json());
    state.devices = status.devices || [];
    state.latestScreenshot = status.latestScreenshot || null;

    elements.statusText.textContent = status.ok
      ? `${state.devices.filter((device) => device.state === "device").length} device ready`
      : status.error || "Unable to reach adb";
    elements.adbPath.textContent = status.adbPath || "Not found";
    elements.saveFolder.textContent = status.screenshotsDir || "Unknown";

    if (!status.ok) {
      setMessage(status.error || "Unable to talk to adb.", "error");
    } else {
      setMessage("Ready to capture.");
    }

    renderDevices();
    renderLatest();
  } catch (error) {
    elements.statusText.textContent = "Server error";
    setMessage(error.message, "error");
  }
}

async function refreshGallery() {
  try {
    const payload = await fetchJson("/api/screenshots");
    state.screenshots = payload.screenshots || [];
    if (!state.latestScreenshot && state.screenshots.length > 0) {
      state.latestScreenshot = state.screenshots[0];
    }
    renderLatest();
    renderGallery();
  } catch (error) {
    setMessage(error.message, "error");
  }
}

async function captureScreenshot() {
  elements.captureButton.disabled = true;
  setMessage("Capturing screenshot from the attached Board...");

  try {
    const serial = elements.deviceSelect.value || null;
    const payload = await fetchJson("/api/screenshot", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ serial })
    });

    state.latestScreenshot = payload.screenshot;
    await refreshGallery();
    renderLatest();
    setMessage(`Saved ${payload.screenshot.filename}`);
  } catch (error) {
    setMessage(error.message, "error");
  } finally {
    elements.captureButton.disabled = !state.devices.some((device) => device.state === "device");
  }
}

elements.captureButton.addEventListener("click", captureScreenshot);
elements.refreshButton.addEventListener("click", async () => {
  await refreshStatus();
  await refreshGallery();
});

Promise.all([refreshStatus(), refreshGallery()]).catch((error) => {
  setMessage(error.message, "error");
});
