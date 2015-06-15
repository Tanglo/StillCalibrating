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
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetMedium
        let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer.layerWithSession(session) as? AVCaptureVideoPreviewLayer
        captureVideoPreviewLayer!.frame = self.view.bounds
//        captureVideoPreviewLayer!.transform = CATransform3DMakeRotation(CGFloat(M_1_PI), 0.0, 1.0, 0.0)
        self.view.layer!.addSublayer(captureVideoPreviewLayer)
        
        let videoDevice = videoDevices[sender.indexOfSelectedItem()]
        var error: NSError?
        let deviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as? AVCaptureDeviceInput
        if deviceInput == nil {
            let errorAlert = NSAlert(error: error!)
            errorAlert.runModal()
        }
        session.addInput(deviceInput)
        session.startRunning()
    }
    
}
