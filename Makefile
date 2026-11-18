APP := Ycradio.app
BIN := .build/release/Ycradio

.PHONY: build test app run clean

build:
	swift build -c release

test:
	swift test

# Media keys and the menu bar extras behave best from a real bundle.
app: build
	mkdir -p $(APP)/Contents/MacOS
	cp $(BIN) $(APP)/Contents/MacOS/Ycradio
	cp Support/Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)
	@echo "Built $(APP)"

run: app
	open $(APP)

clean:
	swift package clean
