//
//  OMLM_View.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/13/23.
//

import SwiftUI
import RealityKit

struct Dashboard: View {
    var body: some View {
            TabView {
                HomeView() // implemented
                    .tabItem {
                        Image(systemName: "house")
                    }
                
                CameraView() // implemented
                    .tabItem {
                        Image(systemName: "camera")
                    }
                
                ProfileView() // implemented
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                    }
            }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}
