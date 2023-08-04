//
//  OMLM_Model.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/17/23.
//

import Foundation
import UIKit

struct FileFolder: Hashable, Identifiable {
    var id = UUID()
    var name: String
    var timestamp: Date
    var size: Int64
    var videoURL: URL?
    var thumbnail: UIImage?
}

struct CSVFile: Hashable, Identifiable {
    var id = UUID()
    var name: String
    var timestamp: Date
    var data: String
    
    // RAW Data in CSV
    // Video in mp4
    // Metadata in JSON
}
