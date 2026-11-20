import AVFoundation
import Foundation
import Testing
@testable import YcradioCore

@Suite("Radio stream switching")
@MainActor
struct RadioStreamSwitchTests {
    private static let sound = URL(fileURLWithPath: "/System/Library/Sounds/Glass.aiff")

    private static func local(_ name: String, _ file: String) -> RadioStream {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(file).aiff")
        return RadioStream(id: name, name: name, url: url)
    }

    @Test func switchingWhilePlayingLoadsTheNewStream() async {
        let player = RadioPlayer(stream: Self.local("a", "Glass"))
        player.play()
        let item = player.player.currentItem!
        for _ in 0..<50 where item.status != .readyToPlay {
            try? await Task.sleep(for: .milliseconds(20))
        }

        let other = Self.local("b", "Ping")
        player.select(other)

        #expect(player.stream == other)
        #expect(player.player.currentItem !== item)
        #expect(player.state != .paused)
    }

    @Test func switchingWhilePausedDropsTheBufferedItem() async {
        let player = RadioPlayer(stream: Self.local("a", "Glass"))
        player.play()
        for _ in 0..<50 where player.player.currentItem?.status != .readyToPlay {
            try? await Task.sleep(for: .milliseconds(20))
        }
        player.pause()

        let other = Self.local("b", "Ping")
        player.select(other)

        #expect(player.stream == other)
        #expect(player.player.currentItem == nil)
        #expect(player.state == .paused)
    }

    @Test func savedStreamIsRestoredAndFallsBackToTheDefault() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defer { defaults.removePersistentDomain(forName: #function) }
        let stream = RadioStream.all[3]

        stream.save(defaults: defaults)

        #expect(RadioStream.saved(defaults: defaults) == stream)
        defaults.set("gone", forKey: "streamID")
        #expect(RadioStream.saved(defaults: defaults) == .yourClassicalRadio)
    }
}
