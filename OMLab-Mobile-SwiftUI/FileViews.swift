//
//  FileViews.swift
//  OMLab-Mobile-SwiftUI
//
//  Abstract:
//  File to handle all file-click actions including the list and detail views.
//
//  Created by Christopher Bain on 4/18/23.
//

import SwiftUI
import UIKit
import Charts
import AVKit
import AVFoundation
import DomainGesture
import ZipArchive

struct FileListView: View {
    @ObservedObject var viewModel: HomeView_ViewModel

    var body: some View {
        List {
            ForEach(viewModel.files.sorted(by: viewModel.sortFunction), id: \.self) { fileFolder in
                FileRowView(file: fileFolder,
                            viewModel: viewModel,
                            destination: FileDetailView(file: fileFolder, viewModel: viewModel))
            }
        }
        .padding(.horizontal, -20)
        .onAppear {
            viewModel.setFileList()
        }
    }
}


struct FileRowView<Destination>: View where Destination: View {
    var file: FileFolder
    @ObservedObject var viewModel: HomeView_ViewModel
    @State var destination: Destination

    @State private var transitionState: TransitionState = .inactive
    @State private var highlightColor: Color = .clear
    
    // Value to mimic 50 ms wait
    let loadingSymbolWaitTime: Int = 50
    let rowViewVStackSpacing: CGFloat = 2
    let thumbnailWidth: CGFloat = 30
    let thumbnailHeight: CGFloat = 50

    var body: some View {
        let isActive = Binding<Bool>(
            get: { transitionState == .active },
            set: { isNowActive in
                if !isNowActive {
                    transitionState = .inactive
                }
            }
        )

        Button {
            guard transitionState == .inactive else { return }
            transitionState = .loading
            highlightColor = Color(UIColor.tertiarySystemBackground)

            // loading symbol appears for a minimum of specified time (simulation of loading based on passed value)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(loadingSymbolWaitTime)) {
                transitionState = .active
                highlightColor = .clear
            }
        } label: {
            HStack {
                if let thumbnail = file.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                } else {
                    // Placeholder image if no thumbnail is available
                    Color.gray
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                }

                VStack(alignment: .leading, spacing: rowViewVStackSpacing) {
                    Text(file.displayName)
                        .font(.headline)
                    Text(formatDate(file.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()

                if transitionState == .loading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(highlightColor)
        .background(
            NavigationLink(
                isActive: isActive,
                destination: { destination },
                label: { }
            )
            .opacity(transitionState == .loading ? 0 : 1)
        )
    }

    private enum TransitionState {
        case inactive
        case loading
        case active
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy HH:mm:ss"
        return dateFormatter.string(from: date)
    }

}


struct FileRowView_SearchMenu<Destination>: View where Destination: View {
    var file: FileFolder
    @ObservedObject var viewModel: HomeView_ViewModel
    @State var destination: Destination

    @State private var transitionState: TransitionState = .inactive
    @State private var highlightColor: Color = .clear
    
    let loadingSymbolWaitTime: Int = 50
    let rowViewVStackSpacing: CGFloat = 2

    var body: some View {
        let isActive = Binding<Bool>(
            get: { transitionState == .active },
            set: { isNowActive in
                if !isNowActive {
                    transitionState = .inactive
                }
            }
        )

        Button {
            guard transitionState == .inactive else { return }
            transitionState = .loading
            highlightColor = Color(UIColor.tertiarySystemBackground)

            // Mimic 50 ms wait
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(loadingSymbolWaitTime)) {
                transitionState = .active
                highlightColor = .clear
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: rowViewVStackSpacing) {
                    Text(file.displayName)
                        .font(.headline)
                    Text(formatDate(file.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()

                if transitionState == .loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(highlightColor)
        .background(
            NavigationLink(
                isActive: isActive,
                destination: { destination },
                label: { }
            )
            .opacity(transitionState == .loading ? 0 : 1)
        )
    }

    private enum TransitionState {
        case inactive
        case loading
        case active
    }

    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy HH:mm:ss"
        return dateFormatter.string(from: date)
    }

}


struct FileDetailView: View {
    var file: FileFolder
    
    @ObservedObject var viewModel: HomeView_ViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingFileInfoView = false
    @State private var isShowingVideoPlayer = false
    @State private var isShowingLog = false
    @State private var newFileName = ""
    
    let fileManager = FileManager.default
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    var body: some View {
        var fileName = file.name
        var fileNameHeader = Text(file.displayName)
        
        VStack {
            HStack {
                Spacer()
                fileNameHeader
                    .font(.title3)
                    .fontWeight(.bold)
                    .toolbar {
                        toolbarItem(fileName: fileName)
                    }
                Spacer()
            }
            .padding(.horizontal)
            
                Spacer()
            
                ScrollView {
                    VStack(spacing: DrawingConstants.graphViewVStackSpacing) {
                        GraphView(fileName: fileName, group: .eyes)
                        GraphView(fileName: fileName, group: .head)
                    }
                    .frame(maxHeight: .infinity)
                }
        }
        .onAppear {
            viewModel.addRecentFile(file)
        }
                
        .sheet(isPresented: $isShowingFileInfoView) {
            FileInfoView(file: file)
        }
        
        .sheet(isPresented: $isShowingVideoPlayer) {
            DisplayEyeTrackingRecording(fileName: fileName)
        }
        
        .sheet(isPresented: $isShowingLog) {
            DisplaySessionLog(fileName: fileName)
        }
    }
    
    struct FileInfoView: View {
        var file: FileFolder
        let infoViewVStackSpacing: CGFloat = 10
        let imageSize: CGFloat = 30
        let rowSpaceLength: CGFloat = 20
        
        var body: some View {
            VStack(spacing: infoViewVStackSpacing) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: imageSize))
                        .foregroundColor(.blue)
                        .padding()
                    
                    Spacer()
                }
                
                metadataField("Name:", value: "\(file.name)")
                metadataField("Folder Size:", value: "\(file.size) kB")
                metadataField("Date Created:", value: "\(file.timestamp)")
                metadataField("ID:", value: "\(file.id)")
                
                Spacer()
            }
        }
        
        private func metadataField(_ label: String, value: String) -> some View {
            HStack {
                Text(label)
                    .fontWeight(.bold)
                if label == "Date Created:" {
                    Text(formatDate(value))
                } else {
                    Text(value)
                }
                
                Spacer(minLength: rowSpaceLength)
            }
            .padding(.horizontal)
        }

        private func formatDate(_ dateString: String) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            if let date = dateFormatter.date(from: dateString) {
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return dateFormatter.string(from: date)
            }
            return dateString
        }
    }

    struct DisplayEyeTrackingRecording: View {
        var fileName: String
        
        var body: some View {
            let fileManager = FileManager.default
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileFolderURL = documentsURL.appendingPathComponent(fileName)
            
            do {
                let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                guard let mp4FileURL = filesURL.first(where: { $0.pathExtension == "mp4" }) else {
                    print("No mp4 file found in the specified folder.")
                    
                    return AnyView(Text("No mp4 File Found")
                        .font(.title3)
                        .foregroundColor(.gray))
                }
                
                let player = AVPlayer(url: mp4FileURL)
                player.play() // Automatically start playing
                
                return AnyView(VideoPlayer(player: player))

            } catch {
                print("Unable to access directory: \(error)")
                
                return AnyView(Text("Unable to Access Directory")
                    .font(.title3)
                    .foregroundColor(.gray))
            }
        }
    }
    
    struct DisplaySessionLog: View {
        var fileName: String
        @State private var fileContent: String = ""
        @State private var fileError: Error?

        var body: some View {
            let fileManager = FileManager.default
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileFolderURL = documentsURL.appendingPathComponent(fileName)
            
            Task {
                do {
                    let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    
                    if let eventFileURL = filesURL.first(where: { $0.lastPathComponent.contains("_events.txt") }) {
                        let content = try String(contentsOf: eventFileURL)
                        fileContent = content.isEmpty ? "Log File Empty" : content
                    } else {
                        print("No session log file found in the specified folder.")
                        fileContent = "No session log file found in folder."
                    }
                } catch {
                    fileError = error
                }
            }
            
            if let error = fileError {
                return AnyView(
                    Text("Error: \(error.localizedDescription)")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding()
                )
            } else {
                return AnyView(
                    VStack {
                        Text("Session Log")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(fileContent)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
                )
            }
        }
    }
    
    func Rename(file: FileFolder) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        let alertController = UIAlertController(title: "Rename File", message: "Enter new file name", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "New File Name"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let confirmRename = UIAlertAction(title: "Rename", style: .default) { _ in
            if let newFileName = alertController.textFields?.first?.text {
                viewModel.removeFromRecentFiles(file)
                renameFile(fileName: file.name, newFileName: newFileName)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(confirmRename)

        if let windowScene = scene as? UIWindowScene {
             windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }

    func renameFile(fileName: String, newFileName: String) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        let fileURL = documentsURL.appendingPathComponent(fileName)
        let newFileURL = documentsURL.appendingPathComponent(newFileName)

        do {
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            print("File renamed successfully.")
            print("New file location: \(newFileURL)")
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
            
            let alert = UIAlertController(title: "Error", message: "File renaming failed. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if let windowScene = scene as? UIWindowScene {
                windowScene.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func shareZip(fileName: String) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)
        
        // Check if the directory exists
        guard fileManager.fileExists(atPath: fileFolderURL.path) else {
            print("Directory does not exist.")
            return
        }
        
        // Define the output zip file URL
        let outputZipURL = documentsURL.appendingPathComponent(fileName + ".zip")
        
        // Create a zip archive
        let success = SSZipArchive.createZipFile(atPath: outputZipURL.path, withContentsOfDirectory: fileFolderURL.path)
        
        if success {
            // Share the zip file
            let activityViewController = UIActivityViewController(activityItems: [outputZipURL], applicationActivities: nil)
            if let windowScene = scene as? UIWindowScene {
                windowScene.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        } else {
            print("Failed to create the zip archive.")
        }
    }

    func shareTrackingData(fileName: String) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let txtFilesURLs = filesURL.filter { $0.pathExtension == "txt" && !$0.lastPathComponent.hasSuffix("_events.txt") }
            
            guard let txtFileURL = txtFilesURLs.first else {
                print("No txt file found in the specified folder.")
                
                let alertController = UIAlertController(title: "File Not Found", message: "Unable to find txt file for export.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                
                if let windowScene = scene as? UIWindowScene {
                         windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
                
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [txtFileURL], applicationActivities: nil)
            if let windowScene = scene as? UIWindowScene {
                     windowScene.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
        catch {
            print("Error while accessing file directory: \(error.localizedDescription)")
        }
    }
    
    func shareVideo(fileName: String) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)

        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let videoURLs = filesURL.filter { $0.pathExtension == "mp4" }

            guard let videoURL = videoURLs.first else {
                print("No video file found in the specified folder.")
                
                let alertController = UIAlertController(title: "File Not Found", message: "Unable to find video file for export.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                
                if let windowScene = scene as? UIWindowScene {
                         windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
                
                return
            }

            let activityViewController = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
            if let windowScene = scene as? UIWindowScene {
                     windowScene.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
        catch {
            print("Error while accessing file directory: \(error.localizedDescription)")
        }
    }
    
    func shareLog(fileName: String) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)

        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let eventFileURLs = filesURL.filter { $0.lastPathComponent.hasSuffix("_events.txt") }

            guard let eventFileURL = eventFileURLs.first else {
                print("No event file found in the specified folder.")
                
                let alertController = UIAlertController(title: "File Not Found", message: "Unable to find event file for export.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                
                if let windowScene = scene as? UIWindowScene {
                         windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
                
                return
            }

            let activityViewController = UIActivityViewController(activityItems: [eventFileURL], applicationActivities: nil)
            if let windowScene = scene as? UIWindowScene {
                     windowScene.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
        catch {
            print("Error while accessing file directory: \(error.localizedDescription)")
        }
    }

    func Delete(file: FileFolder) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        let alertController = UIAlertController(title: "Delete File", message: "Are you sure you want to delete this file?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let confirmDelete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            viewModel.deleteFolder(file.name)
            viewModel.removeFromRecentFiles(file)
            presentationMode.wrappedValue.dismiss()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmDelete)

        if let windowScene = scene as? UIWindowScene {
                 windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func checkForMP4(file: String) -> (exists: Bool, path: String?) {
        let fileFolderURL = documentsURL.appendingPathComponent(file)
        
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            guard let mp4FileURL = filesURL.first(where: { $0.pathExtension == "mp4" }) else {
                return (false, nil)
            }
            
            let mp4FileName = mp4FileURL.deletingPathExtension().lastPathComponent
            return (true, mp4FileName)
            
        } catch {
            print("Unable to access directory: \(error)")
            return (false, nil)
        }
    }
    
    func checkForEventFile(file: String) -> (exists: Bool, path: String?) {
        let fileFolderURL = documentsURL.appendingPathComponent(file)
        
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            if let eventFileURL = filesURL.first(where: { $0.lastPathComponent.contains("_events.txt") }) {
                let eventFileName = eventFileURL.deletingPathExtension().lastPathComponent
                return (true, eventFileName)
            } else {
                return (false, nil)
            }
        } catch {
            print("Unable to access directory: \(error)")
            return (false, nil)
        }
    }
    
    func toolbarItem(fileName: String) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Section {
                    Button(action: {
                        // play video recording
                        isShowingVideoPlayer = true
                    }) {
                        Label("Play Session Recording", systemImage: "play.circle.fill")
                    }
                    .disabled(!checkForMP4(file: fileName).exists)
                    
                    Button(action: {
                        // show file info sheet
                        isShowingLog = true
                    }) {
                        Label("View Session Log", systemImage: "list.bullet.rectangle.portrait.fill")
                    }
                    .disabled(!checkForEventFile(file: fileName).exists)
                }
                
                Section {
                    Menu("Export") {
                        Button(action: {
                            // allow user to export zip file of directory
                            shareZip(fileName: fileName)
                        }) {
                            Label("Zip", systemImage: "archivebox")
                        }
                        
                        Button(action: {
                            // allow user to share txt file data
                            shareTrackingData(fileName: fileName)
                        }) {
                            Label("Tracking Data", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                            // allow user to share video recording (if applicable)
                            shareVideo(fileName: fileName)
                        }) {
                            Label("Video", systemImage: "play.rectangle")
                        }
                        .disabled(!checkForMP4(file: fileName).exists)
                        
                        Button(action: {
                            // allow user to share txt file data (if applicable)
                            shareLog(fileName: fileName)
                        }) {
                            Label("Session Log", systemImage: "doc.text")
                        }
                        .disabled(!checkForEventFile(file: fileName).exists)
                    }
                    
                    Button(action: {
                        // Show rename view
                        Rename(file: file)
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // show file info sheet
                        isShowingFileInfoView = true
                    }) {
                        Label("Folder Info", systemImage: "info.circle")
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        // allow user to attempt to delete file
                        Delete(file: file)
                    }) {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: DrawingConstants.imageWidth, height: DrawingConstants.imageHeight, alignment: .trailing)
            }
        }
    }
}

struct GraphView: View {
    enum Group {
        case eyes
        case head
    }

    // placeholder until modified
    @State private var domain1: ClosedRange<Double> = 0.0...1.0
    @State private var domain2: ClosedRange<Double> = 0.0...1.0
    @State private var domain3: ClosedRange<Double> = 0.0...1.0

    var fileName: String
    let group: Group
    
    var body: some View {
        switch group {
        case .eyes:
            let csv = getCSVData(fileName: fileName)
            if csv.isEmpty {
                Text("No Graph Available")
                    .font(.title3)
                    .foregroundColor(.gray)
            } else {
                let rightEyeXData = makeDataArray(csv: csv, yvalue: "RightEyeX")
                let rightEyeYData = makeDataArray(csv: csv, yvalue: "RightEyeY")
                
                let xMin_X = rightEyeXData.map { $0.x }.min() ?? 0
                let xMax_X = rightEyeXData.map { $0.x }.max() ?? 0
                let yMin_X = rightEyeXData.map { $0.y }.min() ?? 0
                let yMax_X = rightEyeXData.map { $0.y }.max() ?? 0
                
                let xMin_Y = rightEyeYData.map { $0.x }.min() ?? 0
                let xMax_Y = rightEyeYData.map { $0.x }.max() ?? 0
                let yMin_Y = rightEyeYData.map { $0.y }.min() ?? 0
                let yMax_Y = rightEyeYData.map { $0.y }.max() ?? 0
                
                VStack(spacing: DrawingConstants.graphViewVStackSpacing) {
                    // hacky way to define graph scrolling method
                    Rectangle()
                        .hidden()
                        .frame(width: DrawingConstants.placeholderRectangleFrame, height: DrawingConstants.placeholderRectangleFrame)
                        .onAppear {
                            domain1 = xMin_X...xMax_X
                            domain2 = xMin_Y...xMax_Y
                        }
                    
                    VStack {
                        // x data
                        Text("Eye Horizontal (deg)")
                            .fontWeight(.bold)
                        DomainGesture($domain1) {
                            Chart {
                                ForEach(rightEyeXData, id: \.id) { item in
                                    LineMark(
                                        x: .value("Time", item.x),
                                        y: .value("RightEyeX", item.y),
                                        series: .value("Time", "RightEyeX")
                                    )
                                    .foregroundStyle(.red)
                                }
                            }
                            .frame(height: DrawingConstants.eyeGraphsFrameSize)
                            .chartXScale(domain: domain1)
                            .chartYScale(domain: [yMin_X, yMax_X])
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    
                    VStack {
                        // y data
                        Text("Eye Vertical (deg)")
                            .fontWeight(.bold)
                        
                        DomainGesture($domain2) {
                            Chart {
                                ForEach(rightEyeYData, id: \.id) { item in
                                    LineMark(
                                        x: .value("Time", item.x),
                                        y: .value("RightEyeY", item.y),
                                        series: .value("Time", "RightEyeY")
                                    )
                                    .foregroundStyle(.blue)
                                }
                            }
                            .frame(height: DrawingConstants.eyeGraphsFrameSize)
                            .chartXScale(domain: domain2)
                            .chartYScale(domain: [yMin_Y, yMax_Y])
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                }
            }

        case .head:
            let csv = getCSVData(fileName: fileName)
            let colorLegend = [
                (color: Color.red, name: "Yaw"),
                (color: Color.blue, name: "Pitch"),
                (color: Color.green, name: "Roll")
            ]
            
            if csv.isEmpty {
                Text("No Graph Available")
                    .font(.title3)
                    .foregroundColor(.gray)
            } else {
                let headXData = makeDataArray(csv: csv, yvalue: "HeadX")
                let headYData = makeDataArray(csv: csv, yvalue: "HeadY")
                let headZData = makeDataArray(csv: csv, yvalue: "HeadZ")
                
                // Find the lowest minimum and highest maximum values among the arrays
                let xMin = min(
                    headXData.map { $0.x }.min() ?? 0,
                    headYData.map { $0.x }.min() ?? 0,
                    headZData.map { $0.x }.min() ?? 0
                )
                
                let xMax = max(
                    headXData.map { $0.x }.max() ?? 0,
                    headYData.map { $0.x }.max() ?? 0,
                    headZData.map { $0.x }.max() ?? 0
                )
                
                let yMin = min(
                    headXData.map { $0.y }.min() ?? 0,
                    headYData.map { $0.y }.min() ?? 0,
                    headZData.map { $0.y }.min() ?? 0
                )
                
                let yMax = max(
                    headXData.map { $0.y }.max() ?? 0,
                    headYData.map { $0.y }.max() ?? 0,
                    headZData.map { $0.y }.max() ?? 0
                )
                
                VStack {
                    Rectangle()
                        .hidden()
                        .frame(width: DrawingConstants.placeholderRectangleFrame, height: DrawingConstants.placeholderRectangleFrame)
                        .onAppear {
                            domain3 = xMin...xMax
                        }

                    Text("Head (deg)")
                        .fontWeight(.bold)
                    
                    DomainGesture($domain3) {
                        Chart {
                            ForEach(headXData, id: \.id) { item in
                                LineMark(
                                    x: .value("Time", item.x),
                                    y: .value("HeadX", item.y),
                                    series: .value("Time", "Yaw")
                                )
                                .foregroundStyle(.red)
                            }
                            
                            ForEach(headYData, id: \.id) { item in
                                LineMark(
                                    x: .value("Time", item.x),
                                    y: .value("HeadY", item.y),
                                    series: .value("Time", "Pitch")
                                )
                                .foregroundStyle(.blue)
                            }
                            
                            ForEach(headZData, id: \.id) { item in
                                LineMark(
                                    x: .value("Time", item.x),
                                    y: .value("HeadZ", item.y),
                                    series: .value("Time", "Roll")
                                )
                                .foregroundStyle(.green)
                            }
                        }
                        .chartForegroundStyleScale(["Yaw": .red, "Pitch": .blue, "Roll": .green])
                        .chartLegend(position: .top, alignment: .center) {
                            HStack {
                                ForEach(colorLegend, id: \.name) { data in
                                    HStack {
                                        BasicChartSymbolShape.circle
                                            .foregroundColor(data.color)
                                            .frame(width: 8, height: 8)
                                        Text(data.name)
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .frame(height: DrawingConstants.headGraphsFrameSize)
                        .chartXScale(domain: domain3)
                        .chartYScale(domain: [yMin, yMax])
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                }
            }
        }
    }
    
    struct GraphData {
        var id = UUID()
        var x: Double
        var y: Double
    }
    
    func getCSVData(fileName: String) -> [String: [String]] {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to access documents directory.")
            return [:]
        }
        
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)
        do {
            // .contentsOfDirectory acts as a "double-click" on a folder
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let csvFilesURLs = filesURL.filter { $0.pathExtension == "txt" }
            
            guard let csvFileURL = csvFilesURLs.first else {
                print("No txt file found in the specified folder.")
                return [:]
            }

            let content = try String(contentsOf: csvFileURL)
            let lines = content.components(separatedBy: "\n")
            
            guard !lines.isEmpty else {
                print("CSV file is empty.")
                return [:]
            }
            
            let headerLine = lines[0]
            let columnNames = headerLine.components(separatedBy: ", ")
            
            guard let firstTimestampIndex = lines.dropFirst().first?.components(separatedBy: ", ").first,
                  let firstTimeValue = Double(firstTimestampIndex) else {
                print("Could not extract the first timestamp value.")
                return [:]
            }
            
            var parsedCSV: [String: [String]] = [:]
            for columnName in columnNames {
                parsedCSV[columnName] = []
            }
            
            for line in lines.dropFirst() {
                let values = line.components(separatedBy: ", ")
                
                // take in a max of first 60 seconds of data
                if let xValue = Double(values.first ?? "0"), xValue - firstTimeValue <= 60.0 {
                    for (index, columnName) in columnNames.enumerated() {
                        if index < values.count && !values[index].isEmpty {
                            parsedCSV[columnName]?.append(values[index])
                        }
                    }
                } else {
                    break
                }
            }
            
            return parsedCSV
        } catch {
            print("Error while accessing file directory: \(error.localizedDescription)")
            return [:]
        }
    }

    func makeDataArray(csv: [String: [String]], yvalue: String) -> [GraphData] {
        guard let xValues = csv["Time"], let yValues = csv[yvalue] else {
            return []
        }
        
        let count = min(xValues.count, yValues.count)
        
        var dataArray: [GraphData] = []
        if let firstTimestamp = Double(xValues.first ?? "0") {
            dataArray = (0..<count).compactMap { i in
                guard let x = Double(xValues[i]), let y = Double(yValues[i]) else {
                    return nil
                }
                let xInSeconds = x - firstTimestamp
                return GraphData(x: xInSeconds, y: y)
            }
        }
        
        return dataArray
    }
}

private struct DrawingConstants {
    static let imageWidth: CGFloat = 25
    static let imageHeight: CGFloat = 15
    static let graphViewVStackSpacing: CGFloat = 20
    static let placeholderRectangleFrame: CGFloat = 0.0001
    static let eyeGraphsFrameSize: CGFloat = 150
    static let headGraphsFrameSize: CGFloat = 250
}


/// DO NOT DELETE!!!
// file list w/o loading symbol when clicked
//                NavigationLink(
//                    destination: FileDetailView(file: fileFolder, viewModel: viewModel),
//                    label: {
//                        FileRowView(file: fileFolder)
//                            .listRowInsets(.init(top: 10,
//                                                 leading: 0,
//                                                 bottom: 10,
//                                                 trailing: 10))
//                    }
//                )
// file list w/ loading symbol when clicked (breaks search view when active...)

//struct FileRowView: View {
//    var file: FileFolder
//
//    var body: some View {
//        HStack(spacing: 6) {
//            if let thumbnail = file.thumbnail {
//                Image(uiImage: thumbnail)
//                    .resizable() // Allow the image to be resized
//                    .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
//                    .frame(width: 30, height: 50) // Set the desired size for the thumbnail
//            } else {
//                // Placeholder image if no thumbnail is available
//                Color.gray
//                    .frame(width: 30, height: 50)
//            }
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text(file.name)
//                    .font(.headline)
//                Text(formatDate(file.timestamp))
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//        }
//    }
//
//    private func formatDate(_ date: Date) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MM/dd/yy HH:mm:ss"
//        return dateFormatter.string(from: date)
//    }
//}


// display graphs of data based on passed y-axis param
    
    /* old graph view versions
    // right eye positions
    GraphView(fileName: fileName, yvalue: "RightEyeX", color: .red)
    GraphView(fileName: fileName, yvalue: "RightEyeY", color: .green)
    GraphView(fileName: fileName, yvalue: "RightEyeZ", color: .blue)

    // head positions
    GraphView(fileName: fileName, yvalue: "HeadX", color: .red)
    GraphView(fileName: fileName, yvalue: "HeadY", color: .green)
    GraphView(fileName: fileName, yvalue: "HeadZ", color: .blue)
    */


//    struct RenameFileView: View {
//        var fileName: String
//        @Binding var newFileName: String
//        var onRename: (String) -> Void
//
//        var body: some View {
//            VStack {
//                Text("Rename File")
//                    .font(.title)
//                    .fontWeight(.bold)
//
//                TextField("New File Name", text: $newFileName) { isEditing in
//                    if !isEditing {
//                        onRename(newFileName)
//                    }
//                }
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//                Spacer()
//            }
//            .padding()
//        }
//    }

