import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    // MARK: - NetworkClient
    private let networkClient = NetworkClient()
    
    // MARK: - URL
    private var mostPopularMoviesUrl: URL {
        // Если мы не смогли преобразовать строку в URL, то приложение упадёт с ошибкой
        guard let url = URL(string: "https://imdb-api.com/en/API/Top250Movies/k_5kfdpbcn") else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }
    
    private enum DecodeError: Error {
        case codeError
    }
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
                
            case .success(let data):
                let movieList = try? JSONDecoder().decode(MostPopularMovies.self, from: data)
                
                if let movieList = movieList {
                    handler(.success(movieList))
                } else {
                    handler(.failure(DecodeError.codeError))
                }
            }
        }
    }
}
struct NetworkClient {
    
    private enum NetworkError: Error {
        case codeError
    }
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                handler(.failure(error))
                return
            }
            if let response = response as? HTTPURLResponse,
               response.statusCode < 200 || response.statusCode >= 300 {
                handler(.failure(NetworkError.codeError))
            }
            guard let data = data else { return }
            handler(.success(data))
        }
        task.resume()
    }
 }
