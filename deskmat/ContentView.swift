//
//  ContentView.swift
//  deskmat
//
//  Created by Vjeko on 04.05.2026..
//
import SwiftUI
import AppKit

struct WallpaperResult: Identifiable, Codable {
    let id: String
    let path: String
    let thumbs: Thumbs

    struct Thumbs: Codable {
        let large: String
        let original: String
        let small: String
    }
}

struct WallhavenResponse: Codable {
    let data: [WallpaperResult]
}

struct InstantTooltip: ViewModifier {
    let text: String
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovering = $0 }
            .background(
                Group {
                    if isHovering {
                        Text(text)
                            .font(.caption)
                            .fixedSize()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            .offset(y: -36)
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .top
            )
            .animation(.easeInOut(duration: 0.1), value: isHovering)
    }
}

extension View {
    func instantTooltip(_ text: String) -> some View {
        modifier(InstantTooltip(text: text))
    }
}

struct ContentView: View {
    @AppStorage("lastQuery") private var query: String = ""
    @State private var current: WallpaperResult? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @AppStorage("lastSearch") private var showSearch: Bool = true

    init(previewWallpaper: WallpaperResult? = nil) {
        _current = State(initialValue: previewWallpaper)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen image
            if let wallpaper = current {
                AsyncImage(url: URL(string: wallpaper.path)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        GeometryReader { geo in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }
                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Failed to load image")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !isLoading {
                Text("Type in a query and hit Enter or press Refresh")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom search bar overlay
            HStack(spacing: 10) {
                TextField("Search example: 'night sky'", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { fetchWallpapers() }
                    .opacity(showSearch ? 1 : 0)
                    .disabled(!showSearch)
                    .frame(width: showSearch ? nil : 0)
                
                Button(action: toggleSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                }
                .instantTooltip("Toggle search")

                Button(action: fetchWallpapers) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                }
                .instantTooltip("Fetch new wallpaper")
                .disabled(isLoading)

                Button(action: setAsWallpaper) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 16, weight: .semibold))
                }
                .instantTooltip("Set as desktop wallpaper")
                .disabled(current == nil || isLoading)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .animation(.easeInOut(duration: 0.2), value: showSearch)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if current == nil && !query.isEmpty {
                    fetchWallpapers()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: openInBrowser) {
                    Image(systemName: "safari")
                        .font(.system(size: 16, weight: .semibold))
                }
                .help("Open image in browser")
                .disabled(current == nil)
            }
        }
        .toolbar(.visible, for: .windowToolbar)
    }
    
    private func openInBrowser() {
        guard let urlString = current?.path, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func toggleSearch() {
      showSearch = !showSearch
    }

    private func setAsWallpaper() {
        guard let urlString = current?.path, let url = URL(string: urlString) else { return }

        // Download the image to a temp file then set it
        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else { return }

            // Use unique filename each time to avoid stale file lock
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("deskmat_\(UUID().uuidString).jpg")
            try? FileManager.default.moveItem(at: localURL, to: dest)

            DispatchQueue.main.async {
                let workspace = NSWorkspace.shared
                let screens = NSScreen.screens
                for screen in screens {
                    try? workspace.setDesktopImageURL(dest, for: screen, options: [:])
                }
            }
        }.resume()
    }

    private func normalizeQuery(_ raw: String) -> String {
        let tokens = raw
            .components(separatedBy: CharacterSet(charactersIn: ",").union(.whitespaces))
            .flatMap { $0.components(separatedBy: " and ") }
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty && $0 != "and" }
        return tokens.joined(separator: "+")
    }

    private func fetchWallpapers() {
        let normalized = normalizeQuery(query)
        guard !normalized.isEmpty else { return }

        var components = URLComponents(string: "https://wallhaven.cc/api/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: normalized),
            URLQueryItem(name: "categories", value: "110"),
            URLQueryItem(name: "purity", value: "100"),
            URLQueryItem(name: "sorting", value: "random"),
            URLQueryItem(name: "order", value: "desc")
        ]

        guard let url = components.url else { return }

        isLoading = true
        errorMessage = nil
        current = nil

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(WallhavenResponse.self, from: data)
                    current = decoded.data.randomElement()
                } catch {
                    errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView(previewWallpaper: WallpaperResult(
        id: "1",
        path: "https://w.wallhaven.cc/full/85/wallhaven-85r992.jpg",
        thumbs: .init(large: "", original: "", small: "")
    ))
}
