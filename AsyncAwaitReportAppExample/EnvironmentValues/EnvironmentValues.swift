//
//  EnvironmentValues.swift
//  AsyncAwaitReportAppExample
//
//  Created by user on 24.11.2021.
//

import SwiftUI

struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue = ImageLoader()
}

extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self ] = newValue}
    }
}
