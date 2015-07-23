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
    var flipHorizontally = false
    var flipVertically = false

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
        self.addObserver(self, forKeyPath: "flipHorizontally", options: .allZeros, context: nil)
        self.addObserver(self, forKeyPath: "flipVertically", options: .allZeros, context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        selectCamera(cameraPopup!)
    }
    
    @IBAction func selectCamera(sender: AnyObject){
        if cameraPopup!.selectedItem != nil {
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
            captureVideoPreviewLayer!.transform = CATransform3DIdentity
            if flipHorizontally {
                captureVideoPreviewLayer!.transform = CATransform3DConcat(captureVideoPreviewLayer!.transform, CATransform3DMakeRotation(CGFloat(M_PI), 0.0, 1.0, 0.0))
            }
            if flipVertically {
                captureVideoPreviewLayer!.transform = CATransform3DConcat(captureVideoPreviewLayer!.transform, CATransform3DMakeRotation(CGFloat(M_PI), 1.0, 0.0, 0.0))
            }
            
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
                    var capturedImageRep = NSBitmapImageRep(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer))
                    if self.flipHorizontally || self.flipVertically{
                        capturedImageRep = self.flipBitmapImageRep(capturedImageRep!)
                    }
                    var pngData = capturedImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [NSObject: AnyObject]())
                    if pngData != nil {
                        pngData!.writeToFile(filePath, atomically: true)
                    }
                })
            }
        } else {
            NSBeep()
        }
    }
    
    func flipBitmapImageRep(bitmapImageRep: NSBitmapImageRep) -> NSBitmapImageRep{
        let flippedImage = NSImage(size: bitmapImageRep.size)
        flippedImage.lockFocus()
        var transform = NSAffineTransform()
        if flipHorizontally{
            transform.scaleXBy(-1.0, yBy: 1.0)
            transform.translateXBy(-flippedImage.size.width, yBy: 0.0)
        }
        if flipVertically{
            transform.scaleXBy(1.0, yBy: -1.0)
            transform.translateXBy(0.0, yBy: -flippedImage.size.height)
        }
        transform.concat()
        bitmapImageRep.drawInRect(NSRect(origin: NSPoint(x: 0.0, y: 0.0), size: flippedImage.size))
        flippedImage.unlockFocus()
        let flippedData = flippedImage.TIFFRepresentation
        return NSBitmapImageRep(data: flippedData!)!
    }
    
    @IBAction func toggleFocus(sender: AnyObject){
        if(selectedDevice != nil){
            var newFocusMode = AVCaptureFocusMode.ContinuousAutoFocus
            if((sender as! NSButton).state == NSOnState){
                newFocusMode = AVCaptureFocusMode.Locked
            }
            if(selectedDevice!.isFocusModeSupported(newFocusMode)){
                var error: NSError?
                if(selectedDevice!.lockForConfiguration(&error)){
                    selectedDevice!.focusMode = newFocusMode
                    selectedDevice!.unlockForConfiguration()
                } else {
                    let errorAlert = NSAlert(error: error!)
                    errorAlert.runModal()
                }
            }
        }
    }
    
}
