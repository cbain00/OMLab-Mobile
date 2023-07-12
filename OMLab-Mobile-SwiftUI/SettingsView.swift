//
//  SettingsView.swift
//  OMLab-Mobile-SwiftUI
//
//  Created by Christopher Bain on 4/19/23.
//

import SwiftUI

struct SettingsView: View {
    let settings: [(label: String, items: [Setting<Text>])] = [
        ("General", [
            Setting(name: "Notifications", icon: "bell", action: {
                NavigationLink("Notifications", destination: Text("Notifications View"))
            }),
            Setting(name: "UDP Connection", icon: "wifi", action: {
                NavigationLink("UDP Connection", destination: Text("UDP Connection View"))
            })
        ]),
        ("Security", [
            Setting(name: "Privacy Center", icon: "lock", action: {
                NavigationLink("Privacy Center", destination: Text("Privacy Center View"))
            }),
            Setting(name: "Two-Factor Authentication", icon: "key", action: {
                NavigationLink("Two-Factor Authentication", destination: Text("Two-Factor Auth View"))
            })
        ]),
        ("Account", [
            Setting(name: "Profile", icon: "person", action: {
                NavigationLink("Profile", destination: Text("Profile View"))
            })
        ])
    ]
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()

            List {
                ForEach(settings, id: \.label) { section in
                    Section(header: Text(section.label)) {
                        ForEach(section.items) { setting in
                            HStack {
                                Image(systemName: setting.icon)
                                Text(setting.name)
                                Spacer()
                                setting.action()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct Setting<Destination: View>: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let action: () -> NavigationLink<Text, Destination>
}

