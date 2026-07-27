APP_NAME := LidLock
APP_DIR := .build/$(APP_NAME).app
INSTALL_DIR := /Applications
SWIFT_SOURCES := Sources

.PHONY: build run app notarize install clean format check

build:
	swift build -c release

format:
	xcrun swift-format format --in-place --recursive $(SWIFT_SOURCES)

check:
	xcrun swift-format lint --strict --recursive $(SWIFT_SOURCES)

run:
	swift run

# Assemble the .app (pass SIGN_ID=<cert name> to sign with a stable identity
# instead of ad-hoc, or CODESIGN_IDENTITY=<id> for a Developer ID release build)
app:
	./scripts/bundle.sh

# Notarize and staple the built bundle (needs NOTARY_* env; see the script).
# Sign with a Developer ID first: CODESIGN_IDENTITY=<id> make notarize
notarize: app
	./scripts/notarize-app.sh

install: app
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP_DIR)" "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	swift package clean
	rm -rf "$(APP_DIR)"
