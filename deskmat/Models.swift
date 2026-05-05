struct WallpaperResult: Identifiable, Codable {
    let id: String
    let path: String
    let download_location: String?
}

struct WallhavenResponse: Codable {
    let data: [WallpaperResult]
}

struct UnsplashPhoto: Codable {
    let id: String
    let urls: Urls
    let links: Links

    struct Urls: Codable {
        let regular: String
        let full: String
    }
    
    struct Links: Codable {
        let download_location: String
    }
}

enum ImageSource: String, CaseIterable {
    case wallhaven
    case unsplash
}
