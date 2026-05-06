import SwiftUI
import AppKit
import Combine

@MainActor
final class WallpaperViewModel: ObservableObject {

    @Published var current: WallpaperResult?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @AppStorage("lastQuery") var query: String = ""
    @AppStorage("lastSearch") var showSearch: Bool = true
    @AppStorage("lastSource") var imageSource: ImageSource = .wallhaven

    init(previewWallpaper: WallpaperResult? = nil) {
        self.current = previewWallpaper
    }

    func onAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.current == nil && !self.query.isEmpty {
                self.fetch()
            }
        }
    }

    func toggleSearch() {
        showSearch.toggle()
    }

    func fetch() {
        guard !normalizeQuery(query).isEmpty else { return }
        isLoading = true
        Task {
            do {
                let result = switch imageSource {
                case .wallhaven:
                    try await WallpaperService.fetchWallhaven(query: normalizeQuery(query))
                case .unsplash:
                    try await WallpaperService.fetchUnsplash(query: normalizeQuery(query))
                }
                await MainActor.run {
                    self.current = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showErrorMessage(error.localizedDescription)
                }
            }
        }
    }
    
    func showErrorMessage(_ message: String) {
        errorMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.errorMessage = nil
        }
    }

    func setAsWallpaper() {
        
        if imageSource == .unsplash,
           let photo = current {
            
            guard let location = photo.download_location else { return }

            WallpaperService.trackUnsplashDownload(location: location)
        }

        guard let urlString = current?.path,
              let url = URL(string: urlString) else { return }

        URLSession.shared.downloadTask(with: url) { localURL, _, _ in
            guard let localURL else { return }

            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("deskmat_\(UUID().uuidString).jpg")

            try? FileManager.default.moveItem(at: localURL, to: dest)

            DispatchQueue.main.async {
                let workspace = NSWorkspace.shared
                NSScreen.screens.forEach { screen in
                    try? workspace.setDesktopImageURL(dest, for: screen, options: [:])
                }
            }
        }.resume()
    }

    private func normalizeQuery(_ raw: String) -> String {
        raw.lowercased()
            .split(whereSeparator: { $0 == " " || $0 == "," })
            .joined(separator: "+")
    }
    
    func openInBrowser() {
        guard let urlString = current?.path, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
