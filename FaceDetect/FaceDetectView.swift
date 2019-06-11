//
//  FaceDetectView.swift
//  FaceDetect
//
//  Created by sujian on 2019/6/6.
//  Copyright © 2019 sujian. All rights reserved.
//

import UIKit
import AVFoundation

protocol FaceDetectViewDelegate: class {
    func didDetected(_ faceDetectView: FaceDetectView)
}

class FaceDetectView: UIView {
    
    weak var delegate: FaceDetectViewDelegate?
    var completeHandle: (() -> Void)?
    var frontDetectionDone = false
    var backDetectionDone = false
    var position: AVCaptureDevice.Position  = .front
    
    lazy var session: AVCaptureSession = {
        let obj = AVCaptureSession()
        obj.sessionPreset = .high
        obj.automaticallyConfiguresApplicationAudioSession = false
        return obj
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let obj = AVCaptureVideoPreviewLayer(session: self.session)
        obj.videoGravity = .resizeAspectFill
        return obj
    }()
    
    lazy var faceDetector: CIDetector? = {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return detector
    }()
    
    convenience init(_ completeHandle:@escaping () -> Void) {
        self.init(frame: CGRect.zero)
        self.completeHandle = completeHandle
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    var currentDevice: AVCaptureDevice?
    var videoDeviceInput: AVCaptureDeviceInput?
    
    var imageView: UIImageView!
    func setupUI() {
        let devices = AVCaptureDevice.devices(for: .video)
        
        guard let device = devices.filter({ $0.position == position }).first else {
            return
            
        }
        currentDevice = device
        if let videoDeviceInput = try? AVCaptureDeviceInput(device: device) {
            self.videoDeviceInput = videoDeviceInput
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            }
        }
        
        let videoOutDataOutput = AVCaptureVideoDataOutput()
        videoOutDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
        videoOutDataOutput.alwaysDiscardsLateVideoFrames = true
        videoOutDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video queue"))
        if session.canAddOutput(videoOutDataOutput) {
            session.addOutput(videoOutDataOutput)
        }
        
       layer.addSublayer(previewLayer)
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        //imageView.backgroundColor = UIColor.green
        imageView.image = UIImage(named: "face")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        imageView.tintColor = UIColor.white
        addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 180).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func start() {
        session.startRunning()
    }
    
    func stop() {
        session.stopRunning()
    }
    
    func convertToBackCamera() {
        if currentDevice?.position == .front {
            if let input = session.inputs.first {
                session.removeInput(input)
                
            }
        }
    }
    
    func switchScene() {
        guard var position = videoDeviceInput?.device.position else { return }
        
        position = position == .front ? .back : .front
        self.position = position
        let devices = AVCaptureDevice.devices(for: .video)
        guard let device = devices.filter({ $0.position == position }).first else { return }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        if let input = videoDeviceInput {
            session.beginConfiguration()
            session.removeInput(input)
            session.addInput(videoInput)
            session.commitConfiguration()
            
            self.videoDeviceInput = videoInput
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        previewLayer.frame = bounds
        imageView?.center = center
    }
}

extension FaceDetectView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer){
            let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: attachments as? [CIImageOption : Any])
            
            
            if let faces = faceDetector?.features(in: ciImage), faces.count > 0 {
                
                if position == .front && !frontDetectionDone {
                    print("found face in front camera")
                    frontDetectionDone = true
                    self.session.stopRunning()
                    DispatchQueue.main.async {
                        self.imageView.tintColor = UIColor.green
                        delay(time: 1, work: {
                            self.imageView.tintColor = UIColor.white
                            self.switchScene()
                            self.session.startRunning()
                        })
                    }
                }
                
                if position == .back && !backDetectionDone {
                    print("found face in back camera")
                    backDetectionDone = true
                }
                
                if frontDetectionDone && backDetectionDone {
                    DispatchQueue.main.async {
                        self.delegate?.didDetected(self)
                        self.completeHandle?()
                    }
                }
            }
        }
    }
    
}
