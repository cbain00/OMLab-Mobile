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
        let fileURL = documentsURL.appendingPathComponent(fileName)
        let newFileURL = documentsURL.appendingPathComponent(newFileName)
        
        do {
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            // Update the view or perform any other necessary operations
            
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
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            // Find the specified file folder
            if let fileFolderURL = fileURLs.first(where: { $0.lastPathComponent == fileName }) {
                let filesURL = try fileManager.contentsOfDirectory(at: fileFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                // Assuming the CSV file is the first file in the folder
                if let csvFileURL = filesURL.first {
                    let content = try String(contentsOf: csvFileURL)
                    let lines = content.components(separatedBy: "\n")
                    var parsedCSV: [String: [String]] = [:]
                    
                    // Extract header line and split it into column names
                    let headerLine = lines[0]
                    let columnNames = headerLine.components(separatedBy: ", ")
                    
                    // Initialize arrays for each column name
                    for columnName in columnNames {
                        parsedCSV[columnName] = []
                    }
                    
                    // Process data lines
                    for line in lines.dropFirst() {
                        let values = line.components(separatedBy: ", ")
                        
                        // Append values to corresponding column arrays
                        for (index, columnName) in columnNames.enumerated() {
                            if index < values.count && values[index] != "" { parsedCSV[columnName]?.append(values[index]) }
                        }
                    }

                    return parsedCSV
                    
                } else {
                    print("No CSV file found in the specified folder.")
                }
            } else {
                print("Specified file folder not found.")
            }
        } catch {
            print("Error while accessing file directory: \(error.localizedDescription)")
        }
        
        return [:]
    }

    func makeDataArray(csv: [String: [String]], yvalue: String) -> [GraphData] {
        var dataArray: [GraphData] = []
        
        if let xValues = csv["Time"], let yValues = csv[yvalue] {
            let count = min(xValues.count, yValues.count)
            
            for i in 0..<count {
                if let x = Double(xValues[i]), let y = Double(yValues[i]) {
                    let graphData = GraphData(x: x, y: y)
                    dataArray.append(graphData)
                }
            }
        }
        
        return dataArray
    }
}











// Test to make graph view
/*
struct ProfitOverTime {
    var date: Int
    var profit: Double
}

struct GraphView: View {
    // Fake data for demonstration purposes
    let departmentAProfit: [ProfitOverTime] = [
        .init(date: 1, profit: 20.0),
        .init(date: 2, profit: 30.0),
        .init(date: 3, profit: 40.0),
    ]
    let departmentBProfit: [ProfitOverTime] = [
        .init(date: 1, profit: 50.0),
        .init(date: 2, profit: 45.0),
        .init(date: 3, profit: 40.0),
    ]

    var body: some View {
        Chart {
            ForEach(departmentAProfit, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Profit A", item.profit),
                    series: .value("Company", "A")
                )
                .foregroundStyle(.blue)
            }
            ForEach(departmentBProfit, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Profit B", item.profit),
                    series: .value("Company", "B")
                )
                .foregroundStyle(.green)
            }
            RuleMark(
                y: .value("Threshold", 400)
            )
            .foregroundStyle(.red)
        }
    }
}
*/
