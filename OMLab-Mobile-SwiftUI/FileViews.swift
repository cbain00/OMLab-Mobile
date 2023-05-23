//
//  FileViews.swift
//  OMLab-Mobile-SwiftUI
//
//  Created by Christopher Bain on 4/18/23.
//

import SwiftUI
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

// Goal: After user clicks on file, data should be processed and multiple graphs should be displayed showing graphs of the tracking data (eye movements, euler angles, etc.)
struct FileDetailView: View {
    var file: FileFolder
    @ObservedObject var viewModel: HomeView_ViewModel
    @State private var isAlertPresented = false
    @State private var newFileName = ""
    
    var body: some View {
        let fileName = file.name
        
        VStack {
            HStack {
                Spacer()
                
                Text(fileName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Menu {
                    Button(action: { isAlertPresented = true }) {
                        Label("Rename File", systemImage: "pencil")
                    }
                    
                    Button(action: {}) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button(action: {}) {
                        Label("File Info", systemImage: "info.circle")
                    }
                    
                    Button(action: {}) {
                        Label("Delete File", systemImage: "trash.fill")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            .padding(.horizontal)
             
            // display graphs of data based on passed file
            Spacer()
            
            GraphView(fileName: fileName)
            
            Spacer()
                
        }
        .onAppear {
            viewModel.addRecentFile(file)
            //print(viewModel.recentFiles)
        }
        .alert(isPresented: $isAlertPresented) {
            Alert(
                title: Text("Rename File"),
                message: Text("Enter the new file name"),
                primaryButton: .default(Text("Rename"), action: {
                    renameFile(fileName: fileName, newFileName: newFileName)
                }),
                secondaryButton: .cancel()
            )
        }
    }
    
    func renameFile(fileName: String, newFileName: String) {
        let fileManager = FileManager.default
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var fileURL = documentsURL.appendingPathComponent(fileName)
        let newFileURL = documentsURL.appendingPathComponent(newFileName)
        
        do {
            var rv = URLResourceValues()
            rv.name = newFileName
            try fileURL.setResourceValues(rv)
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
        }
    }
}


struct GraphView: View {
    var fileName: String
    
    var body: some View {
        let csv = getCSVData(fileName: fileName)
        if !csv.isEmpty {
            // currently using right eye tracking data, in future this will either have multiple views or the user can pick what will be on y-axis
            let eyeData = makeDataArray(csv: csv, yvalue: "RightEyeX")
            let xMin = eyeData.map { $0.x }.min() ?? 0; let xMax = eyeData.map { $0.x }.max() ?? 0
            let yMin = eyeData.map { $0.y }.min() ?? 0; let yMax = eyeData.map { $0.y }.max() ?? 0
            
            Chart {
                ForEach(eyeData, id: \.id) { item in
                    LineMark(
                        x: .value("Time", item.x),
                        y: .value("Position", item.y),
                        series: .value("Right", "Eye")
                    )
                    .foregroundStyle(.green)
                }
            }
            .chartXScale(domain: [xMin, xMax])
            .chartYScale(domain: [yMin, yMax])
            
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
