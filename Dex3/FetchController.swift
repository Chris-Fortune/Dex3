//
//  FetchController.swift
//  Dex3
//
//  Created by Chris Fortune on 1/29/25.
//

import Foundation

struct FetchController {
    enum NetworkError: Error {
        case badURL, badResponse, badData
    }
    
    private let baseURL = URL(string: "https://pokeapi.co/api/v2/pokemon/")!
    
    func fetchAllPokemon() async throws -> [TempPokemon] {
        var allPokemon: [TempPokemon] = []
        
        var fetchComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        fetchComponents?.queryItems = [URLQueryItem(name: "limit", value: "386")]
        
        // Validate that its a valid URL
        guard let fetchURL = fetchComponents?.url else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: fetchURL)
        
        // Validate the response is HTTPURLResponse and has a status code of 200
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.badResponse
        }
        
        // Obtains the list of pokemon and their URLs to fetch detail information
        guard let pokeDictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any], let pokeDex = pokeDictionary["results"] as? [[String: String]] else {
            throw NetworkError.badData
        }
        
        for pokemon in pokeDex {
            if let url = pokemon["url"] {
                allPokemon.append(try await fetchPokemon(from: URL(string: url)!))
            }
        }
        
        // Should return 386 pokemon (first 3 generations)
        return allPokemon
    }
    
    private func fetchPokemon(from url: URL) async throws -> TempPokemon {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw NetworkError.badResponse
        }
        
        let tempPokemon = try JSONDecoder().decode(TempPokemon.self, from: data)
        
        print("Fetched \(tempPokemon.id): \(tempPokemon.name)")
        return tempPokemon
    }
}
