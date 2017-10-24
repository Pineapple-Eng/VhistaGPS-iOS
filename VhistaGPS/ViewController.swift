//
//  ViewController.swift
//  Travelia
//
//  Created by Juan David Cruz Serrano on 9/10/17.
//  Copyright © 2017 Juan David Cruz Serrano. All rights reserved.
//

import UIKit

import AVFoundation
import ARCL
import CoreLocation
import AppShuttle
import Alamofire
import SceneKit

var userLocation:CLLocation!
class ViewController: UIViewController {
    
    var sceneLocationView = SceneLocationView()
    @IBOutlet weak var interfaceView: UIView!
    @IBOutlet weak var topToolbar: UIToolbar!
    
    let locationManager = CLLocationManager()
    var needPlacesUpdate = true
    
    var places = [Place]()
    
    var checkNodesTimer: Timer!
    var visibleNodes = [SCNNode]()
    var annotationNodes = [LocationAnnotationNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        VhistaSpeechManager.shared.sayGreetingMessage()
        setUpSceneLocationView()
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let _ = checkLocationPermissions()
        let _ = checkCameraPermissions()
    }
    
    func setUpUI() {
        topToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        topToolbar.backgroundColor = UIColor.clear
        topToolbar.clipsToBounds = true
    }
    
    @IBAction func reloadLocations(_ sender: Any) {
        needPlacesUpdate = true
    }
    
    @IBAction func radialAnalysis(_ sender: Any) {
        if !checkCameraPermissions() {
            return
        }
        if !checkLocationPermissions() {
            return
        }
        
        if needPlacesUpdate {
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        self.performSegue(withIdentifier: "GoToRadar", sender: nil)
        
       
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    
    func setUpSceneLocationView() {
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        view.bringSubview(toFront: interfaceView)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func addNearbyPlaces() {
        
        if !checkLocationPermissions() {
            return
        }
        
        places = [Place]()
        annotationNodes = [LocationAnnotationNode]()
        
        for node in sceneLocationView.getLocationNodes() {
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        
        checkNodesTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkNodes), userInfo: nil, repeats: true)
        
        let parameters: Parameters = ["latitude": userLocation.coordinate.latitude, "longitude":userLocation.coordinate.longitude]
        print(parameters)
        Alamofire.request("https://us-central1-vhistaapp.cloudfunctions.net/getNearbyPlaces", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success:
                if let json = response.result.value {
                    let places = json as! Dictionary<String, Any>
                    for place in places {
                        let placeDict = place.value as! Dictionary<String, Any>
                        let newPlace = Place.init(name: placeDict["name"] as! String, type: placeDict["type"] as! String,address: placeDict["address"] as! String, latitude: placeDict["latitude"] as! Double, longitude: placeDict["longitude"] as! Double, thumbnailURL: placeDict["thumbnailURL"] as! String, pinType: placeDict["pinType"] as! String, elevation: placeDict["elevation"] as! Double)
                        self.places.append(newPlace)
                    }
                    self.addPlaceNodesInScene()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func addPlaceNodesInScene() {
        
        for place in places {
            let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            let location = CLLocation(coordinate: coordinate, altitude: place.elevation)
            let image:UIImage!
            
            switch place.pinType {
            case "TRAFFICLIGHT":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "TrafficLightPin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "CULTURE":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "CulturePin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "HEALTH":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "HealthPin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "EDUCATION":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "EducationalPin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "STORE":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "StorePin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "FOOD":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "RestaurantPin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "TRANSPORT":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "TransportationPin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            case "SECURITY":
                image = textToImage(drawText: place.name, inImage: UIImage(named: "SecurityPin")!, atPoint: CGPoint(x: 0.0, y: 100.0))
            default:
                image = textToImage(drawText: place.name, inImage: UIImage(named: "placeholderPin")!, atPoint: CGPoint(x: 0.0, y: 20.0))
            }
            
            let placeDict = ["name": place.name, "pinType":place.pinType, "type":place.type, "latitude":place.latitude, "longitude":place.longitude, "thumbnailURL": place.thumbnailURL, "elevation": place.elevation, "address": place.address] as [String : Any]
            
            let annotationNode = LocationAnnotationNode(location: location, image: image, place: placeDict)
            annotationNodes.append(annotationNode)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        }
        
    }
    
    @objc func checkNodes() {
      
        for node in sceneLocationView.sceneNode!.childNodes {
            var isVisible = false
            if visibleNodes.contains(node) {
                isVisible = true
            }
            if (sceneLocationView.isNode(node, insideFrustumOf: sceneLocationView.pointOfView!)) {
                if !isVisible {
                    visibleNodes.append(node)
                    speakNode(pNode: node)
                }
            } else {
                if isVisible {
                    visibleNodes.remove(at:visibleNodes.index(of: node)!)
                }
            }
            
        }
    }
    
    func speakNode(pNode:SCNNode) {
        
        if needPlacesUpdate {
            return
        }
        
        let place = (pNode as! LocationAnnotationNode).place
        
        let placeCoordinate = CLLocation(coordinate: CLLocationCoordinate2D(latitude: place["latitude"] as! Double, longitude: place["longitude"] as! Double), altitude: place["elevation"] as! Double)
        let distanceInMeters = String(Int(userLocation.distance(from: placeCoordinate).rounded())) // result is in meters
        let stringToSpeak = place["name"] as! String + " a " + distanceInMeters + " metros."
        
        VhistaSpeechManager.shared.sayText(stringToSpeak: stringToSpeak , isProtected: true, rate: Float(globalRate))
        
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        if needPlacesUpdate {
            addNearbyPlaces()
            needPlacesUpdate = false
        }
    }
}

extension UIViewController {
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.darkGray
        let textFont = UIFont.systemFont(ofSize: 12)
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSAttributedStringKey.font: textFont,
            NSAttributedStringKey.foregroundColor: textColor,
            NSAttributedStringKey.paragraphStyle: titleParagraphStyle
            ]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func checkCameraPermissions() -> Bool{
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.denied {
            
            VhistaSpeechManager.shared.stopSpeech(sender: self)
            
            VhistaSpeechManager.shared.sayText(stringToSpeak: NSLocalizedString("No_Camera_Access", comment: ""), isProtected: true, rate: Float(globalRate))
            
            let alert: UIAlertController = UIAlertController(title: NSLocalizedString("Camera_Access", comment: ""), message: NSLocalizedString("No_Camera_Access", comment: ""), preferredStyle: .alert)
            
            let button: UIAlertAction = UIAlertAction(title: NSLocalizedString("Go_To_Settings", comment: ""), style: .default, handler: { (action:UIAlertAction) in
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { (completition) in
                })
            })
            
            alert.addAction(button)
            
            self.present(alert, animated: true, completion: nil)
            
            return false
            
        } else if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized {
            return true
        } else {
            return false
        }
    }
    
    func checkLocationPermissions() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .denied:
                VhistaSpeechManager.shared.stopSpeech(sender: self)
                
                VhistaSpeechManager.shared.sayText(stringToSpeak: NSLocalizedString("No_Location_Access", comment: ""), isProtected: true, rate: Float(globalRate))
                
                let alert: UIAlertController = UIAlertController(title: NSLocalizedString("Location_Access", comment: ""), message: NSLocalizedString("No_Location_Access", comment: ""), preferredStyle: .alert)
                
                let button: UIAlertAction = UIAlertAction(title: NSLocalizedString("Go_To_Settings", comment: ""), style: .default, handler: { (action:UIAlertAction) in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: { (completition) in
                    })
                })
                
                alert.addAction(button)
                
                self.present(alert, animated: true, completion: nil)
                
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
                return true
            case .notDetermined:
                return false
            case .restricted:
                return false
            }
        } else {
            print("Location services are not enabled")
            return false
        }
    }
}

