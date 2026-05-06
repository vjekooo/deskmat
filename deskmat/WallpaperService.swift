import Foundation

struct WallpaperService {
    
    static var unsplashKey: String {
        Bundle.main.object(forInfoDictionaryKey: "UNSPLASH_ACCESS_KEY") as? String ?? ""
    }

    static func fetchWallhaven(query: String) async throws -> WallpaperResult {
        var components = URLComponents(string: "https://wallhaven.cc/api/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sorting", value: "random"),
            URLQueryItem(name: "order", value: "desc")
        ]
        guard let url = components.url else { throw NSError(domain: "Invalid URL", code: 0) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(WallhavenResponse.self, from: data)
        
        guard let item = decoded.data.randomElement() else {
            throw NSError(domain: "No results", code: 0)
        }
        return item
    }
    
    static func fetchUnsplash(query: String) async throws -> WallpaperResult {
        var components = URLComponents(string: "https://api.unsplash.com/photos/random")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "client_id", value: unsplashKey)
        ]
        guard let url = components.url else { throw NSError(domain: "Invalid URL", code: 0) }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "No response", code: 0)
        }

        if httpResponse.statusCode != 200 {
            if let apiError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = apiError["errors"] as? [String] {
                throw NSError(
                    domain: "UnsplashAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errors.joined(separator: ", ")]
                )
            }
            throw NSError(
                domain: "UnsplashAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
            )
        }

        let decoded = try JSONDecoder().decode(UnsplashPhoto.self, from: data)
        return WallpaperResult(
            id: decoded.id,
            path: decoded.urls.full,
            download_location: decoded.links.download_location,
            user: decoded.user.name,
            userLink: decoded.user.links.html
        )
    }
    
    static func trackUnsplashDownload(location: String) {
        guard var components = URLComponents(string: location) else { return }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: unsplashKey)
        ]

        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url).resume()
    }
}
