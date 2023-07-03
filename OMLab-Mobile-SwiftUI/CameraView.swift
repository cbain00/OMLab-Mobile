//
//  CameraView.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/18/23.
//

import SwiftUI

struct CameraView: View {
    @State private var isRecording = false
    
    var body: some View {
        EyeTrackingView().edgesIgnoringSafeArea(.all)
    }
}

// record button on screen, currently just for show
struct RecordButton: View {
    var isRecording: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 50, height: 50) // Adjust the size of the circle here
                Image(systemName: isRecording ? "stop.fill" : "record.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30) // Adjust the size of the image here
                    .foregroundColor(.white)
            }
        }
        .frame(width: 70, height: 70) // Adjust the size of the button here
        .background(Color.black.opacity(0.01))
        .cornerRadius(35)
    }
}

struct EyeTrackingView: UIViewControllerRepresentable {        
    func makeUIViewController(context: Context) -> EyeTrackingViewController {
        let eyeTrackingVC = EyeTrackingViewController()
        return eyeTrackingVC
    }
    
    func updateUIViewController(_ uiViewController: EyeTrackingViewController, context: Context) {
        // Update the EyeTrackingViewController as needed using the viewModel
    }
}
