//
//  ViewController.swift
//  Ionkepler
//
//  Created by Ari Morales on 3/30/16.
//  Copyright © 2016 Coreveillance. All rights reserved.
//

import UIKit
import CoreLocation
import WebKit

class ViewController: UIViewController, UIWebViewDelegate, WKScriptMessageHandler, EPSignatureDelegate, CLLocationManagerDelegate {
    var webView: WKWebView!
	var imgViewSignature: UIImageView!
    @IBOutlet var containerView: UIView!
	
	let locationManager = CLLocationManager()

	var session = iksession(us:"", psw:"")
	var latitud: Double = 0.0
	var longitud: Double = 0.0
	var altitude: Double = 0.0
	var isPresented: Bool = false
	var speed: Double = 0.0
	var accuracy: Double = 0.0
    //let url = "http://ionkepler.com/coreveillance/main/mobile.php"
	let url = "http://192.168.1.233/coreveillance/main/mobile.php"
	var imageurl=""
    var barcode = bar_codes()
    let contentController = WKUserContentController();
    let config = WKWebViewConfiguration()
    var sentData: NSDictionary = [:]
    var input_serial:String = ""
	var SignatureResponde=""
	override func loadView() {
        super.loadView()
        let userScript = WKUserScript(
            source: "redHeader()",
            injectionTime: WKUserScriptInjectionTime.AtDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.addScriptMessageHandler(
            self,
            name: "callbackHandler"
        )
        config.userContentController = contentController
        self.webView = WKWebView(
            frame: self.containerView.bounds,
            configuration: config
        )
        self.view = self.webView!
	}
	func init_Location() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
	}
    override func viewDidLoad() {
        super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        let requestURL = NSURL(string:url)
        let request = NSURLRequest(URL: requestURL!)
        self.webView!.loadRequest(request)
		self.GetSession()
		self.init_Location()
    }
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        sentData = message.body as! NSDictionary
        let function:String = String(sentData["fnc"] as! NSString)
        if(function == "activate_scanner") {
            input_serial = String(sentData["input_serial"] as! NSString)
            self.activate_scanner()
        }
		if(function == "ShowStatusBar") {
			self.ShowStatusBar()
		}
		if(function == "hide_statusbar") {
			self.HideStatusBar()
		}
		if(function == "ShowRouteMap") {
			let daddress:String = String(sentData["daddress"] as! NSString)
			self.ShowRouteMap(daddress)
		}
		if(function == "ESignature") {
			let customer_name:String = String(sentData["customer_name"] as! NSString)
			SignatureResponde = String(sentData["respond"] as! NSString)
			self.ESignature(customer_name)
		}
		if(function == "GetGPSLocation") {
			let input = String(sentData["input"] as! NSString)
			self.GetGPSLocation(input)
		}
		if(function == "SaveSession") {
			let user = String(sentData["user"] as! NSString)
			let password = String(sentData["password"] as! NSString)
			self.SaveSession(user,password: password)
		}
		if(function == "GetSession") {
			self.GetSession()
		}
		if(function == "DeleteSession") {
			self.DeleteSession()
		}
		if(function == "EditImage") {
			let url = String(sentData["url"] as! NSString)
			self.EditImage(url)
		}
    }
	func GetGPSLocation(input : String) {
		let location = "{\"lat\":\"\(latitud)\",\"long\": \"\(longitud)\",\"altitude\": \"\(altitude)\",\"speed\": \"\(speed)\",\"accuracy\": \"\(accuracy)\"}"
		let send="$('#\(input)').val('\(location)');CallbackNativeApp();"
		print("Sending \(send)")
		webView!.evaluateJavaScript(send) { (result, error) in
			if error != nil {
				print(result)
			}
		}
	}
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let userLocation = locations[0]
		latitud=userLocation.coordinate.latitude
		longitud=userLocation.coordinate.longitude
		altitude=userLocation.altitude
		speed=userLocation.speed
		accuracy=userLocation.horizontalAccuracy
	}
	func ESignature(customer_name: String) {
		let value = UIInterfaceOrientation.Portrait.rawValue
		UIDevice.currentDevice().setValue(value, forKey: "orientation")
		let signatureVC = EPSignatureViewController(signatureDelegate: self, showsDate: true, showsSaveSignatureOption: true)
		signatureVC.subtitleText = "I'm pleased with the service"
		signatureVC.title = customer_name
		signatureVC.showsDate=false
		signatureVC.showsSaveSignatureOption = false
		let nav = UINavigationController(rootViewController: signatureVC)
		presentViewController(nav, animated: true, completion: nil)
	}
	func epSignature(_: EPSignatureViewController, didCancel error : NSError) {
		let value = UIInterfaceOrientation.Portrait.rawValue
		UIDevice.currentDevice().setValue(value, forKey: "orientation")
		print("User canceled")
	}
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
	func epSignature(_: EPSignatureViewController, didSigned signatureImage : UIImage, boundingRect: CGRect) {
		let signaturepng = UIImagePNGRepresentation(signatureImage)
		var signaturepngBase64:NSString = signaturepng!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
		signaturepngBase64 = signaturepngBase64.stringByReplacingOccurrencesOfString("\n", withString: "")
		signaturepngBase64 = signaturepngBase64.stringByReplacingOccurrencesOfString("\r", withString: "")
		print("Sending put_src_img('\(SignatureResponde)_image','data:image/png;base64,\(signaturepngBase64)')")
		webView!.evaluateJavaScript("put_src_img('\(SignatureResponde)_image','data:image/png;base64,\(signaturepngBase64)')") { (result, error) in
			if error != nil {
				print(result)
			}
		}
	}
	func ShowStatusBar()  {
        prefersStatusBarHidden()
		//UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Fade)
	}
	func HideStatusBar()  {
        prefersStatusBarHidden()
		//UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
	}
	func ShowRouteMap(daddress:String){
		print("Opening: comgooglemaps://?saddr=&daddr=\(daddress)&directionsmode=driving")
		if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
			UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?saddr=&daddr=\(daddress)&directionsmode=driving")!)
		} else {
			print("Can't use comgooglemaps://");
		}
	}
	func EditImage(url : String) {
		print("Editing Image \(url)")
		let drawpad = self.storyboard?.instantiateViewControllerWithIdentifier("DrawPadViewController") as! DrawPadViewController
		drawpad.imageurl = url
		self.presentViewController(drawpad, animated: false, completion: nil)
	}
	func DidDrawImage(_: DrawPad, didDraw Image : UIImage, boundingRect: CGRect) {
		let signaturepng = UIImagePNGRepresentation(Image)
		var signaturepngBase64:NSString = signaturepng!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
		signaturepngBase64 = signaturepngBase64.stringByReplacingOccurrencesOfString("\n", withString: "")
		signaturepngBase64 = signaturepngBase64.stringByReplacingOccurrencesOfString("\r", withString: "")
		print("Sending put_src_img('\(SignatureResponde)_image','data:image/png;base64,\(signaturepngBase64)')")
		webView!.evaluateJavaScript("put_src_img('\(SignatureResponde)_image','data:image/png;base64,\(signaturepngBase64)')") { (result, error) in
			if error != nil {
				print(result)
			}
		}
	}
    func activate_scanner() {
        print("Activating Scanner")
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ScannerViewController") as UIViewController
        // .instantiatViewControllerWithIdentifier() returns AnyObject! this must be downcast to utilize it
        self.presentViewController(viewController, animated: false, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToScanner(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? ScannerViewController, barcode_send = sourceViewController.barcode_send {
            // Add a new meal.
            barcode = barcode_send
        }
        print("Entro")
        for serial in (self.barcode?.serials)! {
            print("Sending load_serial({serial:'\(serial.number)',product_number:'\(serial.product)',input_serial:'\(input_serial)'})")
            webView!.evaluateJavaScript("load_serial({serial:'\(serial.number)',product_number:'\(serial.product)',input_serial:'\(input_serial)'})") { (result, error) in
                if error != nil {
                    print(result)
                }
            }
        }
    }
	func SaveSession(user: String, password: String) {
		session.user=user
		session.password=password
		session.SaveSession()
	}
	func DeleteSession() {
		session.user=""
		session.password=""
		session.SaveSession()
	}
	func GetSession() {
		session.GetSession()
		print("Sending xajax_controlador('iniciar_sesion',{user:'\(session.user)',password:'\(session.password)'});")
		webView!.evaluateJavaScript("xajax_controlador('iniciar_sesion',{user:'\(session.user)',password:'\(session.password)'});") { (result, error) in
			if error != nil {
				print(result)
			}
		}
	}
}

