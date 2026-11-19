import AVFoundation
import Testing
@testable import YcradioCore

@Suite("Radio player pause timebox")
@MainActor
struct RadioPlayerPauseTests {
    private static let sound = URL(fileURLWithPath: "/System/Library/Sounds/Glass.aiff")

    private func playing(_ grace: Duration) async -> (RadioPlayer, AVPlayerItem) {
        let player = RadioPlayer(url: Self.sound, pauseGrace: grace)
        player.play()
        let item = player.player.currentItem!
        for _ in 0..<50 where item.status != .readyToPlay {
            try? await Task.sleep(for: .milliseconds(20))
        }
        return (player, item)
    }

    @Test func resumeInsideTheTimeboxPlaysTheKeptBuffer() async {
        let (player, item) = await playing(.seconds(30))
        player.pause()
        #expect(player.state == .paused)
        #expect(player.player.currentItem === item)

        player.play()
        #expect(player.player.currentItem === item)
        #expect(player.state == .buffering)
    }

    @Test func resumeAfterTheTimeboxReconnectsAtTheLiveEdge() async throws {
        let (player, item) = await playing(.milliseconds(50))
        player.pause()

        try await Task.sleep(for: .milliseconds(300))
        #expect(player.player.currentItem == nil)

        player.play()
        #expect(player.player.currentItem != nil)
        #expect(player.player.currentItem !== item)
    }
}
