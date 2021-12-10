//
//  ImagesLazyVGridView.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
//

import SwiftUI

struct ImagesLazyVGridView: View {
    
    let images: [CurrrentImage]
    let height: CGFloat = 180
    
    @ObservedObject var viewModel: ContentViewModel
    
    var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(images) { image in
                if let url = URL(string: image.imageURL) {
                    ImageView(title: image.user, imageURL: url)
                        .frame(height: height)
                        .onTapGesture {
                            performTasks(imageID: image.id)
                        }
                }
            }
        }
        .padding()
    }
}

extension ImagesLazyVGridView {
    @MainActor
    func decreaseTagCount(_ imageID: Int) async {
        let index = viewModel.currentImages.firstIndex { $0.id == imageID }
        viewModel.currentImages[index!].tagCount -= 1
    }
    
    func performTasks(imageID: Int) {
        
        Task {
            guard let image = await viewModel.getImage(with: imageID) else { return }
            
            // Create a task group
            await withTaskGroup(of: Void.self, body: { taskGroup in
                
                // Create 3000 child tasks to increase tag count
                for _ in 0..<3000 {
                    taskGroup.addTask {
                        await self.viewModel.increaseTagCount(imageID)
                    }
                }
                
                // Create 1000 child tasks to decrease tag count
                for _ in 0..<1000 {
                    taskGroup.addTask {
                        await self.decreaseTagCount(imageID)
                    }
                }
            })
            print("👍🏻 Fetch count for image from \(String(describing: image.user)): \(String(describing: image.tagCount))")
        }
    }
}
