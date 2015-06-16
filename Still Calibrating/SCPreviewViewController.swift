//
//  SCPreviewViewController.swift
//  Still Calibrating
//
//  Created by Lee Walsh on 15/06/2015.
//  Copyright (c) 2015 Lee David Walsh. All rights reserved.
//

import Cocoa
import AVFoundation

class SCPreviewViewController: NSViewController {
    @IBOutlet var cameraPopup: NSPopUpButton?
    @IBOutlet var captureStillButton: NSButton?
    var videoDevices = [AVCaptureDevice]()
    var selectedDevice: AVCaptureDevice?
    var session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let devices = AVCaptureDevice.devices()
        cameraPopup!.removeAllItems()
        for device in devices {
            if device.hasMediaType(AVMediaTypeVideo){
                videoDevices.append(device as! AVCaptureDevice)
                cameraPopup!.addItemWithTitle((device as! AVCaptureDevice).localizedName)
            }
        }
        cameraPopup!.selectItem(nil)
    }
    
    @IBAction func selectCamera(sender: AnyObject){
        if !self.view.wantsLayer {
            self.view.wantsLayer = true
        } else {
            for layer in self.view.layer!.sublayers{
                layer.removeFromSuperlayer()
            }
        }
        session.sessionPreset = AVCaptureSessionPresetMedium
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer.layerWithSession(session) as? AVCaptureVideoPreviewLayer
        captureVideoPreviewLayer!.frame = self.view.bounds
        self.view.layer!.addSublayer(captureVideoPreviewLayer)
        captureVideoPreviewLayer!.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerHeightSizable
        captureVideoPreviewLayer!.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0.0, 1.0, 0.0)
        
        selectedDevice = videoDevices[sender.indexOfSelectedItem()]
        var error: NSError?
        let deviceInput = AVCaptureDeviceInput.deviceInputWithDevice(selectedDevice, error: &error) as? AVCaptureDeviceInput
        if deviceInput == nil {
            let errorAlert = NSAlert(error: error!)
            errorAlert.runModal()
        }
        session.addInput(deviceInput)
        let stillOutput = AVCaptureStillImageOutput()
        session.addOutput(stillOutput)
        session.startRunning()
    }
    
    @IBAction func captureStillImage(sender: AnyObject){
        if selectedDevice != nil {
            let stillOutput = session.outputs[0] as! AVCaptureStillImageOutput
            let videoConnection = stillOutput.connectionWithMediaType(AVMediaTypeVideo)
            let savePanel = NSSavePanel()
            savePanel.extensionHidden = false
            let result = savePanel.runModal()
            if result == NSModalResponseOK {
                let filePath = savePanel.URL!.path!+".png"
                let captureAlert = NSAlert()
                captureAlert.messageText = "Ready to capture a still image"
                captureAlert.addButtonWithTitle("Capture")
                captureAlert.runModal()
                stillOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (sampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
                    let exifAttachments = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, nil)
                    if (exifAttachments != nil) {
                        //use attachments
                    }
                    let capturedImageRep = NSBitmapImageRep(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer))
                    let pngData = capturedImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [NSObject: AnyObject]())
                    if pngData != nil {
                        pngData!.writeToFile(filePath, atomically: true)
                    }
                })
            }
        } else {
            NSBeep()
        }
    }
    
}
