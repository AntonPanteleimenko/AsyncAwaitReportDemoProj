//
//  ImageView.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
//

import SwiftUI

struct ImageView: View {
    let title: String
    let imageURL: URL
    
    @State private var image: UIImage?
    
    @Environment(\.imageLoader) private var imageLoader
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            Text(title)
                .font(.caption2)
                .fixedSize(horizontal: true, vertical: false)
        }
        .task {
            await loadImage()
        }
    }
}

private extension ImageView {
    func loadImage() async {
        do {
            self.image = try await imageLoader.fetch(imageURL)
        } catch {
            self.image = UIImage(named: "placeholder")
        }
    }
}
