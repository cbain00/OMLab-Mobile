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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                }
            
            CameraView()
                // best option without hiding tabs
                .edgesIgnoringSafeArea(.top)
                .tabItem {
                    Image(systemName: "camera")
                }
                .tag(1)
            
            SettingsView()
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
