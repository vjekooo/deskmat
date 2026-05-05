import Foundation

struct WallpaperService {

    static func fetchWallhaven(query: String, completion: @escaping (Result<WallpaperResult, Error>) -> Void) {

        var components = URLComponents(string: "https://wallhaven.cc/api/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "categories", value: "110"),
            URLQueryItem(name: "purity", value: "100"),
            URLQueryItem(name: "sorting", value: "random"),
            URLQueryItem(name: "order", value: "desc")
        ]

        guard let url = components.url else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in

            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(WallhavenResponse.self, from: data)
                if let item = decoded.data.randomElement() {
                    completion(.success(item))
                }
            } catch {
                completion(.failure(error))
            }

        }.resume()
    }

    static func fetchUnsplash(query: String, completion: @escaping (Result<WallpaperResult, Error>) -> Void) {

        let key = Bundle.main.object(forInfoDictionaryKey: "UNSPLASH_ACCESS_KEY") as? String ?? ""

        var components = URLComponents(string: "https://api.unsplash.com/photos/random")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: key)
        ]

        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "No response", code: 0)))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            if httpResponse.statusCode != 200 {
                if let apiError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errors = apiError["errors"] as? [String] {

                    completion(.failure(NSError(
                        domain: "UnsplashAPI",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: errors.joined(separator: ", ")]
                    )))
                    return
                }

                completion(.failure(NSError(
                    domain: "UnsplashAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                )))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(UnsplashPhoto.self, from: data)

                let result = WallpaperResult(
                    id: decoded.id,
                    path: decoded.urls.full,
                    download_location: decoded.links.download_location
                )

                completion(.success(result))

            } catch {
                completion(.failure(error))
            }

        }.resume()
       
    }
    
    static func trackUnsplashDownload(location: String) {
        guard let url = URL(string: location) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request).resume()
    }
}
