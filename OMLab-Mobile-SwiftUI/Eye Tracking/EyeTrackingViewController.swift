/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for eye tracking experience.
*/

import ARKit
import SceneKit
import SwiftUI
import UIKit

class EyeTrackingViewController: UIViewController, ARSessionDelegate, UITextFieldDelegate {
    
    // MARK: Outlets
    var sceneView: ARSCNView!
    weak var recordingSwitch: UISwitch!
    weak var recordingName: UITextField!
    //weak var logTextView: UITextView!
    var isRecordingSwitchOn = false

    // https://stackoverflow.com/questions/35006738/auto-scroll-for-uitextview-using-swift-ios-app
    // MARK: Properties
    var eyeTrackingRecording : EyeTrackingRecording!
    var eyeTrackingNetworkService : EyeTrackingNetworkService!
    var faceAnchorsAndContentControllers: [ARFaceAnchor: VirtualContentController] = [:]

    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneView = ARSCNView(frame: view.bounds)
        sceneView.translatesAutoresizingMaskIntoConstraints = false // disable auto layout
        
        view.addSubview(sceneView)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let recordingSwitch = UISwitch()
        recordingSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(recordingSwitch)
        
        NSLayoutConstraint.activate([
            recordingSwitch.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            recordingSwitch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        
        /*
        let recordingName = UITextField()
        recordingName.translatesAutoresizingMaskIntoConstraints = false
        recordingName.placeholder = "Enter recording name"
        recordingName.borderStyle = .roundedRect
        recordingName.returnKeyType = .done
        recordingName.delegate = self

        view.addSubview(recordingName)
        
        NSLayoutConstraint.activate([
            recordingName.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingName.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            recordingName.widthAnchor.constraint(equalToConstant: 200),
            recordingName.heightAnchor.constraint(equalToConstant: 30)
        ])
         */

        // asign values to existing variables
        self.sceneView = sceneView
        self.recordingSwitch = recordingSwitch
        //self.recordingName = recordingName

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Initialize the recording
        eyeTrackingRecording = EyeTrackingRecording()
        
        // initialize UDP listener
        eyeTrackingNetworkService = EyeTrackingNetworkService(on:8000, self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Dismiss the keyboard
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    // MARK: - ARSessionDelegate

    // Session display if AR session fails to display
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    // Running AR Session
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let faceAnchor = anchors[0] as! ARFaceAnchor
        eyeTrackingRecording.RecordData(recordingSwitchIsOn: recordingSwitch.isOn, session, faceAnchor, "file")
        //self.displayFileNamer()
    }

    func displayFileNamer() {
        if isRecordingSwitchOn == recordingSwitch.isOn {
            // Recording switch state hasn't changed, so return
            return
        }
        
        isRecordingSwitchOn = recordingSwitch.isOn

        let alertController = UIAlertController(title: "File Name", message: "Enter a name for the recording", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Enter Recording Name"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.resetTracking()
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let fileName = alertController.textFields?.first?.text else {
                self.resetTracking()
                return
            }

            self.renameFile(fileName: self.eyeTrackingRecording.folderName, newFileName: fileName)
            self.resetTracking()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        present(alertController, animated: true, completion: nil)
    }

    func renameFile(fileName: String, newFileName: String) {
        let fileManager = FileManager.default
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        let newFileURL = documentsURL.appendingPathComponent(newFileName)
        
        do {
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            print("File named successfully.")
        } catch {
            print("Error renaming file: \(error.localizedDescription)")
        }
    }
    
    func recordEvent(_ message: String) {
        eyeTrackingRecording.RecordMessage(recordingSwitchIsOn: recordingSwitch.isOn, message, recordingName.text ?? "test")
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = 1
        }
        configuration.isLightEstimationEnabled = true
        configuration.worldAlignment = .gravity
        
        /*
         The y-axis matches the direction of gravity as detected by the device's motion sensing hardware; that is, the vector (0,-1,0) points downward.
        
        The position and orientation of the device as of when the session configuration is first run determine the rest of the coordinate system: For the z-axis, ARKit chooses a basis vector (0,0,-1) pointing in the direction the device camera faces and perpendicular to the gravity axis. ARKit chooses a x-axis based on the z- and y-axes using the right hand rule—that is, the basis vector (1,0,0) is orthogonal to the other two axes, and (for a viewer looking in the negative-z direction) points toward the right.
         */

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        faceAnchorsAndContentControllers.removeAll()
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        let restartAction = UIAlertAction(title: "Exit", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            exit(0);
        }
        
        alertController.addAction(continueAction)
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return false
    }
    
    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension EyeTrackingViewController: ARSCNViewDelegate {
     
    // add a new face anchor
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        DispatchQueue.main.async {
            let contentController = TransformVisualization()
            if node.childNodes.isEmpty, let contentNode = contentController.renderer(renderer, nodeFor: faceAnchor) {
                node.addChildNode(contentNode)
                self.faceAnchorsAndContentControllers[faceAnchor] = contentController
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let contentController = faceAnchorsAndContentControllers[faceAnchor],
            let contentNode = contentController.contentNode else {
            return
        }
        
        contentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceAnchorsAndContentControllers[faceAnchor] = nil
    }
}
