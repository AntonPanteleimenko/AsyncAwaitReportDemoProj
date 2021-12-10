//
//  ContentView.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel = ContentViewModel()
    @State var showsAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isFetching {
                    ProgressView()
                }
                ImagesLazyVGridView(images: viewModel.currentImages, viewModel: viewModel)
            }
            .navigationTitle("Images")
            .task {
                await self.performFetch()
            }
            .navigationBarItems(trailing: refreshButton)
            .navigationBarItems(leading: loadDifferentImagesButton)
        }
        .navigationViewStyle(.stack)
        .alert(isPresented: self.$showsAlert) {
            Alert(title: Text("Error while fetching images"))
        }
    }
}

private extension ContentView {
    var refreshButton: some View {
        let title: String = "Refresh!"
        let action: () -> Void = {
            Task.init {
                await viewModel.refreshImages()
            }
        }
        return Button(title, action: action)
            .buttonStyle(RefreshButton())
    }
    
    var loadDifferentImagesButton: some View {
        let title: String = "Load random!"
        let action: () -> Void = {
            Task.init {
                await viewModel.fetchRandomData()
            }
        }
        return Button(title, action: action)
            .buttonStyle(RefreshButton())
    }
    
    func performFetch() async {
        do {
            try await viewModel.fetchData()
        } catch {
            self.showsAlert.toggle()
        }
    }
}
