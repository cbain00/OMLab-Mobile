//
//  EyeTrackingRecording.swift
//  ARKitFaceExample
//
//  Created by Jorge Otero-Millan on 6/29/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import ARKit
import Foundation

class EyeTrackingRecording {
    
    var dataFile: FileHandle!
    var eventFile: FileHandle!
    var dataFilePath: String = ""
    var eventFilePath: String = ""
    var folderName: String = ""
    
    var lastTimestamp : TimeInterval = TimeInterval()
    
    func RecordData(recordingSwitchIsOn: Bool, _ session: ARSession, _ faceAnchor: ARFaceAnchor, _ recordingName: String) {
        
        if #available(iOS 15.0, *) {
            // https://stackoverflow.com/questions/52477238/how-to-get-the-angle-and-distance-between-camera-position-and-image-object-posit
            let cameraMatrix = session.currentFrame?.camera.transform ?? simd_float4x4()
            
            lastTimestamp = session.currentFrame?.timestamp ?? 0
        
            if recordingSwitchIsOn
            {
                if dataFile == nil
                {
                    folderName = CreateNewFile(recordingName)
                }
                
                // https://stackoverflow.com/questions/50236214/arkit-eulerangles-of-transform-matrix-4x4
                
                let timestamp = session.currentFrame?.timestamp ?? 0
                
                let rightEyeEulerAngles = faceAnchor.rightEyeTransform.eulerAngles
                let leftEyeEulerAngles = faceAnchor.leftEyeTransform.eulerAngles
                let transformEulerAngles = faceAnchor.transform.eulerAngles
                
                let rightEyeTransform = faceAnchor.rightEyeTransform
                let leftEyeTransform = faceAnchor.leftEyeTransform
                let transform = faceAnchor.transform
                
                let eyeBlinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? Float.nan
                let eyeLookDownLeft = faceAnchor.blendShapes[.eyeLookDownLeft]?.floatValue ?? Float.nan
                let eyeLookInLeft = faceAnchor.blendShapes[.eyeLookInLeft]?.floatValue ?? Float.nan
                let eyeLookOutLeft = faceAnchor.blendShapes[.eyeLookOutLeft]?.floatValue ?? Float.nan
                let eyeLookUpLeft = faceAnchor.blendShapes[.eyeLookUpLeft]?.floatValue ?? Float.nan
                let eyeSquintLeft = faceAnchor.blendShapes[.eyeSquintLeft]?.floatValue ?? Float.nan
                let eyeWideLeft = faceAnchor.blendShapes[.eyeWideLeft]?.floatValue ?? Float.nan
                
                let eyeBlinkRight = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? Float.nan
                let eyeLookDownRight = faceAnchor.blendShapes[.eyeLookDownRight]?.floatValue ?? Float.nan
                let eyeLookInRight = faceAnchor.blendShapes[.eyeLookInRight]?.floatValue ?? Float.nan
                let eyeLookOutRight = faceAnchor.blendShapes[.eyeLookOutRight]?.floatValue ?? Float.nan
                let eyeLookUpRight = faceAnchor.blendShapes[.eyeLookUpRight]?.floatValue ?? Float.nan
                let eyeSquintRight = faceAnchor.blendShapes[.eyeSquintRight]?.floatValue ?? Float.nan
                let eyeWideRight = faceAnchor.blendShapes[.eyeWideRight]?.floatValue ?? Float.nan
                
                let lookAtPoint = faceAnchor.lookAtPoint
                
                let line = "\(timestamp), \(rightEyeEulerAngles[0]), \(rightEyeEulerAngles[1]), \(rightEyeEulerAngles[2]), \(leftEyeEulerAngles[0]), \(leftEyeEulerAngles[1]), \(leftEyeEulerAngles[2]), \(transformEulerAngles[0]), \(transformEulerAngles[1]), \(transformEulerAngles[2]),  \(rightEyeTransform[0,0]), \(rightEyeTransform[0,1]), \(rightEyeTransform[0,2]), \(rightEyeTransform[0,3]), \(rightEyeTransform[1,0]), \(rightEyeTransform[1,1]), \(rightEyeTransform[1,2]), \(rightEyeTransform[1,3]), \(rightEyeTransform[2,0]), \(rightEyeTransform[2,1]), \(rightEyeTransform[2,2]), \(rightEyeTransform[2,3]), \(rightEyeTransform[3,0]), \(rightEyeTransform[3,1]), \(rightEyeTransform[3,2]), \(rightEyeTransform[3,3]), \(leftEyeTransform[0,0]), \(leftEyeTransform[0,1]), \(leftEyeTransform[0,2]), \(leftEyeTransform[0,3]), \(leftEyeTransform[1,0]), \(leftEyeTransform[1,1]), \(leftEyeTransform[1,2]), \(leftEyeTransform[1,3]), \(leftEyeTransform[2,0]), \(leftEyeTransform[2,1]), \(leftEyeTransform[2,2]), \(leftEyeTransform[2,3]), \(leftEyeTransform[3,0]), \(leftEyeTransform[3,1]), \(leftEyeTransform[3,2]), \(leftEyeTransform[3,3]), \(transform[0,0]), \(transform[0,1]), \(transform[0,2]), \(transform[0,3]), \(transform[1,0]), \(transform[1,1]), \(transform[1,2]), \(transform[1,3]), \(transform[2,0]), \(transform[2,1]), \(transform[2,2]), \(transform[2,3]), \(transform[3,0]), \(transform[3,1]), \(transform[3,2]), \(transform[3,3]), \(cameraMatrix[0,0]), \(cameraMatrix[0,1]), \(cameraMatrix[0,2]), \(cameraMatrix[0,3]), \(cameraMatrix[1,0]), \(cameraMatrix[1,1]), \(cameraMatrix[1,2]), \(cameraMatrix[1,3]), \(cameraMatrix[2,0]), \(cameraMatrix[2,1]), \(cameraMatrix[2,2]), \(cameraMatrix[2,3]), \(cameraMatrix[3,0]), \(cameraMatrix[3,1]), \(cameraMatrix[3,2]), \(cameraMatrix[3,3]), \(eyeBlinkLeft), \(eyeLookDownLeft), \(eyeLookInLeft), \(eyeLookOutLeft), \(eyeLookUpLeft), \(eyeSquintLeft), \(eyeWideLeft), \(eyeBlinkRight), \(eyeLookDownRight), \(eyeLookInRight), \(eyeLookOutRight), \(eyeLookUpRight), \(eyeSquintRight), \(eyeWideRight), \(lookAtPoint[0]), \(lookAtPoint[1]), \(lookAtPoint[2])\n"
                
                // Write data
                dataFile!.write(line.data(using: .utf8)!)
            }
            
            // Close data file
            if (!recordingSwitchIsOn && dataFile != nil)
            {
                dataFile!.closeFile()
                dataFile = nil
            }
            
            // Close event file because otherwise it will not close unless there is another event
            if (!recordingSwitchIsOn && eventFile != nil)
            {
                eventFile!.closeFile()
                eventFile = nil
            }
        }
    }
    
    
    func RecordMessage(recordingSwitchIsOn: Bool, _ message: String, _ recordingName: String) {
        
        if #available(iOS 15.0, *) {
           
            if recordingSwitchIsOn
            {
                if eventFile == nil
                {
                    CreateNewEventFile(recordingName)
                }
                
                //https://stackoverflow.com/questions/50236214/arkit-eulerangles-of-transform-matrix-4x4
                
                let line = "\(lastTimestamp), \(message)\n"
                
                // Write data
                eventFile!.write(line.data(using: .utf8)!)
            }
            
            // Close file
            if (!recordingSwitchIsOn && eventFile != nil)
            {
                eventFile!.closeFile()
                eventFile = nil
            }
        }
    }
    
    
    func CreateNewFile(_ recordingName: String) -> String {
        // https://stackoverflow.com/questions/58107752/how-can-i-write-to-a-file-line-by-line-in-swift-4
        // https://nemecek.be/blog/57/making-files-from-your-app-available-in-the-ios-files-app
        // https://cocoacasts.com/swift-fundamentals-how-to-convert-a-date-to-a-string-in-swift
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'_'HHmmss"
        
        let foldername = "\(recordingName)_\(formatter.string(from: Date()))"
        let dataFilename = "\(foldername).txt"
        let eventFilename = "\(foldername)_events.txt"
        
        // create new folder first
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let dirPath = documentsURL?.appendingPathComponent(foldername, isDirectory: true)
        do
        {
            try FileManager.default.createDirectory(atPath: dirPath!.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            print("Unable to create directory \(error.debugDescription)")
        }
        print("\nDir Path = \(dirPath!)")
        
        
        // create data file and event file
        
        dataFilePath = dirPath!.appendingPathComponent(dataFilename).path
        eventFilePath = dirPath!.appendingPathComponent(eventFilename).path
        
        
        let fileManager = FileManager.default
        // If file exists, remove it
        if fileManager.fileExists(atPath: dataFilePath)
        {
            do { try fileManager.removeItem(atPath: dataFilePath) }
            catch let error {
                print(error)
            }
        }
        
        // Create file and open it for writing
        fileManager.createFile(atPath: dataFilePath,  contents:Data(" ".utf8), attributes: nil)
        dataFile = FileHandle(forWritingAtPath: dataFilePath)
        if dataFile == nil
        {
            print("Open of outFilename forWritingAtPath: failed.  \nCheck whether the file already exists.  \nIt should already exist.\n");
            exit(0)
        }
        
        let line = "Time, RightEyeX, RightEyeY, RightEyeZ, LeftEyeX, LeftEyeY, LeftEyeZ, HeadX, HeadY, HeadZ, RightEye00, RightEye01, RightEye02, RightEye03, RightEye10, RightEye11, RightEye12, RightEye13, RightEye20, RightEye21, RightEye22, RightEye23, RightEye30, RightEye31, RightEye32, RightEye33, LeftEye00, LeftEye01, LeftEye02, LeftEye03, LeftEye10, LeftEye11, LeftEye12, LeftEye13, LeftEye20, LeftEye21, LeftEye22, LeftEye23, LeftEye30, LeftEye31, LeftEye32, LeftEye33, Head00, Head01, Head02, Head03, Head10, Head11, Head12, Head13, Head20, Head21, Head22, Head23, Head30, Head31, Head32, Head33, Camera00, Camera01, Camera02, Camera03, Camera10, Camera11, Camera12, Camera13, Camera20, Camera21, Camera22, Camera23, Camera30, Camera31, Camera32, Camera33, eyeBlinkLeft, eyeLookDownLeft, eyeLookInLeft, eyeLookOutLeft, eyeLookUpLeft, eyeSquintLeft, eyeWideLeft, eyeBlinkRight, eyeLookDownRight, eyeLookInRight, eyeLookOutRight, eyeLookUpRight, eyeSquintRight, eyeWideRight, lookAtPoint0, lookAtPoint1, lookAtPoint2\n"
        
        // Write data
        dataFile!.write(line.data(using: .utf8)!)
        return foldername
    }
    
    
    func CreateNewEventFile(_ recordingName: String) {
        
        let fileManager = FileManager.default
        // If file exists, remove it
        if fileManager.fileExists(atPath: eventFilePath)
        {
            do { try fileManager.removeItem(atPath: eventFilePath) }
            catch let error{
                print(error)
            }
        }
        
        // Create file and open it for writing
        fileManager.createFile(atPath: eventFilePath, contents:Data(" ".utf8), attributes: nil)
        eventFile = FileHandle(forWritingAtPath: eventFilePath)
        if eventFile == nil
        {
            print("Open of outFilename forWritingAtPath: failed.  \nCheck whether the file already exists.  \nIt should already exist.\n");
            exit(0)
        }
        
        let line = "Time, Message\n"
        
        // Write data
        eventFile!.write(line.data(using: .utf8)!)
    }
}

/*
 %
 figure
 subplot(5,1,1,'nextplot','add')
 plot(d.Time, [d.RightEyeX, d.LeftEyeX])
 subplot(5,1,2,'nextplot','add')
 plot(d.Time, [d.RightEyeY, d.LeftEyeY])
 subplot(5,1,3,'nextplot','add')
 plot(d.Time, [d.HeadX, d.HeadY, d.HeadZ])
 subplot(5,1,4,'nextplot','add')
 plot(d.Time, [d.Head30, d.Head31, d.Head32])
 subplot(5,1,5,'nextplot','add')
 plot(d.Time, [d.lookAtPoint0, d.lookAtPoint1, d.lookAtPoint2])
 */
