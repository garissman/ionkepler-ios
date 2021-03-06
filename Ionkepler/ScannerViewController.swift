//
//  ScannerViewController.swift
//  Ionkepler
//
//  Created by Ari Morales on 3/30/16.
//  Copyright © 2016 Coreveillance. All rights reserved.
//

import UIKit
import AVFoundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet var donebutton: UIButton!
    @IBOutlet var scannerlabel: UILabel!
	@IBOutlet var lightbutton: UIButton!
	
	var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var audioPlayer: AVAudioPlayer!
    var barcode = bar_codes()
    var barcode_send = bar_codes()
    
    // Added to support different barcodes
    let supportedBarCodes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeAztecCode]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        self.loadSound("Bleep")
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
            // Detect all the supported bar code
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
            // Move the message label to the top view
            view.bringSubviewToFront(scannerlabel)
            view.bringSubviewToFront(donebutton)
			view.bringSubviewToFront(lightbutton)
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func playbleep(sender: AnyObject) {
        self.audioPlayer.play()
    }
    func loadSound(soundName: String){
        do {
            self.audioPlayer =  try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(soundName, ofType: "wav")!))
            self.audioPlayer.prepareToPlay()
        } catch {
            print("Error")
        }
    }
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            //messageLabel.text = "No barcode/QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // Here we use filter method to check if the type of metadataObj is supported
        // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
        // can be found in the array of supported bar codes.
        if supportedBarCodes.contains(metadataObj.type) {
            //        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            let numero:String
            let productn:String
            if metadataObj.stringValue != nil {
                let codigo:String=metadataObj.stringValue
                let arreglo = codigo.characters.split{$0 == ";"}.map(String.init)
                if arreglo.count==2 {
                    numero=String(arreglo[0])
                    productn=String(arreglo[1])
                }else{
                    numero=String(metadataObj.stringValue)
                    productn=String("")
                }
                barcode?.add_serial(numero, product: productn)
                let count=barcode!.serials.count
                scannerlabel.text = "Count: \(count) Last Code: "+metadataObj.stringValue
                self.audioPlayer.play()
            }
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if donebutton === sender {
            barcode_send=barcode
        }
    }
	@IBAction func LightToggle(sender: AnyObject) {
		let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
		if (device.hasTorch) {
			do {
				try device.lockForConfiguration()
				if (device.torchMode == AVCaptureTorchMode.On) {
					device.torchMode = AVCaptureTorchMode.Off
				} else {
					try device.setTorchModeOnWithLevel(1.0)
				}
				device.unlockForConfiguration()
			} catch {
				print(error)
			}
		}
	}
}