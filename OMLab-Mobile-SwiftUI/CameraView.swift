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
        EyeTrackingView()
            //.edgesIgnoringSafeArea(.all)
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
