//
//  AnnotateViewController.swift
//  AnatomyShare
//
//  Created by Dave on 12/29/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import AVKit
import ColorSlider
import CoreData
import Photos

class AnnotateViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    // Draft that is passed in
    var postDraft: PostDraft!
    
    // Needed to access coreData
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    // Flag to determine if the draft was loaded from a previous save
    var isSavedDraft: Bool = false
    
    // Buttons
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    
    // UISlider
    @IBOutlet weak var slider: UISlider!
    
    // ColorSlider
    var colorSlider: ColorSlider!
    
    // TextView Wrappers
    @IBOutlet weak var wrapperOne: UIView!
    @IBOutlet weak var wrapperTwo: UIView!
    @IBOutlet weak var wrapperThree: UIView!
    @IBOutlet weak var wrapperFour: UIView!
    @IBOutlet weak var wrapperFive: UIView!
    
    
    // TextView Wrapper Constraints
    @IBOutlet weak var wrapperOneCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperOneCenterY: NSLayoutConstraint!
    @IBOutlet weak var wrapperTwoCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperTwoCenterY: NSLayoutConstraint!
    @IBOutlet weak var wrapperThreeCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperThreeCenterY: NSLayoutConstraint!
    @IBOutlet weak var wrapperFourCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperFourCenterY: NSLayoutConstraint!
    @IBOutlet weak var wrapperFiveCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperFiveCenterY: NSLayoutConstraint!
    
    // Values to reset textview to the center of the view
    var centerX: CGFloat?
    var centerY: CGFloat?
    
    // TextView font size starting value to reset
    var startingFontSize: CGFloat?
    
    // TextViews
    @IBOutlet weak var tvOne: UITextView!
    @IBOutlet weak var tvTwo: UITextView!
    @IBOutlet weak var tvThree: UITextView!
    @IBOutlet weak var tvFour: UITextView!
    @IBOutlet weak var tvFive: UITextView!
    
    var activeTextView = UITextView()
    var textColor = UIColor.black
    
    // Drawing
    var topImageView = UIImageView()
    
    var drawing: Bool! {
        didSet {
            self.changePencilImage()
        }
    }
    
    var lastPoint = CGPoint.zero
    var fromPoint = CGPoint()
    var toPoint = CGPoint()
    var brushWidth: CGFloat = 4.0
    var opacity: CGFloat = 1.0
    var strokeColor: CGColor = UIColor.red.cgColor
    let screenSize = UIScreen.main.bounds
    var previousDrawings = [UIImage]()
    
    // Flip images if needed
    var showingAnnotatedImage: Bool! {
        didSet {
            self.switchImages()
        }
    }
    
    // Editing Picture
    var fromEditVC: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Notification to call overwriteDraft from PostDetails
        NotificationCenter.default.addObserver(self, selector: #selector(self.saveDraftFromPostDetails(_:)), name: NSNotification.Name(rawValue: "saveDraftFromPostDetails"), object: nil)
        
        initialize()
    }
    
    @objc func saveDraftFromPostDetails(_ notification: NSNotification) {
        print(notification.userInfo ?? "empty")
        if let dict = notification.userInfo as NSDictionary? {
            print("dict")
            if let draft = dict["draft"] as? PostDraft {
                print("postDraft")
                self.overwriteSavedDraft(postDraft: draft)
            }
        }
    }
    
    // MARKER: COLOR SLIDER!
    private func createColorSlider() {
        let previewView = DefaultPreviewView()
        previewView.side = .left
        previewView.animationDuration = 0.2
        previewView.offsetAmount = 50
        
        colorSlider = ColorSlider(orientation: .vertical, previewView: previewView)
        colorSlider.frame = CGRect(x: 100, y: 150, width: 12, height: 300)
        colorSlider.translatesAutoresizingMaskIntoConstraints = false
        colorSlider.addTarget(self, action: #selector(self.changedColor(_:)), for: .valueChanged)
        imageView.addSubview(colorSlider)
        colorSlider.tag = 999
        
        // Constraints for colorSlider
        // 1. Center it with the draw button
        // 2. Add some space at the top
        // 3. Give it a fixed size
        colorSlider.widthAnchor.constraint(equalToConstant: 12).isActive = true
        colorSlider.heightAnchor.constraint(equalToConstant: 290).isActive = true
        NSLayoutConstraint(item: colorSlider, attribute: .centerX, relatedBy: NSLayoutRelation.equal, toItem: drawButton, attribute: .centerX, multiplier: 1.0, constant: 1.0).isActive = true
        NSLayoutConstraint(item: colorSlider, attribute: .top, relatedBy: .equal, toItem: self.drawButton, attribute: .bottom, multiplier: 1.0, constant: 40.0).isActive = true
    }
    
    @objc func changedColor(_ slider: ColorSlider) {
        if !drawing {
            activeTextView.textColor = slider.color
        }
        strokeColor = slider.color.cgColor
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if tvOne.isFirstResponder {
            tvOne.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else if tvTwo.isFirstResponder {
            tvTwo.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else if tvThree.isFirstResponder {
            tvThree.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else if tvFour.isFirstResponder {
            tvFour.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else if tvFive.isFirstResponder {
            tvFive.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else {
            pictureImageView.alpha = CGFloat(slider.value)
        }
    }
    
    @IBAction func drawPressed(_ sender: Any) {
        drawing = !drawing
        trashButton.isHidden = true
        undoButton.isHidden = !undoButton.isHidden
        
        if !wrapperOne.isHidden {
            wrapperOne.isUserInteractionEnabled = !drawing
        }
        if !wrapperTwo.isHidden {
            wrapperTwo.isUserInteractionEnabled = !drawing
        }
        if !wrapperThree.isHidden {
            wrapperThree.isUserInteractionEnabled = !drawing
        }
        if !wrapperFour.isHidden {
            wrapperFour.isUserInteractionEnabled = !drawing
        }
        if !wrapperFive.isHidden {
            wrapperFive.isUserInteractionEnabled = !drawing
        }
    }
    
    
    // Flip the drawbutton image so the user knows if they are drawing
    private func changePencilImage() {
        if drawing {
            drawButton.setBackgroundImage(#imageLiteral(resourceName: "GrayPencil"), for: .normal)
        }
        else {
            drawButton.setBackgroundImage(#imageLiteral(resourceName: "Pencil"), for: .normal)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing {
            if let touch = touches.first {
                lastPoint = touch.preciseLocation(in: self.pictureImageView)
            }
        }
        else {
            slider.isHidden = true
            if tvOne.isFirstResponder {
                tvOne.resignFirstResponder()
            }
            else if tvTwo.isFirstResponder {
                tvTwo.resignFirstResponder()
            }
            else if tvThree.isFirstResponder {
                tvThree.resignFirstResponder()
            }
            else if tvFour.isFirstResponder {
                tvFour.resignFirstResponder()
            }
            else if tvFive.isFirstResponder {
                tvFive.resignFirstResponder()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing {
            if let touch = touches.first {
                let currentPoint = touch.preciseLocation(in: self.pictureImageView)
                drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
                lastPoint = currentPoint
            }
        }
    }
    
    private func shouldDrawLine(start: CGPoint, end: CGPoint) -> Bool {
        if self.topImageView.frame.contains(start) && topImageView.frame.contains(end) {
            return true
        }
        return false
    }
    
    // all drawing has to occur on an image without an applied filter (i.e. the original image)
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        if shouldDrawLine(start: fromPoint, end: toPoint) {
            UIGraphicsBeginImageContextWithOptions(topImageView.frame.size, false, 0.0)
            topImageView.image?.draw(in: CGRect(x: 0, y: 0, width: topImageView.frame.size.width, height: topImageView.frame.size.height))
            
            let context = UIGraphicsGetCurrentContext()
            context?.move(to: fromPoint)
            context?.addLine(to: toPoint)
            context?.setLineCap(CGLineCap.round)
            context?.setLineWidth(brushWidth)
            context?.setStrokeColor(strokeColor)
            context?.setBlendMode(CGBlendMode.normal)
            context?.strokePath()
            
            topImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            topImageView.alpha = opacity
            UIGraphicsEndImageContext()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing {
            if let touch = touches.first {
                if self.imageView.frame.contains(touch.preciseLocation(in: self.pictureImageView)) {
                    if let drawing = topImageView.image {
                        previousDrawings.append(drawing)
                    }
                }
            }
        }
    }
    
    
    @IBAction func undoPressed(_ sender: Any) {
        if !previousDrawings.isEmpty {
            previousDrawings.remove(at: previousDrawings.count - 1)
            if let lastDrawing = previousDrawings.last {
                DispatchQueue.main.async {
                    self.topImageView.image = lastDrawing
                }
            }
            else {
                DispatchQueue.main.async {
                    self.topImageView.image = nil
                }
            }
        }
    }
    
    
    @IBAction func addText(_ sender: Any) {
        DispatchQueue.main.async {
            self.drawing = false
            self.undoButton.isHidden = true
            self.trashButton.isHidden = false
            
            if self.wrapperOne.isHidden {
                self.wrapperOne.isHidden = false
                // self.tvOne.isHidden = false
                self.wrapperOne.isUserInteractionEnabled = true
                self.tvOne.becomeFirstResponder()
                return
                
            }
            else if self.wrapperTwo.isHidden {
                self.wrapperTwo.isHidden = false
                // self.tvTwo.isHidden = false
                self.wrapperTwo.isUserInteractionEnabled = true
                self.tvTwo.becomeFirstResponder()
                
            }
            else if self.wrapperThree.isHidden {
                self.wrapperThree.isHidden = false
                // self.tvThree.isHidden = false
                self.wrapperThree.isUserInteractionEnabled = true
                self.tvThree.becomeFirstResponder()
                
            }
            else if self.wrapperFour.isHidden {
                self.wrapperFour.isHidden = false
                // self.tvFour.isHidden = false
                self.wrapperFour.isUserInteractionEnabled = true
                self.tvFour.becomeFirstResponder()
                
            }
            else if self.wrapperFive.isHidden {
                self.wrapperFive.isHidden = false
                // self.tvFive.isHidden = false
                self.wrapperFive.isUserInteractionEnabled = true
                self.tvFive.becomeFirstResponder()
                
            }
        }
    }
    
    // When the trash is pressed a textview is hidden from the screen
    // it's position is reset to the center
    // font size is reset to the starting size
    // and any rotation is also removed
    @IBAction func trashPressed(_ sender: Any) {
        if activeTextView.tag == 11 {
            tvOne.text = ""
            wrapperOne.isHidden = true
            wrapperOne.transform = CGAffineTransform(rotationAngle: 0)
            
            // if these values are nil the textview wasn't moved
            if let x = self.centerX, let y = self.centerY {
                wrapperOneCenterX.constant = x
                wrapperOneCenterY.constant = y
            }
            if let size = startingFontSize {
                self.tvOne.font = UIFont.systemFont(ofSize: size)
            }
        }
        else if activeTextView.tag == 12 {
            tvTwo.text = ""
            wrapperTwo.isHidden = true
            wrapperTwo.transform = CGAffineTransform(rotationAngle: 0)
            
            if let x = self.centerX, let y = self.centerY {
                wrapperTwoCenterX.constant = x
                wrapperTwoCenterY.constant = y
            }
            if let size = startingFontSize {
                self.tvTwo.font = UIFont.systemFont(ofSize: size)
            }
            
        }
        else if activeTextView.tag == 13 {
            tvThree.text = ""
            wrapperThree.isHidden = true
            wrapperThree.transform = CGAffineTransform(rotationAngle: 0)
            
            if let x = self.centerX, let y = self.centerY {
                wrapperThreeCenterX.constant = x
                wrapperThreeCenterY.constant = y
            }
            if let size = startingFontSize {
                self.tvThree.font = UIFont.systemFont(ofSize: size)
            }
        }
        else if activeTextView.tag == 14 {
            tvFour.text = ""
            wrapperFour.isHidden = true
            wrapperFour.transform = CGAffineTransform(rotationAngle: 0)
            
            if let x = self.centerX, let y = self.centerY {
                wrapperFourCenterX.constant = x
                wrapperFourCenterY.constant = y
            }
            if let size = startingFontSize {
                self.tvFour.font = UIFont.systemFont(ofSize: size)
            }
        }
        else if activeTextView.tag == 15 {
            tvFive.text = ""
            wrapperFive.isHidden = true
            wrapperFive.transform = CGAffineTransform(rotationAngle: 0)
            
            if let x = self.centerX, let y = self.centerY {
                wrapperFiveCenterX.constant = x
                wrapperFiveCenterY.constant = y
            }
            if let size = startingFontSize {
                self.tvFive.font = UIFont.systemFont(ofSize: size)
            }
        }
    }
    
    // MARKER: GESTURE RECOGNIZERS
    func createGestureRecognizers() {
        // Pan Gestures
        let wrapperOnePanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperOne.addGestureRecognizer(wrapperOnePanGesture)
        wrapperOnePanGesture.delegate = self
        
        let wrapperTwoPanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperTwo.addGestureRecognizer(wrapperTwoPanGesture)
        wrapperTwoPanGesture.delegate = self
        
        let wrapperThreePanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperThree.addGestureRecognizer(wrapperThreePanGesture)
        wrapperThreePanGesture.delegate = self
        
        let wrapperFourPanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperFour.addGestureRecognizer(wrapperFourPanGesture)
        wrapperFourPanGesture.delegate = self
        
        let wrapperFivePanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperFive.addGestureRecognizer(wrapperFivePanGesture)
        wrapperFivePanGesture.delegate = self
        
        
        // Pinch Gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        imageView.addGestureRecognizer(pinchGesture)
        imageView.isUserInteractionEnabled = true
        pinchGesture.delegate = self
        
        let wrapperOnePinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperOne.addGestureRecognizer(wrapperOnePinchGesture)
        wrapperOnePinchGesture.delegate = self
        
        let wrapperTwoPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperTwo.addGestureRecognizer(wrapperTwoPinchGesture)
        wrapperTwoPinchGesture.delegate = self
        
        let wrapperThreePinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperThree.addGestureRecognizer(wrapperThreePinchGesture)
        wrapperThreePinchGesture.delegate = self
        
        let wrapperFourPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperFour.addGestureRecognizer(wrapperFourPinchGesture)
        wrapperFourPinchGesture.delegate = self
        
        let wrapperFivePinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperFive.addGestureRecognizer(wrapperFivePinchGesture)
        wrapperFivePinchGesture.delegate = self
        
        // Rotate Gestures
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        imageView.addGestureRecognizer(rotateGesture)
        rotateGesture.delegate = self
        
        let wrapperOneRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperOne.addGestureRecognizer(wrapperOneRotate)
        wrapperOneRotate.delegate = self
        
        let wrapperTwoRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperTwo.addGestureRecognizer(wrapperTwoRotate)
        wrapperTwoRotate.delegate = self
        
        let wrapperThreeRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperThree.addGestureRecognizer(wrapperThreeRotate)
        wrapperThreeRotate.delegate = self
        
        let wrapperFourRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperFour.addGestureRecognizer(wrapperFourRotate)
        wrapperFourRotate.delegate = self
        
        let wrapperFiveRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperFive.addGestureRecognizer(wrapperFiveRotate)
        wrapperFiveRotate.delegate = self
    }
    
    @objc func handleRotate(recognizer: UIRotationGestureRecognizer) {
        var lastRotation: CGFloat = 0
        let location = recognizer.location(in: recognizer.view)
        let rotation = lastRotation + recognizer.rotation
        
        if recognizer.state == .ended {
            lastRotation = 0.0
        }
        
        // Rotate detected on imageView
        if wrapperOne.frame.contains(location) {
            wrapperOne.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if wrapperTwo.frame.contains(location) {
            wrapperTwo.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if wrapperThree.frame.contains(location) {
            wrapperThree.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if wrapperFour.frame.contains(location) {
            wrapperFour.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if wrapperFive.frame.contains(location) {
            wrapperFive.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if let view = recognizer.view {
            if view.tag < 37 {
                view.transform = CGAffineTransform(rotationAngle: rotation)
            }
        }
    }
    
    // HANDLE PINCH GESTURES ON TEXT FIELDS
    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        let location = recognizer.location(in: recognizer.view)
        let pinchScale: CGFloat = recognizer.scale
        
        // PINCH DETECTED ON IMAGEVIEW
        if wrapperOne.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: tvOne)
        }
        else if wrapperTwo.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: tvTwo)
        }
        else if wrapperThree.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: tvThree)
        }
        else if wrapperFour.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: tvFour)
        }
        else if wrapperFive.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: tvFive)
        }
            
            // PINCH DETECTED IN TEXTVIEW
        else if let view = recognizer.view {
            adjustTextViewFontSize(pinchScale: pinchScale, view: view)
        }
        recognizer.scale = 1.0
    }
    
    
    
    // FUNCTION TO DETERMINE HOW TO SCALE THE FONT SIZE OF A TEXTVIEW BASED ON A PINCH GESTURE
    private func adjustTextViewFontSize(pinchScale: CGFloat, view: UIView) {
        let minFontSize: CGFloat = 15
        let maxFontSize: CGFloat = 120
        
        if let textview = view as? UITextView {
            if let currentFontSize = textview.font?.pointSize {
                let size = CGFloat(currentFontSize * pinchScale)
                if size > maxFontSize {
                    textview.font = UIFont.systemFont(ofSize: maxFontSize)
                }
                else if size < minFontSize {
                    textview.font = UIFont.systemFont(ofSize: minFontSize)
                }
                else {
                    textview.font = UIFont.systemFont(ofSize: CGFloat(currentFontSize * pinchScale))
                }
            }
        }
    }
    
    // TEXTFIELD PAN GESTURES HANDLED HERE
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        if let uiView = recognizer.view {
            
            if self.centerX == nil || self.centerY == nil {
                // save the original values to reset the position
                self.centerX = wrapperOneCenterX.constant
                self.centerY = wrapperOneCenterY.constant
            }
            
            var translation = recognizer.translation(in: self.view)
            
            var recognizerFrame = recognizer.view?.frame
            recognizerFrame?.origin.x += translation.x
            recognizerFrame?.origin.y += translation.y
            
            let width = UIScreen.main.bounds.width
            let height = UIScreen.main.bounds.height
            
            if let frame = recognizerFrame {
                if height > width {
                    // portrait orientation
                    // draw a square centered with size width x width
                    let diff = (height - width) / 2
                    let rect = CGRect(x: 0, y: diff, width: width, height: width)
                    
                    if !rect.contains(frame) {
                        return
                    }
                }
                else {
                    // landscape orientation
                    // draw a square centered with size height x height
                    let diff = (width - height) / 2
                    let rect = CGRect(x: diff, y: 0, width: height, height: height)
                    if !rect.contains(frame) {
                        return
                    }
                }
            }
            else {
                return
            }
            
            translation.x = max(translation.x, imageView.frame.minX - uiView.frame.minX)
            translation.x = min(translation.x, imageView.frame.maxX - uiView.frame.maxX)
            translation.y = max(translation.y, imageView.frame.minY - uiView.frame.minY)
            translation.y = min(translation.y, imageView.frame.maxY - uiView.frame.maxY)
            
            if let view = recognizer.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
                switch recognizer.state {
                case .changed:
                    if uiView.tag == 1 {
                        // qwer
                        wrapperOneCenterX.constant = wrapperOneCenterX.constant + translation.x
                        wrapperOneCenterY.constant = wrapperOneCenterY.constant + translation.y
                    }
                    else if uiView.tag == 2 {
                        wrapperTwoCenterX.constant = wrapperTwoCenterX.constant + translation.x
                        wrapperTwoCenterY.constant = wrapperTwoCenterY.constant + translation.y
                    }
                    else if uiView.tag == 3 {
                        wrapperThreeCenterX.constant = wrapperThreeCenterX.constant + translation.x
                        wrapperThreeCenterY.constant = wrapperThreeCenterY.constant + translation.y
                    }
                    else if uiView.tag == 4 {
                        wrapperFourCenterX.constant = wrapperFourCenterX.constant + translation.x
                        wrapperFourCenterY.constant = wrapperFourCenterY.constant + translation.y
                    }
                    else if uiView.tag == 5 {
                        wrapperFiveCenterX.constant = wrapperFiveCenterX.constant + translation.x
                        wrapperFiveCenterY.constant = wrapperFiveCenterY.constant + translation.y
                    }
                default:
                    break
                }
                recognizer.setTranslation(CGPoint.zero , in: view)
            }
        }
    }
    
    // ALLOWS MULTIPLE GESTURES AT THE SAME TIME
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // prevent pinch and swipe from firing at the same time
        if (gestureRecognizer is UIPinchGestureRecognizer || gestureRecognizer is UISwipeGestureRecognizer) && (otherGestureRecognizer is UIPinchGestureRecognizer || otherGestureRecognizer is UISwipeGestureRecognizer) {
            return false
        }
        return true
    }
    
    // Textview Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Keep track of the last touched textview
        self.activeTextView = textView
        // the position of the slider should also be set to the current alpha value
        // of that textView
        if let value = self.activeTextView.backgroundColor?.cgColor.alpha {
            self.slider.value = Float(value)
        }
        // if a textview is touched and becomes first responder than
        // the trash icon should be displayed
        self.trashButton.isHidden = false
        self.slider.isHidden = false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // save the text to the correct spot in the postDraft
        guard let text = textView.text else { return }
        
        switch textView.tag {
        case 11:
            self.postDraft.textOne = text
        case 12:
            self.postDraft.textTwo = text
        case 13:
            self.postDraft.textThree = text
        case 14:
            self.postDraft.textFour = text
        case 15:
            self.postDraft.textFive = text
        default:
            return
        }
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // This method should save both the original image
    // and the annotated (if created)
    @IBAction func savePressed(_ sender: Any) {
        if self.isSavedDraft && !self.isAnnotated() {
            // Previously saved draft where nothing was changed
            // so just return
            self.showImageSavedAlert()
            return
        }
        // Overwritting a previously saved draft
        else if self.isAnnotated() && self.isSavedDraft {
            // we want to update the annotated image saved to disk
            // and the path stored in core data
            DispatchQueue.main.async {
                if let annotatedImage = self.captureScreen() {
                    self.postDraft.annotatedImage = annotatedImage
                    self.overwriteSavedDraft(postDraft: self.postDraft)
                }
            }
        }
        // Saving a new draft
        else if !isSavedDraft && self.isAnnotated() {
            DispatchQueue.main.async {
                if let image = self.pictureImageView.image?.correctlyOrientedImage(), let annotatedImage = self.captureScreen() {
                    self.postDraft.originalImage = image
                    self.postDraft.annotatedImage = annotatedImage
                    self.saveDraft(postDraft: self.postDraft)
                }
            }
        }
        // Saving only the original photo
        else if !isSavedDraft && !isAnnotated() {
            self.saveOriginalImageOnly()
            self.isSavedDraft = true
        }
        else {
            self.showImageSavedAlert()
        }
    }
    
    // This method updates an existing draft to reflect new user changes
    // new changes could be the addition or update of an annotated image
    // or the advent of additional data such as table, category, region, or text.
    //
    // The original image cannot be changed by the user so we don't have to worry
    // about changes to that.
    func overwriteSavedDraft(postDraft: PostDraft) {
        CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
        DispatchQueue.global(qos: .utility).async {
            if let newImageData = UIImagePNGRepresentation(postDraft.annotatedImage!) {
                // delete the old image and save the new image
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                if let folderName = postDraft.folderName {
                    print("folderName: \(folderName)")
                    let folderPath = documentsURL.appendingPathComponent("/Drafts/\(folderName)")
                    let time = Date().millisecondsSince1970
                    let fileNameIfNeeded = String("\(time).png")
                    // if there's an existing annotated image then we overwrite that file
                    // however, if there isn't an annotated image we need to generate that fileName
                    let fileName = postDraft.annotatedImageName ?? fileNameIfNeeded
                    let fullPath = folderPath.appendingPathComponent(fileName)
                    // remove image at /Documents/Drafts/fileName
                    if fileManager.fileExists(atPath: fullPath.path) {
                        do {
                            try fileManager.removeItem(at: fullPath)
                            try newImageData.write(to: fullPath, options: .atomic)
                            
                            // update the record in core data
                            self.saveDraftToCoreData(postDraft: postDraft, newRecord: false)
                            
                            // clear the loaded drafts so the new update will be visible
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearLoadedDrafts"), object: nil)
                            
                            // let the user know everything worked
                            self.showImageSavedAlert()
                        }
                        catch {
                            print(error.localizedDescription)
                            self.showImageNotSavedAlert()
                            return
                        }
                    }
                    else {
                        // no file there so just write the new image
                        do {
                            try newImageData.write(to: fullPath, options: .atomic)
                            // update the record in core data
                            self.saveDraftToCoreData(postDraft: postDraft, newRecord: false)
                            
                            // clear the loaded drafts so the new update will be visible
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearLoadedDrafts"), object: nil)
                            
                            // let the user know everything worked
                            self.showImageSavedAlert()
                        }
                        catch {
                            print(error.localizedDescription)
                            self.showImageNotSavedAlert()
                            return
                        }
                    }
                }
                else {
                    // Folder DNE
                    // Therefore the post has never been saved before
                    self.saveDraft(postDraft: postDraft)
                }
            }
        }
    }
    
    func saveOriginalImageOnly() {
        CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let time = Date().millisecondsSince1970
            let folderName = String("\(time)")
            let fileName = String("\(time).png")
            
            self.postDraft.folderName = folderName
            self.postDraft.originalImageName = fileName
            
            // Save to /Documents/Drafts/time
            let folderPath = documentsURL.appendingPathComponent("/Drafts/\(folderName)")
            
            // create the folder needed to store the draft
            if !fileManager.fileExists(atPath: folderPath.path) {
                do {
                    // withIntermediate will create the "Drafts" folder if needed
                    try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print(error.localizedDescription)
                    self.showImageNotSavedAlert()
                    return
                }
            }
            else {
                self.showImageNotSavedAlert()
                return
            }
            DispatchQueue.main.async {
                do {
                    if let image = self.pictureImageView.image?.correctlyOrientedImage() {
                        if let imageData = UIImagePNGRepresentation(image) {
                            // write the image to the folder we just created
                            if !fileManager.fileExists(atPath: folderPath.appendingPathComponent(fileName).path) {
                                try imageData.write(to: folderPath.appendingPathComponent(fileName), options: .atomic)
                                self.saveImageToCoreData(folderName: folderName, imageName: fileName)
                                self.showImageSavedAlert()
                            }
                            else {
                                self.showImageNotSavedAlert()
                            }
                        }
                    }
                    else {
                        self.showImageNotSavedAlert()
                    }
                }
                catch {
                    self.showImageNotSavedAlert()
                }
            }
        }
    }

    // Function to save new drafts only!
    // This is called when a user has an original photo
    // and they have annotated it as well
    func saveDraft(postDraft: PostDraft) {
        CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
        DispatchQueue.global(qos: .utility).async {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // use the time to name the folder so that it's always unique
            let time = Date().millisecondsSince1970
            let timeTwo = time + 1
            let folderName = String("\(time)")
            let fileName = String("\(time).png")
            let fileNameTwo = String("\(timeTwo).png")
            
            postDraft.folderName = folderName
            postDraft.originalImageName = fileName
            postDraft.annotatedImageName = fileNameTwo
            
            // save to /Documents/Drafts/time/time.png
            let folderPath = documentsURL.appendingPathComponent("/Drafts/\(folderName)")
            
            // create the folders needed to store the drafts
            if !fileManager.fileExists(atPath: folderPath.path) {
                do {
                    // withIntermediate will create the "Drafts" folder if needed
                    try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print(error.localizedDescription)
                    self.showImageNotSavedAlert()
                    return
                }
            }
            else {
                self.showImageNotSavedAlert()
                return
            }
            do {
                if let original = postDraft.originalImage, let annotated = postDraft.annotatedImage {
                    if let imageData = UIImagePNGRepresentation(original), let annotatedData = UIImagePNGRepresentation(annotated) {
                        
                        // Make sure all file paths are safe to write to
                        if fileManager.fileExists(atPath: folderPath.appendingPathComponent(fileName).path) || fileManager.fileExists(atPath: folderPath.appendingPathComponent(fileNameTwo).path) {
                            self.showImageNotSavedAlert()
                            return
                        }
                        
                        // write both images to the annotated path
                        try imageData.write(to: folderPath.appendingPathComponent(fileName), options: .atomic)
                        try annotatedData.write(to: folderPath.appendingPathComponent(fileNameTwo), options: .atomic)
                        
                        // save path to annotated image folder to core data
                        self.saveDraftToCoreData(postDraft: postDraft, newRecord: true)
                        
                        // let the user know everything worked
                        self.showImageSavedAlert()
                    }
                }
                else {
                    self.showImageNotSavedAlert()
                    return
                }
            }
            catch {
                print(error.localizedDescription)
                self.showImageNotSavedAlert()
            }
        }
    }
    
    func saveDraftToCoreData(postDraft: PostDraft, newRecord: Bool) {
        DispatchQueue.global(qos: .utility).async {
            if let appDel = self.appDelegate {
                let container = appDel.persistentContainer
                let context = container.viewContext
                
                if let folderName = postDraft.folderName {
                    if !newRecord {
                        let fetchRequest = NSFetchRequest<Draft>(entityName: "Draft")
                        let condition = NSPredicate(format: "folderName == \(folderName)")
                        fetchRequest.predicate = condition
                        
                        do {
                            let results = try context.fetch(fetchRequest)
                            if results.count == 1 {
                                let entity = results[0]
                                entity.folderName = folderName
                                entity.originalImageName = postDraft.originalImageName
                                entity.annotatedImageName = postDraft.annotatedImageName
                                entity.table = postDraft.table
                                entity.category = postDraft.category
                                entity.region = postDraft.region
                                entity.postDescription = postDraft.text
                                entity.textOne = postDraft.textOne
                                entity.textTwo = postDraft.textTwo
                                entity.textThree = postDraft.textThree
                                entity.textFour = postDraft.textFour
                                entity.textFive = postDraft.textFive
                                appDel.saveContext()
                                
                            }
                        }
                        catch {
                            print(error.localizedDescription)
                        }
                    }
                    else {
                        let entity = Draft(context: context)
                        entity.folderName = folderName
                        entity.originalImageName = postDraft.originalImageName
                        entity.annotatedImageName = postDraft.annotatedImageName
                        entity.table = postDraft.table
                        entity.category = postDraft.category
                        entity.region = postDraft.region
                        entity.postDescription = postDraft.text
                        entity.textOne = postDraft.textOne
                        entity.textTwo = postDraft.textTwo
                        entity.textThree = postDraft.textThree
                        entity.textFour = postDraft.textFour
                        entity.textFive = postDraft.textFive
                        appDel.saveContext()
                    }
                }
            }
        }
    }
    
    // Save just an original image to coreData
    func saveImageToCoreData(folderName: String, imageName: String) {
        DispatchQueue.global(qos: .utility).async {
            if let appDel = self.appDelegate {
                let container = appDel.persistentContainer
                let context = container.viewContext
                let entity = Draft(context: context)
                entity.folderName = folderName
                entity.originalImageName = imageName
                appDel.saveContext()
            }
        }
    }
    
    private func isAnnotated() -> Bool {
        if !wrapperOne.isHidden || !wrapperTwo.isHidden || !wrapperThree.isHidden ||
            !wrapperFour.isHidden || !wrapperFive.isHidden || topImageView.image != nil  {
            return true
        }
        return false
    }
    
    func showImageSavedAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
            let ac = UIAlertController(title: "Draft Saved", message: "Your draft was successfully saved", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            if let topController = UIApplication.topViewController() {
                topController.present(ac, animated: true)
            }
        }
    }
    
    func showImageNotSavedAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
            let ac = UIAlertController(title: "Error!", message: "Your draft could not be saved. Please try again", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            if let topController = UIApplication.topViewController() {
                topController.present(ac, animated: true)
            }
        }
    }
    
    // MARKER: CAPTURING THE SCREEN
    private func captureScreen() -> UIImage? {
        // Check to see what view aren't hidden
        // If a view isn't hidden then we add it to the screenshot
        
        // Add top imageview first because that holds the "drawing"
        // we want any text that the user wrote to appear
        // on top of the "drawing"
        if self.topImageView.image != nil {
            self.pictureImageView.addSubview(self.topImageView)
        }
        if !self.wrapperOne.isHidden {
            self.pictureImageView.addSubview(self.wrapperOne)
        }
        if !self.wrapperTwo.isHidden {
            self.pictureImageView.addSubview(self.wrapperTwo)
        }
        if !self.wrapperThree.isHidden {
            self.pictureImageView.addSubview(self.wrapperThree)
        }
        if !self.wrapperFour.isHidden {
            self.pictureImageView.addSubview(self.wrapperFour)
        }
        if !self.wrapperFive.isHidden {
            self.pictureImageView.addSubview(self.wrapperFive)
        }
        
        self.colorSlider.isHidden = true
        
        UIGraphicsBeginImageContextWithOptions(pictureImageView.bounds.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        pictureImageView.layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        colorSlider.isHidden = false
        UIGraphicsEndImageContext()
        return image
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        // check to make sure capture screen works?
        if let annotated = self.captureScreen() {
            self.postDraft.annotatedImage = annotated
            if !self.fromEditVC {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "toDetails", sender: nil)
                }
            }
            else {
                let storyboard = UIStoryboard(name: "Tabs", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "EditPost") as? EditPostViewController {
                    vc.postDraft = self.postDraft
                    vc.imageChanged = true
                    self.show(vc, sender: self)
                }
            }
        }
        else {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Error", message: "Failed to capture your image please try again.")
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetails" {
            if let controller = segue.destination as? PostDetailsViewController {
                // all we need to do now is capture the screen
                // update the postDraft and pass to the next VC
                controller.postDraft = self.postDraft
            }
        }
    }
    
    @IBAction func flipPressed(_ sender: Any) {
        // flip the displayed image
        if self.showingAnnotatedImage != nil {
            self.showingAnnotatedImage = !self.showingAnnotatedImage
        }
    }
    
    private func switchImages() {
        if self.showingAnnotatedImage && self.postDraft.annotatedImage != nil {
            self.pictureImageView.image = self.postDraft.annotatedImage
        }
        else {
            self.pictureImageView.image = self.postDraft.originalImage
        }
    }
    
    private func setupTopImageView() {        
        topImageView.translatesAutoresizingMaskIntoConstraints = false
        topImageView.contentMode = .scaleToFill
        pictureImageView.addSubview(topImageView)
        
        topImageView.centerXAnchor.constraint(equalTo: pictureImageView.centerXAnchor).isActive = true
        topImageView.centerYAnchor.constraint(equalTo: pictureImageView.centerYAnchor).isActive = true
        topImageView.heightAnchor.constraint(equalTo: pictureImageView.heightAnchor, multiplier: 1.0).isActive = true
        topImageView.widthAnchor.constraint(equalTo: pictureImageView.widthAnchor, multiplier: 1.0).isActive = true
    }
    
    private func initialize() {
        self.view.clipsToBounds = true
        self.pictureImageView.contentMode = UIViewContentMode.scaleAspectFill
        
        if self.postDraft.originalImage != nil {
            // Do we also have an annotated image
            if self.postDraft.annotatedImage != nil {
                // We have both images so set the image being displayed to the annotated image
                // Also display the flip image button
                self.flipButton.isHidden = false
                self.showingAnnotatedImage = true
            }
            else {
                self.showingAnnotatedImage = false
                self.flipButton.isHidden = true
            }
        }
        
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if hidden {
                self.navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
        
        setupTopImageView()
        createGestureRecognizers()
        createColorSlider()
        

        self.tvOne.delegate = self
        self.tvTwo.delegate = self
        self.tvThree.delegate = self
        self.tvFour.delegate = self
        self.tvFive.delegate = self
        self.imageView.isMultipleTouchEnabled = true
        self.drawing = false

        
        if UIDevice.current.userInterfaceIdiom == .pad {
            startingFontSize = CGFloat(30)
        }
        else {
            startingFontSize = CGFloat(20)
        }
        
        if let size = startingFontSize {
            self.tvOne.font = UIFont.systemFont(ofSize: size)
            self.tvTwo.font = UIFont.systemFont(ofSize: size)
            self.tvThree.font = UIFont.systemFont(ofSize: size)
            self.tvFour.font = UIFont.systemFont(ofSize: size)
            self.tvFive.font = UIFont.systemFont(ofSize: size)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if !hidden {
                self.navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
    }
}
