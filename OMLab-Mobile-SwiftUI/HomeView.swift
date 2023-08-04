//
//  File.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/17/23.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeView_ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Displays home menu navigation bar
                HomeMenuView(viewModel: viewModel)

                Divider()

                // view for sorting button
                SortByView(header: "Files", sortOption: $viewModel.sortOption)

                // view for list of saved user files
                FileListView(viewModel: viewModel)
                
                Spacer()
            }
        }
    }
}


struct HomeMenuView: View {
    @ObservedObject var viewModel: HomeView_ViewModel
    @State private var showReportView = false
    
    var body: some View {
        HStack {
            Menu {
                Button(action: {
                    showReportView = true
                }) {
                    Label("Report a problem", systemImage: "exclamationmark.triangle.fill")
                }
                
                // Add other options as desired
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 25, height: 25, alignment: .leading)
                    .font(.system(size: 20))
            }

            Text("Home")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)

            NavigationLink(destination: SearchBarView(viewModel: viewModel)) {
                Image(systemName: "magnifyingglass")
            }
        }
        .padding()
        
        .sheet(isPresented: $showReportView) {
            ReportProblem(isSheetPresented: $showReportView)
        }
    }
}

// not fully implemented, problem reporting goes nowhere
struct ReportProblem: View {
    @Binding var isSheetPresented: Bool
    
    var body: some View {
        VStack {
            Text("Report a Problem")
                .font(.title)
                .fontWeight(.bold)
            
            // Add content for reporting a problem
            
            Button(action: {
                // Handle report submission
                
                // Dismiss sheet
                isSheetPresented = false
            }) {
                Text("Submit")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationBarTitle(Text("Report a Problem"))
        .onDisappear {
            // Perform any necessary cleanup or post-submission actions here
        }
    }
}


struct SortByView: View {
    let header: String
    let sortOption: Binding<Int>
    
    var body: some View {
        HStack {
            Text(header)
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Menu {
                Button(action: { sortOption.wrappedValue = 0 }) {
                    Label("Newest to Oldest", systemImage: sortOption.wrappedValue == 0 ? "checkmark" : String())
                }
                Button(action: { sortOption.wrappedValue = 1 }) {
                    Label("Oldest to Newest", systemImage: sortOption.wrappedValue == 1 ? "checkmark" : String())
                }
                Button(action: { sortOption.wrappedValue = 2 }) {
                    Label("Alphabetical Order", systemImage: sortOption.wrappedValue == 2 ? "checkmark" : String())
                }
                Button(action: { sortOption.wrappedValue = 3 }) {
                    Label("Smallest to Largest", systemImage: sortOption.wrappedValue == 3 ? "checkmark" : String())
                }
                Button(action: { sortOption.wrappedValue = 4 }) {
                    Label("Largest to Smallest", systemImage: sortOption.wrappedValue == 4 ? "checkmark" : String())
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
        .padding(.horizontal, 20.0)
    }
}


struct SearchBarView: View {
    @ObservedObject var viewModel: HomeView_ViewModel
    @State private var searchText: String = ""
    @State private var isSearching = true
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, placeholder: "Search Files...")
            List {
                if !viewModel.recentFiles.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                    Section(header: Text("Recently Viewed")) {
                        ForEach(viewModel.recentFiles.filter {
                            searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased())
                        }, id: \.self) { file in
                            NavigationLink(destination: FileDetailView(file: file, viewModel: viewModel)) {
                                Text(file.name)
                            }
                        }
                    }
                }
                
                if viewModel.files.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                    Text("No files found")
                        .foregroundColor(.gray)
                } else {
                    Section(header: Text("All Files")) {
                        ForEach(viewModel.files.filter {
                            searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased())
                        }.sorted(by: viewModel.sortFunction), id: \.self) { file in
                            NavigationLink(destination: FileDetailView(file: file, viewModel: viewModel)) {
                                Text(file.name)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Search Files"))
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        init(text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}


//    var body: some View {
//        VStack {
//            Text("Search Files")
//                .font(.title3)
//                .fontWeight(.medium)
//
//            SearchBar(text: $searchText)
//                .padding(.horizontal)
//
//            List {
//                // Check if there are any recent files matching the search criteria
//                if !viewModel.recentFiles.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }).isEmpty {
//                    // If so, show them in a section with a header
//                    Section(header: Text("Recently Viewed")) {
//                        // Iterate over the recent files that match the search criteria
//                        ForEach(
//                            viewModel.recentFiles
//                                .filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }))
//                        { file in
//                            NavigationLink(destination: FileDetailView(file: file, viewModel: viewModel)) {
//                                Text(file.name)
//                            }
//                        }
//                    }
//                }
//
//                // Check if there are any files matching the search criteria
//                if viewModel.files.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }).isEmpty {
//                    // If not, show a message indicating that no files were found
//                    Text("No files found")
//                } else {
//                    // Otherwise, show all files that match the search criteria in a section with a header
//                    Section(header: Text("All Files")) {
//                        // Iterate over the files that match the search criteria
//                        ForEach(
//                            viewModel.files
//                                .filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) })
//                                .sorted(by: viewModel.sortFunction))
//                        { file in
//                            NavigationLink(destination: FileDetailView(file: file, viewModel: viewModel)) {
//                                Text(file.name)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }

//struct SearchBar: View {
//    @Binding var text: String
//
//    var body: some View {
//        HStack {
//            Spacer()
//            TextField("Search", text: $text)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .frame(maxWidth: 800)
//
//            Button(action: {
//                text = ""
//            }, label: {
//                Image(systemName: "xmark.circle.fill")
//            })
//            .padding(.horizontal, 4)
//            .opacity(text == "" ? 0 : 1)
//        }
//        .padding(.horizontal)
//    }
//}

/*
struct SortingView: View {
    @Binding var sortOption: Int

    var body: some View {
        List {
            SortingButton(title: "Newest to Oldest", isSelected: sortOption == 0) {
                sortOption = 0
            }
            
            SortingButton(title: "Oldest to Newest", isSelected: sortOption == 1) {
                sortOption = 1
            }
            
            SortingButton(title: "Alphabetical Order", isSelected: sortOption == 2) {
                sortOption = 2
            }
            
             SortingButton(title: "File Size (Smallest to Largest)", isSelected: sortOption == 3) {
                 sortOption = 3
             }
            
            SortingButton(title: "File Size (Largest to Smallest)", isSelected: sortOption == 4) {
                sortOption = 4
            }

        }
    }
}


struct SortingButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
*/
