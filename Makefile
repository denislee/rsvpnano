# Makefile for RSVPnano — build, flash, and monitor the ESP32-S3 firmware.
#
# Usage:
#   make            # build the firmware (default env)
#   make upload     # discover a connected device and flash it
#   make monitor    # open the serial monitor
#   make clean      # remove build artifacts
#
# Override the build environment or PlatformIO binary if needed:
#   make upload ENV=waveshare_esp32s3 PIO=~/.platformio/penv/bin/pio

PIO ?= pio
ENV ?= waveshare_esp32s3_usb_msc

.DEFAULT_GOAL := build

.PHONY: build upload monitor clean list-ports help

build:
	$(PIO) run -e $(ENV)

# Discover a connected board and upload the firmware to it.
#
# tools/find_upload_port.py asks PlatformIO for the attached serial ports and
# prints the best candidate (an ESP32-S3 / USB-UART bridge), ignoring built-in
# motherboard serial ports. When no device is present we stop with a clear
# message instead of flashing the wrong port or hanging.
upload:
	@echo ">> Looking for a connected device..."
	@port=`python3 tools/find_upload_port.py`; \
	if [ -z "$$port" ]; then \
		echo "!! No RSVPnano device found."; \
		echo "   Connect the board (ESP32-S3) over USB and try 'make upload' again."; \
		echo "   Run 'make list-ports' to see what PlatformIO can see."; \
		exit 1; \
	fi; \
	echo ">> Found device at $$port — uploading ($(ENV))..."; \
	if ! $(PIO) run -e $(ENV) -t upload --upload-port "$$port"; then \
		echo ""; \
		echo "!! Upload failed to connect to the ESP32-S3."; \
		echo "   While the app runs, this board claims USB as a mass-storage device and"; \
		echo "   will not auto-enter the bootloader. Put it in ROM download mode by hand:"; \
		echo "     1. Hold the BOOT button down."; \
		echo "     2. Tap RESET (or unplug/replug USB) while still holding BOOT."; \
		echo "     3. Release BOOT, then run 'make upload' again."; \
		echo "   After flashing, tap RESET to run the new firmware."; \
		exit 1; \
	fi

monitor:
	$(PIO) device monitor

list-ports:
	$(PIO) device list

clean:
	$(PIO) run -e $(ENV) -t clean

help:
	@echo "Targets:"
	@echo "  build       Build the firmware (ENV=$(ENV))"
	@echo "  upload      Discover a connected device and flash it"
	@echo "  monitor     Open the serial monitor"
	@echo "  list-ports  List serial ports PlatformIO can see"
	@echo "  clean       Remove build artifacts"
