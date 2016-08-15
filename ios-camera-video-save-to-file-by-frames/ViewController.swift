//
//  ViewController.swift
//  ios-camera-video-save-to-file-by-frames
//
//  Created by Zhaonan Li on 8/13/16.
//  Copyright © 2016 Zhaonan Li. All rights reserved.
//

import UIKit
import GLKit
import Photos
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var videoCaptureStatusLabel: UILabel!
    @IBOutlet weak var startRecordVideoBtn: UIButton!
    @IBOutlet weak var finishRecordVideoBtn: UIButton!

    lazy var glContext: EAGLContext = {
        let glContext = EAGLContext(API: .OpenGLES2)
        return glContext
    }()
    
    lazy var glView: GLKView = {
        let glView = GLKView(
        frame: CGRect(
            x: 0,
            y: 0,
            width: self.cameraView.bounds.width,
            height: self.cameraView.bounds.height),
        context: self.glContext)
        
        glView.bindDrawable()
        return glView
    }()
    
    lazy var ciContext: CIContext = {
        let ciContext = CIContext(EAGLContext: self.glContext)
        return ciContext
    }()
    
    lazy var cameraSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        return session
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCameraSession()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.cameraView.addSubview(self.glView)
        cameraSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startRecordVideo(sender: AnyObject) {
    }
    
    @IBAction func finishRecordVideo(sender: AnyObject) {
    }
    
    func setupCameraSession() {
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) as AVCaptureDevice
        
        do {
            self.cameraSession.beginConfiguration()
            
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            if self.cameraSession.canAddInput(deviceInput) {
                self.cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [
                (kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            if self.cameraSession.canAddOutput(dataOutput) {
                self.cameraSession.addOutput(dataOutput)
            }
            
            self.cameraSession.commitConfiguration()
            
            let videoStreamingQueue = dispatch_queue_create("com.somedomain.videoStreamingQueue", DISPATCH_QUEUE_SERIAL)
            dataOutput.setSampleBufferDelegate(self, queue: videoStreamingQueue)
            
        } catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    // Implement the delegate method
    // Interface: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Here we can collect the frames, and process them.
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let ciImage = CIImage(CVPixelBuffer: pixelBuffer!)
        
        // Rotate the ciImage 90 degrees to right.
        var affineTransform = CGAffineTransformMakeTranslation(ciImage.extent.width / 2, ciImage.extent.height / 2)
        affineTransform = CGAffineTransformRotate(affineTransform, CGFloat(-1 * M_PI_2))
        affineTransform = CGAffineTransformTranslate(affineTransform, -ciImage.extent.width / 2, -ciImage.extent.height / 2)
        
        let transformFilter = CIFilter(
            name: "CIAffineTransform",
            withInputParameters: [
                kCIInputImageKey: ciImage,
                kCIInputTransformKey: NSValue(CGAffineTransform: affineTransform)
            ]
        )
        
        let transformedCIImage = transformFilter!.outputImage!
        
        let scale = UIScreen.mainScreen().scale
        let previewImageFrame = CGRectMake(0, 0, self.cameraView.frame.width * scale, self.cameraView.frame.height * scale)
        
        // Draw the transformedCIImage sized by previewImageFrame on GLKView.
        if self.glContext != EAGLContext.currentContext() {
            EAGLContext.setCurrentContext(self.glContext)
        }
        self.glView.bindDrawable()
        self.ciContext.drawImage(transformedCIImage, inRect: previewImageFrame, fromRect: transformedCIImage.extent)
        self.glView.display()
        
    }
    
    // Implement the delegate method
    // Interface: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Here we can deal with the frames have been droped.
    }
}

