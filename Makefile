APP_NAME = Frost
BUILD_DIR = .build
RELEASE_BIN = $(BUILD_DIR)/release/$(APP_NAME)
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app

.PHONY: build run clean install

build:
	swift build -c release
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp $(RELEASE_BIN) "$(APP_BUNDLE)/Contents/MacOS/"
	@cp Frost/Resources/Info.plist "$(APP_BUNDLE)/Contents/"
	@echo "✅ $(APP_BUNDLE)"

run: build
	@open "$(APP_BUNDLE)"

debug:
	swift build
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@cp .build/debug/$(APP_NAME) "$(APP_BUNDLE)/Contents/MacOS/"
	@cp Frost/Resources/Info.plist "$(APP_BUNDLE)/Contents/"
	@open "$(APP_BUNDLE)"

clean:
	swift package clean
	@rm -rf "$(APP_BUNDLE)"

install: build
	@cp -R "$(APP_BUNDLE)" /Applications/
	@echo "✅ Installed to /Applications/$(APP_NAME).app"
