//
//  RefreshButton.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
//

import SwiftUI

struct RefreshButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.white)
            .padding(5)
            .background(Color.green)
            .cornerRadius(8)
    }
}
