import Foundation
import Testing
@testable import YcradioCore

@Suite("Now playing feed")
struct NowPlayingTests {
    private let message = """
    {"advice":{"reconnect":"yes"},"data":{"plays":[
      {"service_id":3,"played_at":"2026-11-18T07:48:51.000-06:00","song":
        {"song_id":35065,"title":"Carnaval","duration":"10:00","composer":"Robert Schumann"}},
      {"service_id":3,"played_at":"2026-11-18T07:41:27.000-06:00","song":
        {"song_id":595939,"title":"Fall River Legend","composer":"Morton Gould"}}
    ]}}
    """

    @Test func takesTheCurrentPlayAndItsComposer() {
        let nowPlaying = NowPlaying(message: message)
        #expect(nowPlaying?.title == "Carnaval")
        #expect(nowPlaying?.composer == "Robert Schumann")
        #expect(nowPlaying?.displayName == "Robert Schumann — Carnaval")
    }

    @Test func toleratesMissingComposer() {
        let nowPlaying = NowPlaying(message: #"{"data":{"plays":[{"song":{"title":"Etude"}}]}}"#)
        #expect(nowPlaying?.title == "Etude")
        #expect(nowPlaying?.displayName == "Etude")
        #expect(NowPlaying(title: "Etude", composer: "").displayName == "Etude")
    }

    @Test func ignoresMessagesWithoutAPlay() {
        #expect(NowPlaying(message: #"{"data":{"plays":[]}}"#) == nil)
        #expect(NowPlaying(message: #"{"data":null,"advice":{"reconnect":"yes"}}"#) == nil)
        #expect(NowPlaying(message: "keepalive") == nil)
        #expect(NowPlaying(message: #"{"data":{"plays":[{"song":{"title":""}}]}}"#) == nil)
    }
}
