import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Modèle

struct ImportedTrack: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    /// On stocke seulement le nom du fichier : le chemin complet du dossier
    /// Documents peut changer entre deux mises à jour de l'appli.
    var fileName: String

    var url: URL { ImportStore.folder.appendingPathComponent(fileName) }
}

// MARK: - Stockage + import

@MainActor
final class ImportStore: ObservableObject {
    @Published private(set) var tracks: [ImportedTrack] = []

    static let folder: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Imported", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static var indexURL: URL { folder.appendingPathComponent("index.json") }

    init() { load() }

    func importFiles(_ urls: [URL]) async {
        for url in urls {
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }

            let id = UUID()
            let fileName = "\(id.uuidString).\(url.pathExtension)"
            let dest = Self.folder.appendingPathComponent(fileName)

            do {
                try FileManager.default.copyItem(at: url, to: dest)
            } catch {
                print("Erreur import:", error)
                continue
            }

            let (title, artist) = await Self.metadata(
                for: dest,
                fallback: url.deletingPathExtension().lastPathComponent
            )
            tracks.append(ImportedTrack(id: id, title: title, artist: artist, fileName: fileName))
        }
        save()
    }

    func delete(_ track: ImportedTrack) {
        try? FileManager.default.removeItem(at: track.url)
        tracks.removeAll { $0.id == track.id }
        save()
    }

    // MARK: Métadonnées (titre / artiste)

    private static func metadata(for url: URL, fallback: String) async -> (String, String) {
        let asset = AVURLAsset(url: url)
        var title = fallback
        var artist = "Artiste inconnu"

        if let items = try? await asset.load(.commonMetadata) {
            for item in items {
                guard let key = item.commonKey else { continue }
                if key == .commonKeyTitle,
                   let v = try? await item.load(.stringValue), !v.isEmpty { title = v }
                if key == .commonKeyArtist,
                   let v = try? await item.load(.stringValue), !v.isEmpty { artist = v }
            }
        }
        return (title, artist)
    }

    // MARK: Persistance

    private func save() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: Self.indexURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.indexURL),
              let saved = try? JSONDecoder().decode([ImportedTrack].self, from: data)
        else { return }
        // On ignore les entrées dont le fichier a disparu
        tracks = saved.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
}

// MARK: - Bouton d'import

struct ImportButton: View {
    @ObservedObject var store: ImportStore
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            Label("Importer depuis le téléphone", systemImage: "square.and.arrow.down")
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            Task { await store.importFiles(urls) }
        }
    }
}

// MARK: - Liste (exemple, à adapter à ta Bibliothèque)

struct ImportedTracksList: View {
    @ObservedObject var store: ImportStore
    var onPlay: (ImportedTrack) -> Void = { _ in }

    var body: some View {
        List {
            ForEach(store.tracks) { track in
                Button { onPlay(track) } label: {
                    VStack(alignment: .leading) {
                        Text(track.title).font(.headline)
                        Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                offsets.map { store.tracks[$0] }.forEach(store.delete)
            }
        }
    }
}
