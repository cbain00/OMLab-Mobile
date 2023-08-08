//
//  PreviewProvider.swift
//  OMLab-Mobile-SwiftUI
//
//  Created by Christopher Bain on 8/3/23.
//

import Foundation
import SwiftUI

extension PreviewProvider {
    
    static var dev: DeveloperPreview {
        return DeveloperPreview.instance
    }
}

// fake file for preview testing
class DeveloperPreview {
    static let instance = DeveloperPreview()
    private init() { }
    
    let file = FileFolder(
        name: "file_2023-08-03_135656",
        displayName: "file",
        timestamp: Date(timeIntervalSince1970: 150),
        size: 100
    )
}
