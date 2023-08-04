//
//  SettingsView.swift
//  OMLab-Mobile-SwiftUI
//
//  Created by Christopher Bain on 4/19/23.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = Settings_ViewModel()
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
                Toggle(isOn: $viewModel.allowUDPConnections) {
                    Text("Allow UDP Connections")
                }
                
                Toggle(isOn: $viewModel.allowScreenRecording) {
                    Text("Record Tracking Sessions")
                }
            }
        }
        .listStyle(.insetGrouped)
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


    func submitID(newParticipantID: Binding<String>) {
        viewModel.participantID = newParticipantID.wrappedValue
    }
    
    func submitSession(newSessionName: Binding<String>) {
        viewModel.sessionName = newSessionName.wrappedValue
    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


