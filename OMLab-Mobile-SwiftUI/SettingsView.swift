//
//  SettingsView.swift
//  OMLab-Mobile-SwiftUI
//
//  Created by Christopher Bain on 4/19/23.
//

import SwiftUI
import Foundation
import SystemConfiguration.CaptiveNetwork

struct SettingsView: View {
    @ObservedObject var viewModel: Settings_ViewModel
    @State private var isEditingParticipantID = false
    @State private var isEditingSessionName = false
    @State private var newParticipantID = ""
    @State private var newSessionName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                header
                settingsList
            }
            .padding()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
        }
    }
    
    private var settingsList: some View {
        List {
            Section(header: Text("General")) {
                participantIDView
                sessionNameView
            }
            
            Section(header: Text("Permissions")) {
                allowUDPConnectionsView
                allowScreenRecordingView
            }
            
            HStack(spacing: 4.5) {
                Text("Local WiFi IP Address:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(getIPAddress() ?? "nil")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .listStyle(.insetGrouped)
        .padding(.horizontal, -20)
    }
    
    private var participantIDView: some View {
        NavigationLink(
            destination: Text(""),
            isActive: $isEditingParticipantID,
            label: {
                HStack {
                    Text("Participant ID")
                    Spacer()
                    Text(viewModel.participantID.isEmpty ? "N/A" : viewModel.participantID)
                        .foregroundColor(.gray)
                        .padding(.trailing, 6)
                }
            })
            .onTapGesture {
                isEditingParticipantID.toggle()
            }
            .alert("Participant ID", isPresented: $isEditingParticipantID) {
                TextField("Enter participant ID", text: $newParticipantID)
                    .textInputAutocapitalization(.never)
                Button("Ok") {
                    submitID(newParticipantID: $newParticipantID)
                }
                Button("Cancel", role: .cancel) { }
            }
    }
    
    private var sessionNameView: some View {
        NavigationLink(
            destination: Text(""),
            isActive: $isEditingSessionName,
            label: {
                HStack {
                    Text("Session Name")
                    Spacer()
                    Text(viewModel.sessionName.isEmpty ? "N/A" : viewModel.sessionName)
                        .foregroundColor(.gray)
                        .padding(.trailing, 6)
                }
            })
            .onTapGesture {
                isEditingSessionName.toggle()
            }
            .alert("Session Name", isPresented: $isEditingSessionName) {
                TextField("Enter session name", text: $newSessionName)
                    .textInputAutocapitalization(.never)
                Button("Ok") {
                    submitSession(newSessionName: $newSessionName)
                }
                Button("Cancel", role: .cancel) { }
            }
    }
    
    private var allowUDPConnectionsView: some View {
        HStack {
            Image(systemName: "wifi.square.fill")
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Toggle(isOn: $viewModel.allowUDPConnections) {
                Text("Allow Wireless Connections")
            }
        }
    }
    
    private var allowScreenRecordingView: some View {
        HStack {
            Image(systemName: "video.square.fill")
                .font(.system(size: 30))
                .foregroundColor(.green)
            
            Toggle(isOn: $viewModel.allowScreenRecording) {
                Text("Record Video Sessions")
            }
        }
    }

    func submitID(newParticipantID: Binding<String>) {
        viewModel.participantID = newParticipantID.wrappedValue
    }
    
    func submitSession(newSessionName: Binding<String>) {
        viewModel.sessionName = newSessionName.wrappedValue
    }
    
    func getIPAddress() -> String? {
        var address : String?

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface (IPv6 address is not helpful for UDP connecting, removed):
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
            //if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                // wifi = ["en0"]
                // wired = ["en2", "en3", "en4"]
                // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
                
                let name = String(cString: interface.ifa_name)
                // Only accessing WiFi
                if  name == "en0" {
                    // Convert interface address to readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = Settings_ViewModel()
        SettingsView(viewModel: viewModel)
    }
}
