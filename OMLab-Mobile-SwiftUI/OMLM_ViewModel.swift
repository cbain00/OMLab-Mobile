//
//  OMLMViewModel.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/17/23.
//

import SwiftUI
import UIKit
import AVFoundation

class HomeView_ViewModel: ObservableObject {
    @Published var sortOption = 0 // default sorting option is "Newest to Oldest"
    @Published var files: [FileFolder] = []
    @Published var recentFiles: [FileFolder] = []
    let fileManager = FileManager.default
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let maxCount = 5 // max number of files to be held in "recently viewed"
    
    var sortFunction: (FileFolder, FileFolder) -> Bool {
        switch sortOption {
        case 0:
            return { $0.timestamp > $1.timestamp }
        case 1:
            return { $0.timestamp < $1.timestamp }
        case 2:
            return { $0.name < $1.name }
         case 3:
            return { $0.size < $1.size }
        case 4:
           return { $0.size > $1.size }
            
        default:
            return { $0.timestamp > $1.timestamp }
        }
    }
    
    // MARK: File Handlers and Modifiers
        
    func addRecentFile(_ file: FileFolder) {
        if recentFiles.count == maxCount {
            recentFiles.removeLast()
        }
        
        if !recentFiles.contains(where: { $0.name == file.name }) {
            recentFiles.insert(file, at: 0)
        }
    }
    
    func removeFromRecentFiles(_ file: FileFolder) {
        if let index = recentFiles.firstIndex(of: file) {
            recentFiles.remove(at: index)
        }
    }

    // Displays the contents of all text files in a specific save file's documents directory to the console
    func displayTxtFiles() {
        do {
            // Navigate to the directory containing the saved data directories
            let fileFolderURL = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            // Navigate to the directory containing the text files
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL[1], includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            // Display the contents of each text file
            for url in filesURL {
                do {
                    let fileContents = try String(contentsOf: url)
                    print("File: \(url.lastPathComponent)\n\nContents: \(fileContents)")
                    
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) as [FileAttributeKey: Any],
                        let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
                        print("File Timestamp: \(creationDate)")
                        }
                } catch {
                    print("Error reading file \(url): \(error)")
                }
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    // MARK: FileList getters, setters, deleters
    
    func setFileList() {
        self.files = makeFileList()
    }

    func makeFileList() -> [FileFolder] {
        var fileFolders = [FileFolder]()
        
        // check if file has been saved to reduce loading when navigating back to home view
        if fileHasBeenSaved() {
            do {
                let fileFolderURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                for fileFolderURL in fileFolderURLs {
                    guard !isTrashFolder(fileFolderURL) else { continue }
                    
                    let timestamp = getFileFolderCreationDate(fileFolderURL: fileFolderURL)
                    let emptyDate = Date(timeIntervalSince1970: 0)
                    let name = fileFolderURL.lastPathComponent
                    let size = getFileFolderSize(fileFolderURL: fileFolderURL)
                    let videoURL = getVideoURL(fileFolderURL: fileFolderURL)
                    let thumbnail = self.getVideoThumbnail(videoURL: videoURL)
                                                    
                    let fileFolder = FileFolder(name: name, timestamp: timestamp ?? emptyDate, size: size, videoURL: videoURL, thumbnail: thumbnail)
                    fileFolders.append(fileFolder)
                }
            } catch {
                print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            }
            
            return fileFolders
            
        } else {
            return files
        }
    }
    
    func isTrashFolder(_ fileFolderURL: URL) -> Bool {
        return fileFolderURL.lastPathComponent == ".Trash"
    }

    func getFileFolderCreationDate(fileFolderURL: URL) -> Date? {
        guard let filesURL = try? fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return nil
        }
        
        for fileURL in filesURL {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
                return creationDate
            }
        }
        
        return nil
    }

    // returns size of contents of folder in KB
    func getFileFolderSize(fileFolderURL: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let files = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: [.totalFileAllocatedSizeKey], options: .skipsHiddenFiles)
            
            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                if let fileSize = resourceValues.totalFileAllocatedSize {
                    totalSize += Int64(fileSize)
                }
            }
        } catch {
            print("Error retrieving folder size: \(error.localizedDescription)")
        }
        
        totalSize /= 1000
        return totalSize
    }
    
    func getVideoURL(fileFolderURL: URL) -> URL? {
        guard let filesURL = try? fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return nil
        }
        
        guard let mp4FileURL = filesURL.first(where: { $0.pathExtension == "mp4" }) else {
            return nil
        }
        
        return mp4FileURL
    }
    
    func getVideoThumbnail(videoURL: URL?) -> UIImage? {
        if videoURL == nil {
            return nil
        }
        
        return imageFromVideo(url: videoURL!, at: 0)
        
        // https://stackoverflow.com/questions/42520453/extract-frame-from-video-in-swift
        func imageFromVideo(url: URL, at time: TimeInterval) -> UIImage? {
            let asset = AVURLAsset(url: url)

            let assetIG = AVAssetImageGenerator(asset: asset)
            assetIG.appliesPreferredTrackTransform = true
            assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

            let cmTime = CMTime(seconds: time, preferredTimescale: 60)
            let thumbnailImageRef: CGImage
            do {
                thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
            } catch let error {
                print("Error: \(error)")
                return nil
            }

            return UIImage(cgImage: thumbnailImageRef)
        }
    }
    
    func fileHasBeenSaved() -> Bool {
        do {
            let fileFolderURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let currentDocumentsDirectoryLength = fileFolderURLs.count
            
            if currentDocumentsDirectoryLength > files.count {
                return true
            } else {
                return false
            }
        } catch {
            print("Error accessing folder: \(error.localizedDescription)")
        }
        return false
    }

    func deleteFolder(_ file: String) {
        let fileURL = documentsURL.appendingPathComponent(file)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("\(file) deleted successfully.")
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
    }
}

class Settings_ViewModel: ObservableObject {
    @Published var participantID: String = ""
    @Published var sessionName: String = ""
    @Published var allowUDPConnections: Bool = false
    @Published var allowScreenRecording: Bool = false
}
