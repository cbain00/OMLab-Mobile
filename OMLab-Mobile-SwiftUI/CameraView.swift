//
//  CameraView.swift
//  OMLab-Mobile SwiftUI
//
//  Created by Christopher Bain on 4/18/23.
//

import SwiftUI

struct CameraView: View {
    @StateObject var viewModel = ViewController_ViewModel()
    @State var buttonIsRecording = false
    
    var body: some View {
        ZStack {
            EyeTrackingView(viewModel: viewModel)
            VStack {
                Spacer()
                RecordButton(
                    isRecording: $buttonIsRecording,
                    startAction: { viewModel.isRecording = true },
                    stopAction: { viewModel.isRecording = false }
                )
                    .frame(width: 80, height: 80)
                    .padding(.bottom, 20)
            }
        }
    }
}


struct EyeTrackingView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ViewController_ViewModel
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
        
    func updateUIViewController(_ uiViewController: EyeTrackingViewController, context: Context) {
        if viewModel.isRecording == true {
            context.coordinator.startRecording()
        } else {
            context.coordinator.stopRecording()
        }
    }
    
    func makeUIViewController(context: Context) -> EyeTrackingViewController {
        let eyetrackingvc = context.coordinator.eyeTrackingViewController
        return eyetrackingvc
    }

    class Coordinator: NSObject, EyeTrackingViewControllerDelegate {
        var eyeTrackingViewController = EyeTrackingViewController()
        
        func startRecording() {
            print("coordinator: start recording")
            eyeTrackingViewController.isRecordingSwitchOn = true
            eyeTrackingViewController.startRecordingReplayKit()
        }
        
        func stopRecording() {
            print("coordinator: stop recording")
            eyeTrackingViewController.isRecordingSwitchOn = false
            eyeTrackingViewController.stopRecordingReplayKit()
        }
    }
}

protocol EyeTrackingViewControllerDelegate: AnyObject {
    func startRecording()
    func stopRecording()
}


// https://gist.github.com/joshgalvan/29b7ede649da432a14c50e97e59a2147
struct RecordButton: View {
    @Binding var isRecording: Bool
    let startAction: () -> Void
    let stopAction: () -> Void
    let buttonColor: Color
    let borderColor: Color
    let animation: Animation
    
    init(isRecording: Binding<Bool>, animation: Animation = .easeInOut(duration: 0.25), buttonColor: Color = .red, borderColor: Color = .white, startAction: @escaping () -> Void, stopAction: @escaping () -> Void) {
        self._isRecording = isRecording
        self.animation = animation
        self.buttonColor = buttonColor
        self.borderColor = borderColor
        self.startAction = startAction
        self.stopAction = stopAction
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let minDimension = min(geometry.size.width, geometry.size.height)
                
                Button {
                    if isRecording {
                        deactivate()
                    } else {
                        activate()
                    }
                } label: {
                    RecordButtonShape(isRecording: isRecording)
                        .fill(buttonColor)
                }
                .buttonStyle(PlainButtonStyle())

                Circle()
                    .strokeBorder(lineWidth: minDimension * 0.05)
                    .foregroundColor(borderColor)
            }
        }
        .background(Color.clear)
    }
    
    private func activate() {
        startAction()
        withAnimation(animation) {
            isRecording = true
        }
    }
    
    private func deactivate() {
        stopAction()
        withAnimation(animation) {
            isRecording = false
        }
    }
}

struct RecordButtonShape: Shape {
    var shapeRadius: CGFloat
    var distanceFromCardinal: CGFloat
    var b: CGFloat
    var c: CGFloat
    
    init(isRecording: Bool) {
        self.shapeRadius = isRecording ? 1.0 : 0.0
        self.distanceFromCardinal = isRecording ? 1.0 : 0.0
        self.b = isRecording ? 0.90 : 0.55
        self.c = isRecording ? 1.00 : 0.99
    }
    
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, Double>>> {
        get {
            AnimatablePair(Double(shapeRadius),
                           AnimatablePair(Double(distanceFromCardinal),
                                          AnimatablePair(Double(b), Double(c))))
        }
        set {
            shapeRadius = Double(newValue.first)
            distanceFromCardinal = Double(newValue.second.first)
            b = Double(newValue.second.second.first)
            c = Double(newValue.second.second.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let minDimension = min(rect.maxX, rect.maxY)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (minDimension / 2 * 0.82) - (shapeRadius * minDimension * 0.22)
        let movementFactor = 0.65
        
        let rightTop = CGPoint(x: center.x + radius, y: center.y - radius * movementFactor * distanceFromCardinal)
        let rightBottom = CGPoint(x: center.x + radius, y: center.y + radius * movementFactor * distanceFromCardinal)
        
        let topRight = CGPoint(x: center.x + radius * movementFactor * distanceFromCardinal, y: center.y - radius)
        let topLeft = CGPoint(x: center.x - radius * movementFactor * distanceFromCardinal, y: center.y - radius)
        
        let leftTop = CGPoint(x: center.x - radius, y: center.y - radius * movementFactor * distanceFromCardinal)
        let leftBottom = CGPoint(x: center.x - radius, y: center.y + radius * movementFactor * distanceFromCardinal)
        
        let bottomRight = CGPoint(x: center.x + radius * movementFactor * distanceFromCardinal, y: center.y + radius)
        let bottomLeft = CGPoint(x: center.x - radius * movementFactor * distanceFromCardinal, y: center.y + radius)
        
        let topRightControl1 = CGPoint(x: center.x + radius * c, y: center.y - radius * b)
        let topRightControl2 = CGPoint(x: center.x + radius * b, y: center.y - radius * c)
        
        let topLeftControl1 = CGPoint(x: center.x - radius * b, y: center.y - radius * c)
        let topLeftControl2 = CGPoint(x: center.x - radius * c, y: center.y - radius * b)
        
        let bottomLeftControl1 = CGPoint(x: center.x - radius * c, y: center.y + radius * b)
        let bottomLeftControl2 = CGPoint(x: center.x - radius * b, y: center.y + radius * c)
        
        let bottomRightControl1 = CGPoint(x: center.x + radius * b, y: center.y + radius * c)
        let bottomRightControl2 = CGPoint(x: center.x + radius * c, y: center.y + radius * b)
    
        var path = Path()
        
        path.move(to: rightTop)
        path.addCurve(to: topRight, control1: topRightControl1, control2: topRightControl2)
        path.addLine(to: topLeft)
        path.addCurve(to: leftTop, control1: topLeftControl1, control2: topLeftControl2)
        path.addLine(to: leftBottom)
        path.addCurve(to: bottomLeft, control1: bottomLeftControl1, control2: bottomLeftControl2)
        path.addLine(to: bottomRight)
        path.addCurve(to: rightBottom, control1: bottomRightControl1, control2: bottomRightControl2)
        path.addLine(to: rightTop)

        return path
    }
    
    /*
    // start screen recording after button is pressed
    func startRecordingReplayKit() {
        recorder.startRecording { (error) in
            guard error == nil else {
                print("Failed to start recording")
                return
            }
        }
    }
    
    // stop screen recording after button is pressed
    func stopRecordingReplayKit() {
        // if recording, stop recording, else don't do anything
        // this is to avoid permission being presented twice
        if recorder.isRecording {
            outputURL = tempURL()
            recorder.stopRecording(withOutput: outputURL) { (error) in
                guard error == nil else {
                    print("Failed to save recording")
                    return
                }
                print(self.outputURL!)
            }
        } else {
            return
        }
    }
    
    // create URL for video to be saved at
    func tempURL() -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsURL.appendingPathComponent(self.eyeTrackingRecording.folderName)
        let fileURL = folderURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        return fileURL
    }
    
    // AVCaptureFileOutputRecordingDelegate function stub
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            let videoRecorded = outputURL! as URL
            print("File saved successfully as: \(videoRecorded)")
        }
    }
    */
}

