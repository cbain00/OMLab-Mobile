////
////  ProfileView.swift
////  OMLab-Mobile SwiftUI
////
////  Created by Christopher Bain on 4/17/23.
////
//
//import SwiftUI
//
//struct ProfileView: View {
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Title and Settings Button
//                ProfileMenuView()
//
//                Spacer()
//
//                // Personal Info List
//                PersonalInfoView()
//            }
//        }
//    }
//}
//
//struct ProfileMenuView: View {
//    var body: some View {
//        HStack {
//            Text("User Profile")
//                .font(.title)
//                .fontWeight(.bold)
//
//            Spacer()
//
//            NavigationLink(destination: SettingsView()) {
//                Image(systemName: "gearshape")
//            }
//        }
//        .padding(.horizontal)
//    }
//}
//
//struct PersonalInfoView: View {
//    @State private var name = ""
//    @State private var email = ""
//    @State private var dob = Date()
//    @State private var gender = ""
//    @State private var height = 60 // in inches
//    @State private var weight = 100 // in lbs
//
//    let genderOptions = ["Male", "Female"]
//    let heightRange = 48...84 // height range in inches
//    let weightRange = 100...400 // weight range in lbs
//
//    @State private var heightString = "5 ft 0 in"
//    @State private var weightString = "100 lbs"
//
//    var body: some View {
//        List {
//            Section(header: Text("Personal Information")) {
//                // Name
//                TextFieldRow(title: "Name", placeholder: "Enter your name", text: $name)
//
//                // Email
//                TextFieldRow(title: "Email", placeholder: "Enter your email", text: $email)
//
//                // Date of Birth
//                DatePicker("Date of Birth", selection: $dob, displayedComponents: [.date])
//
//                // Gender
//                PickerRow(title: "Gender", options: genderOptions, selection: $gender)
//
//                // Height
//                PickerRow(title: "Height", options: heightRange.map { inch in
//                    String(format: "%d ft %d in", inch / 12, inch % 12)
//                }, selection: $heightString)
//
//                // Weight
//                PickerRow(title: "Weight", options: weightRange.map { lbs in
//                    String(format: "%d lbs", lbs)
//                }, selection: $weightString)
//            }
//        }
//        .onChange(of: heightString) { newValue in
//            if let inch = newValue.split(separator: " ").compactMap({ Int($0) }).last {
//                height = inch
//            }
//        }
//        .onChange(of: weightString) { newValue in
//            if let lbs = newValue.split(separator: " ").compactMap({ Int($0) }).first {
//                weight = lbs
//            }
//        }
//    }
//}
//
//struct TextFieldRow: View {
//    let title: String
//    let placeholder: String
//    @Binding var text: String
//
//    var body: some View {
//        HStack {
//            Text(title)
//                .foregroundColor(.primary)
//            Spacer()
//            TextField(placeholder, text: $text)
//                .foregroundColor(.secondary)
//        }
//    }
//}
//
//struct PickerRow: View {
//    let title: String
//    let options: [String]
//    @Binding var selection: String
//
//    var body: some View {
//        HStack {
//            Text(title)
//                .foregroundColor(.primary)
//            Spacer()
//            Picker(selection: $selection, label: Text("")) {
//                ForEach(options, id: \.self) { option in
//                    Text(option)
//                }
//            }
//            .foregroundColor(.secondary)
//        }
//    }
//}
