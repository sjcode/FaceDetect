//
//  ViewController.swift
//  FaceDetect
//
//  Created by sujian on 2019/6/6.
//  Copyright © 2019 sujian. All rights reserved.
//

import UIKit
import AVFoundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

enum PermissionType: String {
    case camera = "CAMERA_PERMISSION_ALERT_MESSAGE"
    case location = "LOCATIONS_PERMISSION_ALERT_MESSAGE"
    case microphone = "PERMISSION_MICROPHONE_ALERT_MESSAGE"
}

@available(iOS 10.0, *)
func presentPermission(type: PermissionType, parentViewController: UIViewController, cancelHandle: @escaping (UIAlertAction) -> Void) {
    
    let alert = UIAlertController(title: "FaceDetection", message: type.rawValue.localized, preferredStyle: .alert)
    let cancel = UIAlertAction(title: "ALERTCONTROLLER_CANCEL_TITLE".localized, style: .cancel, handler: cancelHandle)
    let action = UIAlertAction(title: "ALERTCONTROLLER_SETTING_TITLE".localized, style: .default, handler: { (action) in
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
    })
    alert.addAction(cancel)
    alert.addAction(action)
    
    parentViewController.present(alert, animated: true, completion: nil)
}

class ViewController: UIViewController {

    @IBOutlet weak var faceDetectView: FaceDetectView!{
        didSet {
            faceDetectView.delegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestAccessForMediaAccessAndCaptureVideo { [weak self] in
            self?.faceDetectView.start()
        }
    }

    func requestAccessForMediaAccessAndCaptureVideo(completeHandle: @escaping () -> Void) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .restricted:
            print("Restricted")
        case .denied:
            print("Denied")
        case .authorized:
            print("authorized")
            completeHandle()
        case .notDetermined:
            print("notDetermined")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                if let strongself = self {
                    if granted {
                        DispatchQueue.main.async {
                            completeHandle()
                        }
                    } else {
                        if #available(iOS 10.0, *) {
                            presentPermission(type: .camera, parentViewController: strongself, cancelHandle: { (action) in
                                //strongself.complete(strongself, state: .failure)
                            })
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }
        }
    }
    
}

extension ViewController: FaceDetectViewDelegate {
    func didDetected(_ faceDetectView: FaceDetectView) {
        let alert = UIAlertController(title: "FaceDetect", message: "all finish", preferredStyle: .alert)
        let action = UIAlertAction(title: "ok", style: .destructive) { (action) in
            
        }
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
}
