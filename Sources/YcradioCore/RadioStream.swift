import Foundation

/// One of the YourClassical radio streams. `id` is the playlist slug: it names
/// the audio stream on yourclassical.org and the now-playing feed for it.
public struct RadioStream: Equatable, Sendable {
    public let id: String
    public let name: String
    public let url: URL

    public init(id: String, name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }

    private init(_ id: String, _ name: String, _ host: String, _ file: String) {
        self.init(id: id, name: name, url: URL(string: "https://\(host).stream.publicradio.org/\(file).aac")!)
    }

    public static let yourClassicalRadio = RadioStream("classical-24", "YourClassical Radio", "ycradio", "ycradio")

    /// Every stream yourclassical.org currently offers, in menu order.
    public static let all: [RadioStream] = [
        yourClassicalRadio,
        RadioStream("classical-mpr", "YourClassical MPR", "cms", "cms"),
        RadioStream("chamber-music-stream", "Chamber Music", "chambermusic", "chambermusic"),
        RadioStream("choral-stream", "Choral", "choral", "choral"),
        RadioStream("concert-band-stream", "Concert Band", "concertband", "concertband"),
        RadioStream("favorites-stream", "Essentials", "favorites", "favorites"),
        RadioStream("kids-classical-stream", "Classical Kids", "classicalkids", "classicalkids"),
        RadioStream("guitar-stream", "Guitar", "guitar", "guitar"),
        RadioStream("holiday-stream", "Holiday", "holiday", "holiday"),
        RadioStream("lullabies-stream", "Sleep", "lullabies", "lullabies"),
        RadioStream("peaceful-piano-stream", "Peaceful Piano", "peacefulpiano", "peacefulpiano"),
        RadioStream("relax-stream", "Relax", "relax", "relax"),
        RadioStream("hispanic-heritage", "Hispanic Heritage", "hispanicheritage", "hispanicheritage"),
        RadioStream("celebratethemaestro", "Celebrate the Maestro", "celebratethemaestro", "celebratethemaestro"),
        RadioStream("pixelplot", "Pixel & Plot", "pixelplot", "pixelplot"),
    ]

    private static let defaultsKey = "streamID"

    /// The last stream the user picked; the default when there is none.
    public static func saved(defaults: UserDefaults = .standard) -> RadioStream {
        all.first { $0.id == defaults.string(forKey: defaultsKey) } ?? yourClassicalRadio
    }

    public func save(defaults: UserDefaults = .standard) {
        defaults.set(id, forKey: Self.defaultsKey)
    }
}
