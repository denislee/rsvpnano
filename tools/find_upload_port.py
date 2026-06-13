#!/usr/bin/env python3
"""Discover the serial port of a connected RSVPnano (ESP32-S3) board.

Asks PlatformIO for the attached serial ports and prints the best candidate to
stdout. A real USB device reports a hardware ID; built-in motherboard serial
ports (``/dev/ttyS*`` with ``hwid == "n/a"``) are ignored so we never try to
flash the wrong port. Espressif's USB VID (303A) and common USB-UART bridges
are preferred.

Exit status:
  0  a port was found (printed to stdout)
  1  no suitable device is connected
  2  PlatformIO could not be run
"""

import json
import subprocess
import sys

# Substrings that strongly indicate an ESP32 board or a USB-UART bridge.
PREFERRED_MARKERS = (
    "303a",            # Espressif USB VID
    "espressif",
    "usb jtag",        # ESP32-S3 native USB ("USB JTAG/serial debug unit")
    "cp210",           # Silicon Labs CP210x
    "ch340", "ch910",  # WCH bridges
    "qinheng",
    "ftdi",
)


def list_ports():
    try:
        out = subprocess.check_output(
            ["pio", "device", "list", "--json-output"],
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    try:
        return json.loads(out)
    except ValueError:
        return []


def main():
    ports = list_ports()
    if ports is None:
        sys.stderr.write("error: could not run 'pio device list'\n")
        return 2

    # Only consider ports that report a real hardware ID.
    real = [p for p in ports if (p.get("hwid") or "n/a").lower() != "n/a"]

    def score(port):
        text = "{} {}".format(port.get("hwid", ""), port.get("description", "")).lower()
        return any(marker in text for marker in PREFERRED_MARKERS)

    preferred = [p for p in real if score(p)]
    chosen = (preferred or real)
    if not chosen:
        return 1

    print(chosen[0]["port"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
