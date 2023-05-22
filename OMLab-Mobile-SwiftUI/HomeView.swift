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
                HomeMenuView()

                Divider()

                // view for sorting button
                SortByView(header: "Test Files", sortOption: $viewModel.sortOption)

                // view for list of saved user files
                FileListView()

                Spacer()
            }
        }
    }
}

struct HomeMenuView: View {
    var body: some View {
        HStack {
            Menu {
                Button(action: {}) {
                    Label("Report a problem", systemImage: "exclamationmark.triangle.fill")
                }
                
                // Add other options as desired
                
            } label: {
                Image(systemName: "ellipsis")
            }

            Text("Home")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)

            NavigationLink(destination: SearchBarView()) {
                Image(systemName: "magnifyingglass")
            }
        }
        .padding()
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
            
            NavigationLink(destination: SortingView(sortOption: sortOption)) {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
        .padding(.horizontal, 20.0)
    }
}

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

struct SearchBarView: View {
    @ObservedObject private var viewModel = HomeView_ViewModel()
    @State private var searchText = ""
    @State private var isSearching = true
    
    var body: some View {
        VStack {
            Text("Search Files")
                .font(.title3)
                .fontWeight(.medium)

            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            List {
                // Check if there are any recent files matching the search criteria
                if !viewModel.recentFiles.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                    // If so, show them in a section with a header
                    Section(header: Text("Recently Viewed")) {
                        // Iterate over the recent files that match the search criteria
                        ForEach(viewModel.recentFiles.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) })) { file in
                            NavigationLink(destination: FileDetailView(file: file, viewModel: viewModel)) {
                                Text(file.name)
                            }
                        }
                    }
                }

                // Check if there are any files matching the search criteria
                if viewModel.files.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }).isEmpty {
                    // If not, show a message indicating that no files were found
                    Text("No files found")
                } else {
                    // Otherwise, show all files that match the search criteria in a section with a header
                    Section(header: Text("All Files")) {
                        // Iterate over the files that match the search criteria
                        ForEach(viewModel.files.filter({ searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) })) { file in
                            NavigationLink(destination: FileDetailView(file: file, viewModel: viewModel)) {
                                Text(file.name)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Spacer()
            TextField("Search", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 800)
            
            Button(action: {
                text = ""
            }, label: {
                Image(systemName: "xmark.circle.fill")
            })
            .padding(.horizontal, 4)
            .opacity(text == "" ? 0 : 1)
        }
        .padding(.horizontal)
    }
}
