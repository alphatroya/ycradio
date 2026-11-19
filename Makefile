APP := Ycradio.app
BIN := .build/release/Ycradio

.PHONY: build test app run clean icon

build:
	swift build -c release

test:
	swift test

# Media keys and the menu bar extras behave best from a real bundle.
app: build
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp $(BIN) $(APP)/Contents/MacOS/Ycradio
	cp Support/Info.plist $(APP)/Contents/Info.plist
	cp Support/AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns
	codesign --force --sign - $(APP)
	@echo "Built $(APP)"

# Regenerate Support/AppIcon.icns (committed; needs only after editing MakeIcon.swift).
icon:
	swift Support/MakeIcon.swift .build/icons record
	@mkdir -p .build/AppIcon.iconset
	@for s in 16 32 128 256 512; do \
		sips -z $$s $$s .build/icons/icon-record.png --out .build/AppIcon.iconset/icon_$${s}x$${s}.png >/dev/null; \
		sips -z $$((s * 2)) $$((s * 2)) .build/icons/icon-record.png --out .build/AppIcon.iconset/icon_$${s}x$${s}@2x.png >/dev/null; \
	done
	iconutil -c icns .build/AppIcon.iconset -o Support/AppIcon.icns
	@echo "Wrote Support/AppIcon.icns"

run: app
	open $(APP)

clean:
	swift package clean
