//
//  SettingsView.swift
//  OMLab-Mobile-SwiftUI
//
//  Created by Christopher Bain on 4/19/23.
//

import SwiftUI

struct SettingsView: View {
    let settings: [(label: String, items: [Setting])] = [
        ("General", [
            Setting(name: "Notifications", icon: "bell", action: { /* Handle notifications */ }),
            Setting(name: "UDP Connection", icon: "wifi", action: { /* Toggle UDP connection */ })
        ]),
        
        ("Security", [
            Setting(name: "Privacy Center", icon: "lock", action: { /* Show privacy center */ }),
            Setting(name: "Two-Factor Authentication", icon: "key", action: { /* Enable two-factor authentication */ })
        ]),
        
        ("Account", [
            Setting(name: "Profile", icon: "person", action: { /* Edit profile */ })
        ])
    ]
    
    var body: some View {
        List {
            ForEach(settings, id: \.label) { section in
                Section(header: Text(section.label)) {
                    ForEach(section.items) { setting in
                        HStack {
                            Image(systemName: setting.icon)
                            Text(setting.name)
                            Spacer()
                            Button(action: setting.action) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle(Text("Settings"))
    }
}

struct Setting: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let action: () -> Void
}

