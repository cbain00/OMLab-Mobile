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

struct FileListView: View {
    @ObservedObject var viewModel: HomeView_ViewModel

    var body: some View {
        List {
            ForEach(viewModel.files.sorted(by: viewModel.sortFunction), id: \.self) { fileFolder in
                NavigationLink(
                    destination: FileDetailView(file: fileFolder, viewModel: viewModel),
                    label: {
                        FileRowView(file: fileFolder)
                            .listRowInsets(.init(top: 10,
                                                 leading: 0,
                                                 bottom: 10,
                                                 trailing: 10))
                    })
            }
        }
        .onAppear {
            viewModel.setFileList()
        }
    }
}


struct FileRowView: View {
    var file: FileFolder
    
    var body: some View {
        HStack(spacing: 6) {
            if let thumbnail = file.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable() // Allow the image to be resized
                    .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
                    .frame(width: 30, height: 50) // Set the desired size for the thumbnail
            } else {
                // Placeholder image if no thumbnail is available
                Color.gray
                    .frame(width: 30, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.headline)
                Text(formatDate(file.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
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
    @State private var showRenameView = false
    @State private var showFileInfoView = false
    @State private var isShowingVideoPlayer = false
    @State private var isShowingLog = false
    @State private var newFileName = ""
    
    init(file: FileFolder, viewModel: HomeView_ViewModel) {
        self.file = file
        self.viewModel = viewModel
        print("Initializing Detail View for \(file.name)")
    }

    var body: some View {
        let fileName = file.name
        
        VStack {
            HStack {
                Spacer()
                Text(fileName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .toolbar {
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
                                        Button(action: {}) {
                                            Label("Export Zip", systemImage: "archivebox")
                                        }
                                        
                                        Button(action: {
                                            // allow user to share txt file data
                                            shareFile(fileName: fileName)
                                        }) {
                                            Label("Export Tracking Data", systemImage: "doc.text")
                                        }
                                        
                                        Button(action: {}) {
                                            Label("Export Video", systemImage: "play.rectangle")
                                        }
                                        
                                        Button(action: {}) {
                                            Label("Export Session Log", systemImage: "doc.text")
                                        }
                                    }
                                    
                                    Button(action: {
                                        // Show rename view
                                        showRenameView = true
                                        newFileName = fileName
                                    }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    
                                    Button(action: {
                                        // show file info sheet
                                        showFileInfoView = true
                                    }) {
                                        Label("Folder Info", systemImage: "info.circle")
                                    }
                                }

                                Section {
                                    Button(role: .destructive, action: {
                                        // allow user to attempt to delete file
                                        Delete(fileName: fileName, file: file)
                                    }) {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                                
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .frame(width: 25, height: 15, alignment: .trailing)
                            }
                        }
                    }
                Spacer()
            }
            .padding(.horizontal)
            
                Spacer()
            
                ScrollView {
                    VStack(spacing: 20) {
                        GraphView(fileName: fileName, group: .eyes)
                        GraphView(fileName: fileName, group: .head)
                    }
                    .frame(maxHeight: .infinity)
                }
        }
        .onAppear {
            viewModel.addRecentFile(file)
        }
        
        .sheet(isPresented: $showRenameView) {
            RenameFileView(fileName: fileName, newFileName: $newFileName) { newName in
                renameFile(fileName: fileName, newFileName: newName)
                viewModel.removeFromRecentFiles(file)
                showRenameView = false
            }
        }

        .sheet(isPresented: $showFileInfoView) {
            FileInfoView(file: file)
        }
        
        .sheet(isPresented: $isShowingVideoPlayer) {
            DisplayEyeTrackingRecording(fileName: fileName)
        }
        
        .sheet(isPresented: $isShowingLog) {
            DisplaySessionLog(fileName: fileName)
        }
    }
    
    struct RenameFileView: View {
        var fileName: String
        @Binding var newFileName: String
        var onRename: (String) -> Void
        
        var body: some View {
            VStack {
                Text("Rename File")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("New File Name", text: $newFileName) { isEditing in
                    if !isEditing {
                        onRename(newFileName)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
    
    struct FileInfoView: View {
        var file: FileFolder
        let imageSize: CGFloat = 30
        let rowSpaceLength: CGFloat = 20
        
        var body: some View {
            VStack {
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


    func renameFile(fileName: String, newFileName: String) {
        let fileManager = FileManager.default
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        let newFileURL = documentsURL.appendingPathComponent(newFileName)
        
        do {
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            print("File renamed successfully.")
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
        }
    }
    
    func shareFile(fileName: String) {
        enum FileType {
            case zip
            case eyeData
            case video
            case log
        }
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let csvFilesURLs = filesURL.filter { $0.pathExtension == "txt" }
            
            guard let csvFileURL = csvFilesURLs.first else {
                print("No CSV file found in the specified folder.")
                
                let alertController = UIAlertController(title: "File Not Found", message: "Unable to find CSV file for export.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                
                if let windowScene = scene as? UIWindowScene {
                         windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
                
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [csvFileURL], applicationActivities: nil)
            if let windowScene = scene as? UIWindowScene {
                     windowScene.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
        catch {
            print("Error while accessing file directory: \(error.localizedDescription)")
        }
    }
    
    func Delete(fileName: String, file: FileFolder) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        let alertController = UIAlertController(title: "Delete File", message: "Are you sure you want to delete this file?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let confirmDelete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            viewModel.deleteFolder(fileName)
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
        let fileManager = FileManager.default
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileFolderURL = documentsURL.appendingPathComponent(file)
        
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            guard let mp4FileURL = filesURL.first(where: { $0.pathExtension == "mp4" }) else {
                //print("No mp4 file found in folder: \(fileFolderURL.lastPathComponent).")
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
        let fileManager = FileManager.default
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileFolderURL = documentsURL.appendingPathComponent(file)
        
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            if let eventFileURL = filesURL.first(where: { $0.lastPathComponent.contains("_events.txt") }) {
                let eventFileName = eventFileURL.deletingPathExtension().lastPathComponent
                return (true, eventFileName)
            } else {
                //print("No event file file found in folder: \(fileFolderURL.lastPathComponent).")
                return (false, nil)
            }
        } catch {
            print("Unable to access directory: \(error)")
            return (false, nil)
        }
    }

}


struct GraphView: View {
    enum Group {
        case eyes
        case head
    }

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
                
                VStack(spacing: 20) {
                    VStack {
                        // x data
                        Text("Eye Horizontal (deg)")
                            .fontWeight(.bold)
                        
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
                        .chartXScale(domain: [xMin_X, xMax_X])
                        .chartYScale(domain: [yMin_X, yMax_X])
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                    
                    VStack {
                        // y data
                        Text("Eye Vertical (deg)")
                            .fontWeight(.bold)
                        
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
                        .chartXScale(domain: [xMin_Y, xMax_Y])
                        .chartYScale(domain: [yMin_Y, yMax_Y])
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                }
            }

        case .head:
            let csv = getCSVData(fileName: fileName)
            let headData = [
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
                    Text("Head (deg)")
                        .fontWeight(.bold)
                    
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
                            ForEach(headData, id: \.name) { data in
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
                    .chartXScale(domain: [xMin, xMax])
                    .chartYScale(domain: [yMin, yMax])
                    .chartYAxis {
                        AxisMarks(position: .leading)
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
    
    // .contentsOfDirectory acts as a "double-click" on a folder
    func getCSVData(fileName: String) -> [String: [String]] {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to access documents directory.")
            return [:]
        }
        
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)
        do {
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
            
            var parsedCSV: [String: [String]] = [:]
            for columnName in columnNames {
                parsedCSV[columnName] = []
            }
            
            for line in lines.dropFirst() {
                let values = line.components(separatedBy: ", ")
                
                for (index, columnName) in columnNames.enumerated() {
                    if index < values.count && !values[index].isEmpty {
                        parsedCSV[columnName]?.append(values[index])
                    }
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
        
        for i in 0..<count {
            if let x = Double(xValues[i]), let y = Double(yValues[i]) {
                let graphData = GraphData(x: x, y: y)
                dataArray.append(graphData)
            }
        }
        
        return dataArray
    }
}

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

