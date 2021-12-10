//
//  CurrrentImage.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
///Users/user/Documents/AsyncAwaitReportAppExample/AsyncAwaitReportAppExample/ViewModel/ContentViewModel.swift

struct CurrrentImage: Identifiable, Equatable, Sendable {
    let id: Int
    let imageURL: String
    let tags: String
    let user: String
    
    var tagCount = 0
    
    init?(currentImageData: Hit) {
        self.id = currentImageData.id
        self.imageURL = currentImageData.largeImageURL
        self.tags = currentImageData.tags
        self.user = currentImageData.user
    }
    
    static func == (lhs: CurrrentImage, rhs: CurrrentImage) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
