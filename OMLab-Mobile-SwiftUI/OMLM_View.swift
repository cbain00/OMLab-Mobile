//
//  OMLM_View.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/13/23.
//

import SwiftUI

struct Dashboard: View {
    // Set the initial selected tab to 1 (index of CameraView)
    @State private var selectedTab = 1
    @StateObject var settings_ViewModel = Settings_ViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                }
            
            CameraView(viewModel: settings_ViewModel)
                .edgesIgnoringSafeArea(.top)
                .tabItem {
                    Image(systemName: "camera")
                }
                .tag(1)
            
            SettingsView(viewModel: settings_ViewModel)
                .tabItem {
                    Image(systemName: "gear")
                }
        }
        .onAppear {
            // Set the selected tab to index of CameraView when the view appears
            selectedTab = 1
        }
    }
}
