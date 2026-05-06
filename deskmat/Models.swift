struct WallpaperResult: Identifiable, Codable {
    let id: String
    let path: String
    let download_location: String?
    let user: String?
    let userLink: String?
}

struct WallhavenResponse: Codable {
    let data: [WallpaperResult]
}

struct UnsplashPhoto: Codable {
    let id: String
    let urls: Urls
    let links: Links
    let user: User

    struct Urls: Codable {
        let regular: String
        let full: String
    }
    
    struct Links: Codable {
        let download_location: String
    }
    
    struct User: Codable {
        let name: String
        let links: UserLinks
    }
    
    struct UserLinks: Codable {
        let html: String
    }
}

enum ImageSource: String, CaseIterable {
    case wallhaven
    case unsplash
}
