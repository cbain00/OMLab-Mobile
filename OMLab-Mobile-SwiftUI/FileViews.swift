//
//  FileViews.swift
//  OMLab-Mobile-SwiftUI
//
// Abstract:
// File to handle all file actions.
//
//  Created by Christopher Bain on 4/18/23.
//

import SwiftUI
import UIKit
import Charts

struct FileListView: View {
    @ObservedObject private var viewModel = HomeView_ViewModel()

    var body: some View {
        List {
            ForEach(viewModel.files.sorted(by: viewModel.sortFunction), id: \.self) { fileFolder in
                NavigationLink(destination: FileDetailView(file: fileFolder, viewModel: viewModel)) {
                    Text(fileFolder.name)
                }
            }
        }
        .onAppear {
            viewModel.setFileList()
        }
    }
}


struct FileDetailView: View {
    var file: FileFolder
    @ObservedObject var viewModel: HomeView_ViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showRenameView = false
    @State private var showFileInfoView = false
    @State private var newFileName = ""
    
    var body: some View {
        let fileName = file.name
        
        VStack {
            HStack {
                Spacer()
                
                Text(fileName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        // Show rename view
                        showRenameView = true
                        newFileName = fileName
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // allow user to share file
                        shareFile(fileName: fileName)
                    }) {
                        Label("Export File", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // show file info sheet
                        showFileInfoView = true
                    }) {
                        Label("File Info", systemImage: "info.circle")
                    }
                    
                    Button(action: {
                        // allow user to attempt to delete file
                        Delete(file: fileName)
                    }) {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 25, height: 15, alignment: .trailing)
                }
            }
            .padding(.horizontal)
            
<<<<<<< HEAD
            GraphView(fileName: fileName, yvalue: "RightEyeX")

            Spacer()

            GraphView(fileName: fileName, yvalue: "RightEyeY")

            Spacer()

            GraphView(fileName: fileName, yvalue: "RightEyeZ")
=======
            // display graphs of data based on passed y-axis param
            ScrollView {
                // right eye positions
                GraphView(fileName: fileName, yvalue: "RightEyeX", color: .red)
                GraphView(fileName: fileName, yvalue: "RightEyeY", color: .green)
                GraphView(fileName: fileName, yvalue: "RightEyeZ", color: .blue)

                // head positions
                GraphView(fileName: fileName, yvalue: "HeadX", color: .red)
                GraphView(fileName: fileName, yvalue: "HeadY", color: .blue)
                GraphView(fileName: fileName, yvalue: "HeadZ", color: .green)
            }
>>>>>>> 6c400ff (making UI better)
        }
        .onAppear {
            viewModel.addRecentFile(file)
        }
<<<<<<< HEAD
=======
        
        .sheet(isPresented: $showRenameView) {
            RenameFileView(fileName: fileName, newFileName: $newFileName) { newName in
                renameFile(fileName: fileName, newFileName: newName)
                showRenameView = false
            }
        }

        .sheet(isPresented: $showFileInfoView) {
            FileInfoView(file: file)
        }
>>>>>>> 6c400ff (making UI better)
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
                
                metadataField("Name:", value: "\(file.name).txt")
                metadataField("Size:", value: "\(file.size) kB")
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
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to access documents directory.")
            return
        }
        
        let fileFolderURL = documentsURL.appendingPathComponent(fileName)
        do {
            let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            guard let csvFileURL = filesURL.first else {
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
    
    func Delete(file: String) {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        let alertController = UIAlertController(title: "Delete File", message: "Are you sure you want to delete this file?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmDelete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            // Perform file deletion here
            viewModel.deleteFile(file)
            presentationMode.wrappedValue.dismiss()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmDelete)

        if let windowScene = scene as? UIWindowScene {
                 windowScene.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
}


struct GraphView: View {
    var fileName: String
    let yvalue: String
<<<<<<< HEAD
=======
    let color: Color
>>>>>>> 6c400ff (making UI better)
    
    var body: some View {
        let csv = getCSVData(fileName: fileName)
        if !csv.isEmpty {
            // currently using right eye tracking data, in future this will either have multiple views or the user can pick what will be on y-axis
            let eyeData = makeDataArray(csv: csv, yvalue: yvalue)
            let xMin = eyeData.map { $0.x }.min() ?? 0; let xMax = eyeData.map { $0.x }.max() ?? 0
            let yMin = eyeData.map { $0.y }.min() ?? 0; let yMax = eyeData.map { $0.y }.max() ?? 0
            
            VStack {
                Text("\(yvalue)")
                    .fontWeight(.bold)
                
                Chart {
                    ForEach(eyeData, id: \.id) { item in
                        LineMark(
                            x: .value("Time", item.x),
                            y: .value("Position", item.y),
                            series: .value("Time", "Position")
                        )
                        .foregroundStyle(color)
                    }
                }
                //.chartAxesLabels(xLabel: Text("X Axis"), yLabel: Text("Y Axis"))
                .chartXScale(domain: [xMin, xMax])
                .chartYScale(domain: [yMin, yMax])
            }
            

            
        } else {
            Text("No Graph Available")
                .font(.title3)
                .foregroundColor(.gray)
        }
    }
    
    struct GraphData {
        var id = UUID()
        var x: Double
        var y: Double
    }
    
    // https://medium.com/@deadbeef404/reading-a-csv-in-swift-7be7a20220c6
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
            
            guard let csvFileURL = filesURL.first else {
                print("No CSV file found in the specified folder.")
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
