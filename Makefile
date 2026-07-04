APP_NAME := LidLock
APP_DIR := .build/$(APP_NAME).app
INSTALL_DIR := /Applications
SWIFT_SOURCES := Sources

.PHONY: build run app install clean format check

build:
	swift build -c release

format:
	xcrun swift-format format --in-place --recursive $(SWIFT_SOURCES)

check:
	xcrun swift-format lint --strict --recursive $(SWIFT_SOURCES)

run:
	swift run

app:
	./scripts/bundle.sh

install: app
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP_DIR)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	swift package clean
	rm -rf "$(APP_DIR)"
