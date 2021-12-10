//
//  ContentViewModel.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
//

import SwiftUI

class Testerrino {
    let value = "someValue"
    
    func printVal() {
        print(value)
    }
}

class ContentViewModel: ObservableObject {
    
    private enum Constants {
        static let api_key = "24496240-98572d5be02785c421123d65d"
        static let baseURL = "https://pixabay.com/api/?key="
    }
    
    @Published var isFetching = false
    @Published var currentImages = [CurrrentImage]()
    @Published var errorMessage = ""
    @Environment(\.imageLoader) private var imageLoader
    var page: Int = 1
    
    @MainActor
    func fetchData() async throws {
        let query = "&q&image_type=photo&category=computer&orientation=vertical&lang=en&safesearch=true&editors_choice=true&page=\(page)"
        let urlString = Constants.baseURL + Constants.api_key + query
        guard let url = URL(string: urlString) else { return }
        do {
            isFetching = true
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let resp = response as? HTTPURLResponse, resp.statusCode >= 300 {
                self.errorMessage = "Failed to hit endpoint with bad status code"
            }
            
            currentImages = parseJSON(withData: data)
            
            if currentImages.isEmpty {
                page = 1
                try await fetchData()
            } else {
                page += 1
            }
            isFetching = false
        } catch {
            isFetching = false
            print("Failed to reach endpoing: \(error)")
        }
    }
    
    @MainActor
    func fetchCategoricalData(perPage: Int, category: String) async throws -> [CurrrentImage] {
        let query = "&q&image_type=photo&category=\(category)&orientation=vertical&lang=en&safesearch=true&editors_choice=true&per_page=\(perPage)"
        let urlString = Constants.baseURL + Constants.api_key + query
        guard let url = URL(string: urlString) else { return [] }
        do {
            isFetching = true
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let resp = response as? HTTPURLResponse, resp.statusCode >= 300 {
                self.errorMessage = "Failed to hit endpoint with bad status code"
            }
            
            isFetching = false
            return parseJSON(withData: data)
        } catch {
            isFetching = false
            print("Failed to reach endpoing: \(error.localizedDescription)")
        }
        return []
    }
    
    @MainActor
    func fetchRandomData() async {
        currentImages.removeAll()
        isFetching = true
        Task {
            do {
                async let firstCategory = try fetchCategoricalData(perPage: 3, category: "nature")
                async let secondCategory = try fetchCategoricalData(perPage: 3, category: "education")
                async let thirdCategory = try fetchCategoricalData(perPage: 3, category: "buildings")
                let images = try await firstCategory + secondCategory + thirdCategory
                
                let searchKeyword: String? = "unknown"
                let filteredImages = await imageLoader.filteredImages(currentImages: images) { image in
                    guard let searchKeyword = searchKeyword else { return false }
                    return image.user == searchKeyword
                }
                
                self.currentImages = filteredImages
            } catch {
                isFetching = false
                print("Failed to reach endpoing: \(error.localizedDescription)")
            }
        }
    }
    
    func refreshImages() async {
        currentImages.removeAll()
        do {
            try await fetchData()
        } catch {
            isFetching = false
            print("Failed to reach endpoing: \(error.localizedDescription)")
        }
    }
    
    private func parseJSON(withData data: Data) -> [CurrrentImage] {
        let decoder = JSONDecoder()
        do {
            let currentImageData = try decoder.decode(Images.self, from: data)
            let images = currentImageData.hits.compactMap { CurrrentImage(currentImageData: $0) }
            return images
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return []
    }
    
    /// Increase tag count by 1
    func increaseTagCount(_ imageID: Int) async {
        let index = currentImages.firstIndex { $0.id == imageID }
        currentImages[index!].tagCount += 1
    }
    
    /// Get image based on its id
    func getImage(with imageID: Int) async -> CurrrentImage? {
        return currentImages.filter({ $0.id == imageID }).first
    }
}
