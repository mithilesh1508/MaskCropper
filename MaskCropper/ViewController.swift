//
//  ViewController.swift
//  MaskCropper
//
//  Created by Mithilesh Kumar on 28/07/22.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var initialCenter = CGPoint()  // The initial center point of the view.
   
    /*Lets follow the step for cropping image along with moving view in full resolution*/
    //MARK: - Variables
    var blurEffectView = UIVisualEffectView()
    var bgImage: UIImage!
    var originalImageView = UIImageView()
    var blurImageView = UIImageView()
    var cropperView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        bgImage = UIImage(named: "m.jpg")
        setupViews()
        setUpVisualBlurOverUserImage()
        
        //setting crop path over image
        applyMaskOverImage()
        
        /*Adding gesture on cropper view*/
        addingGestureOnView(onTo: cropperView)
        
    }
    
    func setupViews(){
        /*preserving aspect ratio of image according to its parent view*/
        self.originalImageView.frame = AVMakeRect(aspectRatio: bgImage.size, insideRect: CGRect(x: 0, y: 150, width: self.view.bounds.size.width, height: self.view.bounds.size.height - 260))
        
        self.blurImageView.frame = AVMakeRect(aspectRatio: self.bgImage.size, insideRect: self.originalImageView.bounds)
        
        self.originalImageView.isUserInteractionEnabled = true //Set it for movement
        self.originalImageView.center = CGPoint(x: self.view.bounds.size.width/2, y: self.view.bounds.size.height/2)
        self.blurImageView.center = CGPoint(x: self.view.bounds.size.width/2, y: self.view.bounds.size.height/2)
        
        self.originalImageView.image = bgImage
        self.blurImageView.image = bgImage
        
        self.view.addSubview(originalImageView)
        self.view.addSubview(blurImageView)
        self.originalImageView.addSubview(cropperView)
        self.originalImageView.clipsToBounds = true
        //Addition ofcrop button
        let cropButton = UIButton(frame: CGRect(x:( self.view.bounds.size.width - 120)/2, y: self.view.bounds.size.height - 80, width: 120, height: 40))
        self.view.addSubview(cropButton)
        cropButton.backgroundColor = .systemTeal
        cropButton.setTitle("Crop", for: .normal)
        cropButton.addTarget(self, action: #selector(cropButtonAction), for: .touchUpInside)
    }
    
    func setUpVisualBlurOverUserImage(){
        let blurEffect = UIBlurEffect(style: .systemThinMaterialLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.blurImageView.bounds
        //always fill the view
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.blurImageView.addSubview(blurEffectView)
        self.view.bringSubviewToFront(self.originalImageView)
    }
    
    func applyMaskOverImage()
    {
        cropperView.frame = CGRect(x: 20, y: 0, width: self.originalImageView.bounds.size.width-40, height: 200) //Pass the CGRect as per your requirements.
        /*Making border of cropview*/
        cropperView.layer.borderColor = UIColor.darkGray.cgColor
        cropperView.layer.borderWidth = 1.0
        
        /*placing of cropview in center of imageView*/
        cropperView.center = CGPoint(x: self.originalImageView.frame.size.width/2, y: self.originalImageView.frame.size.height/2)
        cropperView.alpha = 1.0;
        self.maskPath(cropperView)
    }
    
    func maskPath(_ cropView: UIView) {
        let mask = CAShapeLayer()
        let path = CGPath(rect: cropView.frame, transform: nil)
        mask.path = path
        // Set the mask of the view.
        self.originalImageView.layer.mask = mask
    }
    
    func addingGestureOnView(onTo cropView: UIView)
    {
        let pangesture = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan))
        // pangesture.delegate = self
        cropperView.addGestureRecognizer(pangesture)
        
        let pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(handlePinch))
        //pinchGesture.delegate = self
        cropperView.addGestureRecognizer(pinchGesture)
    }
    
    //MARK: - Crop Button Action
    @objc func cropButtonAction(sender: UIButton){
        //Calculting aspect ratio's
        /* New X= ((orginalX / originalWidth) * currentWidth)*/
        
        let xOffset = ((cropperView.frame.origin.x /*+ imgViewRect.origin.x/2*/) / originalImageView.frame.size.width) * bgImage.size.width
        
        let yOffset = ((cropperView.frame.origin.y /*+ imgViewRect.origin.y / 2*/) / originalImageView.frame.size.height) * bgImage.size.height
        
        let realW = (cropperView.frame.size.width / originalImageView.frame.size.width) * bgImage.size.width
        
        let realH = (cropperView.frame.size.height / originalImageView.frame.size.height) * bgImage.size.height
        
        // The cropRect is the rect of the image to keep,
        // in this case centered
        let cropRect = CGRect(
            x: xOffset,
            y: yOffset,
            width: realW,
            height: realH
        ).integral
        
        // Center crop the image
        let sourceCGImage = bgImage.cgImage!
        let croppedCGImage = sourceCGImage.cropping(
            to: cropRect
        )!
        let croppedImage: UIImage = UIImage(cgImage: croppedCGImage)// do what you want with cropped image.
        print("Your cropped image ==",croppedImage)
    }
    //MARK: - Handling Gesture Action
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer){
    
        guard gestureRecognizer.view != nil else {return}
    
        let superViewFrame = self.originalImageView.bounds
        let location = gestureRecognizer.location(in: originalImageView)
        let translation = gestureRecognizer.translation(in: originalImageView)
        let previousLocation = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
        //Cropper View
        let dragableView = gestureRecognizer.view!
        
        if gestureRecognizer.state == .began {
            // Save the view's original position.
            self.initialCenter = dragableView.center
        }
        // Update the position for the .began, .changed, and .ended states
        if gestureRecognizer.state != .cancelled {
            // new frame for this "draggable" subview, based on touch offset when moving
            var newFrame = gestureRecognizer.view!.frame.offsetBy(dx: location.x - previousLocation.x, dy: location.y - previousLocation.y)
            
            //restriction withing superview's boundary:1
            // make sure Left edge is not past Left edge of superview
            newFrame.origin.x = max(newFrame.origin.x, 0.0)
            // make sure Right edge is not past Right edge of superview
            newFrame.origin.x = min(newFrame.origin.x, superViewFrame.size.width - newFrame.size.width)
            
            // make sure Top edge is not past Top edge of superview
            newFrame.origin.y = max(newFrame.origin.y, 0.0)
            // make sure Bottom edge is not past Bottom edge of superview
            newFrame.origin.y = min(newFrame.origin.y, superViewFrame.size.height - newFrame.size.height)
            
            dragableView.frame = newFrame
            
            gestureRecognizer.setTranslation(.zero, in: dragableView.superview)
            self.maskPath(dragableView)
            
            
            /*
             //restriction withing superview's boundary:2
             if newFrame.origin.x < 0{
             // if the new left edge would be outside the superview (dragging left),
             // set the new origin.x to Zero
             newFrame.origin.x = 0
             }
             else if (newFrame.origin.x + newFrame.size.width > superViewFrame.size.width){
             
             // if the right edge would be outside the superview (dragging right),
             // set the new origin.x to the width of the superview - the width of this view
             newFrame.origin.x = superViewFrame.size.width - dragableView.frame.size.width
             }
             
             if (newFrame.origin.y < 0) {
             
             // if the new top edge would be outside the superview (dragging up),
             // set the new origin.y to Zero
             newFrame.origin.y = 0
             
             }
             else if (newFrame.origin.y + newFrame.size.height > superViewFrame.size.height) {
             
             // if the new bottom edge would be outside the superview (dragging down),
             // set the new origin.y to the height of the superview - the height of this view
             newFrame.origin.y = superViewFrame.size.height - dragableView.frame.size.height
             }
             // update this view's frame
             dragableView.frame = newFrame
             gestureRecognizer.setTranslation(.zero, in: dragableView.superview)
             self.maskPath(dragableView)*/
        }
        else
        {
            // On cancellation, return the piece to its original location.
            dragableView.center = initialCenter
            gestureRecognizer.setTranslation(.zero, in: dragableView.superview)
            self.maskPath(dragableView)
        }
    }
    
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer){
        
        guard gestureRecognizer.view != nil else { return }
        
        if let view = gestureRecognizer.view {
            view.transform = view.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            gestureRecognizer.scale = 1
            self.maskPath(gestureRecognizer.view!)
        }
    }
    
}

