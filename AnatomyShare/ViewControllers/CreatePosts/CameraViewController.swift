//
//  CameraViewController.swift
//  AnatomyShare
//
//  Created by Dave on 12/29/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var captureSession: AVCaptureSession!
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var captureDeviceInputBack: AVCaptureDeviceInput!
    var captureDeviceInputFront: AVCaptureDeviceInput!
    var cameraState: Bool = true
    var flashOn: Bool = false
    var usingBackCamera: Bool = true
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var imageArea: UIView?
    
    // Variables that can be passed in from
    // drafts or edit VC
    var postDraft: PostDraft?
    var fromEditVC: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchToZoom(sender:)))
        previewView.addGestureRecognizer(pinchGesture)
        canAccessCamera()
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        // we want to "go back" to whatever VC we came from
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    @IBAction func changeFlash(_ sender: Any) {
        flashOn = !flashOn
        if flashOn {
            self.flashButton.setBackgroundImage(#imageLiteral(resourceName: "FlashOff"), for: .normal)
        }
        else {
            self.flashButton.setBackgroundImage(#imageLiteral(resourceName: "FlashOn"), for: .normal)
        }
        toggleTorch()
    }
    
    func toggleTorch() {
        if backCamera == nil {
            return
        }
        
        if backCamera.hasTorch {
            do {
                try backCamera.lockForConfiguration()
                
                if flashOn {
                    backCamera.torchMode = .on
                }
                else {
                    backCamera.torchMode = .off
                }
                
                backCamera.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        self.takePhotoButton.isEnabled = false
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                return
            }
            else {
                let settings = AVCapturePhotoSettings()
                let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first!
                let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                     kCVPixelBufferWidthKey as String: 160,
                                     kCVPixelBufferHeightKey as String: 160]
                settings.previewPhotoFormat = previewFormat
                self.cameraOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    // delgate method
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            DispatchQueue.main.async {
                var pictureOrientation: UIImageOrientation?
                
                switch UIDevice.current.orientation {
                case .portrait:
                    pictureOrientation = .right
                    break
                    
                case .portraitUpsideDown:
                    pictureOrientation = .left
                    break
                    
                case .landscapeLeft:
                    pictureOrientation = .up
                    break
                    
                case .landscapeRight:
                    pictureOrientation = .down
                    break
                    
                default:
                    pictureOrientation = .up
                    break
                }
                
                if let image = UIImage(data: imageData) {
                    if let croppedImage = self.cropImageToSquare(image: image) {
                        let imageTurned = UIImage(cgImage: croppedImage.cgImage!, scale: CGFloat(1.0), orientation: pictureOrientation!)
                        if self.postDraft == nil || !self.fromEditVC {
                            self.postDraft = PostDraft()
                            self.postDraft?.originalImage = imageTurned
                        }
                        // if we came from edit VC then a postDraft was passed in so we don't want to lose the existing data
                        else {
                            self.postDraft?.originalImage = imageTurned
                            self.postDraft?.originalImageURL = nil // this image does not have a url yet
                            self.postDraft?.annotatedImage = nil // remove the old image
                        }

                        self.captureSession.stopRunning()
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "toAnnotate", sender: nil)
                        }
                    }
                }
            }
        }
    }
    
    private func cropImageToSquare(image: UIImage) -> UIImage? {
        var croppedImage: UIImage?
        let originalHeight = image.size.height
        let originalWidth = image.size.width
        
        if originalHeight > originalWidth {
            // vertical image taken
            let cropAmount =  (originalHeight - originalWidth) / 2
            let rect = CGRect(x: cropAmount, y: 0, width: originalWidth, height: originalWidth)
            
            if let imageRef = image.cgImage?.cropping(to: rect) {
                croppedImage = UIImage(cgImage: imageRef, scale: CGFloat(1.0), orientation: image.imageOrientation)
            }
        }
        return croppedImage
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAnnotate" {
            if let controller = segue.destination as? AnnotateViewController {
                controller.postDraft = self.postDraft
                if self.fromEditVC {
                    controller.fromEditVC = true
                }
            }
        }
    }
    
    private func drawCropSquare() {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        
        if height > width {
            // portrait orientation
            // draw a square centered with size width x width
            let diff = (height - width) / 2
            let rect = CGRect(x: 0, y: diff, width: width, height: width)
            
            // check if there's already a crop square visible
            if self.imageArea != nil && self.imageArea!.isDescendant(of: self.previewView) {
                self.imageArea?.removeFromSuperview()
            }
            self.imageArea = ImageCropSquare(frame: rect)
            self.previewView.addSubview(self.imageArea!)
            self.imageArea?.isUserInteractionEnabled = false
        }
        else {
            // landscape orientation
            // draw a square centered with size height x height
            let diff = (width - height) / 2
            let rect = CGRect(x: diff, y: 0, width: height, height: height)
            
            if self.imageArea != nil && self.imageArea!.isDescendant(of: self.previewView) {
                self.imageArea?.removeFromSuperview()
            }
            self.imageArea = ImageCropSquare(frame: rect)
            self.previewView.addSubview(self.imageArea!)
            self.imageArea?.isUserInteractionEnabled = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPoint = touches.first
        let x = (touchPoint?.location(in: self.view).x)! / self.view.bounds.width
        let y = (touchPoint?.location(in: self.view).y)! / self.view.bounds.height
        
        let realX = (touchPoint?.location(in: self.view).x)!
        let realY = (touchPoint?.location(in: self.view).y)!
        
        let focusPoint = CGPoint(x: x, y: y)
        
        let k = DrawSquare(frame: CGRect(
            origin: CGPoint(x: realX - 75, y: realY - 75),
            size: CGSize(width: 150, height: 150)))
        
        if backCamera != nil {
            do {
                try backCamera.lockForConfiguration()
                self.previewView.addSubview(k)
            }
            catch {
                print("Can't lock back camera for configuration")
            }
            if backCamera.isFocusPointOfInterestSupported {
                backCamera.focusPointOfInterest = focusPoint
            }
            if backCamera.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                backCamera.focusMode = AVCaptureDevice.FocusMode.autoFocus
            }
            if backCamera.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose) {
                backCamera.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            }
            backCamera.unlockForConfiguration()
            
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            k.removeFromSuperview()
        }
    }
    
    @objc func pinchToZoom(sender: UIPinchGestureRecognizer) {
        if backCamera != nil {
            if sender.state == .changed {
                
                let maxZoomFactor = backCamera.activeFormat.videoMaxZoomFactor
                let pinchVelocityDividerFactor: CGFloat = 35.0
                
                do {
                    try backCamera.lockForConfiguration()
                    defer { backCamera.unlockForConfiguration() }
                    
                    let desiredZoomFactor = backCamera.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                    backCamera.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
    func canAccessCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                // print("can access camera")
                self.loadCamera()
                
            } else {
                self.askPermission()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        if self.previewLayer != nil {
            previewLayer.frame = self.view.bounds
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // ERRORS 1/13
        super.viewWillDisappear(animated)
        self.fromEditVC = false
    }
    
    func loadCamera() {
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            self.captureSession.startRunning()
            self.cameraOutput = AVCapturePhotoOutput()
            self.drawCropSquare()
            
            if self.captureSession.canSetSessionPreset(AVCaptureSession.Preset.high) {
                self.captureSession.sessionPreset = AVCaptureSession.Preset.high
            }
            
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
            
            for device in deviceDiscoverySession.devices {
                // only using the back camera
                // no one is going to take a selfie in the anatomy lab
                if (device as AnyObject).position == AVCaptureDevice.Position.back {
                    self.backCamera = device
                }
            }
            
            
            do {
                self.captureDeviceInputBack = try AVCaptureDeviceInput(device: self.backCamera)
            }
            catch {
                print("Error setting captureDeviceInputBack")
            }
            
            if (self.captureSession.canAddInput(self.captureDeviceInputBack)) {
                self.captureSession.addInput(self.captureDeviceInputBack)
                if (self.captureSession.canAddOutput(self.cameraOutput)) {
                    self.captureSession.addOutput(self.cameraOutput)
                    
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.previewLayer.frame = self.previewView.layer.bounds
                    self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    self.previewView.layer.insertSublayer(self.previewLayer, at: 0)
                    self.fixCameraOrientation()
                }
            }
            else {
                print("can't add input")
            }
        }
    }
    
    private func fixCameraOrientation() {
        DispatchQueue.main.async {
            if let connection =  self.previewLayer?.connection  {
                let currentDevice: UIDevice = UIDevice.current
                let orientation: UIDeviceOrientation = currentDevice.orientation
                let previewLayerConnection : AVCaptureConnection = connection
                
                if (previewLayerConnection.isVideoOrientationSupported) {
                    switch (orientation) {
                    case .portrait:
                        previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                        break
                    case .landscapeRight:
                        previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                        break
                    case .landscapeLeft:
                        previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                        break
                    case .portraitUpsideDown:
                        previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                        break
                    default:
                        previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                        break
                    }
                }
            }
        }
    }
    
    // Marker: Handle Orientation change
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.fixCameraOrientation()
        self.drawCropSquare()
    }
    
    
    
    private func displayBackCamera() {
        DispatchQueue.main.async {
            if self.captureSession.canAddInput(self.captureDeviceInputBack) {
                self.captureSession.addInput(self.captureDeviceInputBack)
            }
            else {
                self.captureSession.removeInput(self.captureDeviceInputFront)
                if self.captureSession.canAddInput(self.captureDeviceInputBack) {
                    self.captureSession.addInput(self.captureDeviceInputBack)
                }
            }
        }
    }
    
    func askPermission() {
        let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if cameraPermissionStatus != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                [weak self]
                (granted :Bool) -> Void in
                
                if granted == true {
                    // User granted
                    DispatchQueue.main.async(){
                        self?.loadCamera()
                    }
                }
                else {
                    // User Rejected
                    DispatchQueue.main.async(){
                        let alert = UIAlertController(title: "Camera Access Denied" , message: "Without permission to use the camera this app won't be very useful. You can grant access at anytime in settings.", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alert.addAction(action)
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            });
        }
        else {
            loadCamera()
        }
    }
    
    @IBAction func photoLibraryPressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toDrafts", sender: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if !hidden {
                self.navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
        if self.captureSession != nil && !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
        if UIDevice.current.orientation != .portrait {
            self.fixCameraOrientation()
        }
        self.takePhotoButton.isEnabled = true
    }
}
