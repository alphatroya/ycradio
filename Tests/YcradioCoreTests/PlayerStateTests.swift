import AVFoundation
import Testing
@testable import YcradioCore

@Suite("Player state")
struct PlayerStateTests {
    @Test func mapsTimeControlStatus() {
        #expect(PlayerState(.paused) == .paused)
        #expect(PlayerState(.waitingToPlayAtSpecifiedRate) == .buffering)
        #expect(PlayerState(.playing) == .playing)
    }

    @Test func everyStateHasItsOwnSymbol() {
        let symbols = [PlayerState.playing, .buffering, .paused].map(\.symbolName)
        #expect(Set(symbols).count == 3)
        #expect(symbols.allSatisfy { !$0.isEmpty })
    }
}
