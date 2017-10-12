//
//  SonarViewController.swift
//  Travelia
//
//  Created by Juan David Cruz Serrano on 10/9/17.
//  Copyright © 2017 Juan David Cruz Serrano. All rights reserved.
//

import UIKit
import Sonar
import GooglePlaces
import Alamofire
import AFNetworking

class SonarViewController: UIViewController {

    @IBOutlet weak var sonarView: SonarView!
    
    var places = [Place]()
    var currentPlace: GMSPlace?
    var currentPlaceDanger: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VhistaSpeechManager.shared.sayText(stringToSpeak: "Reconociendo Ubicación", isProtected: true, rate: Float(globalRate))
        setUpRadar()
        getCurrentPlace()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }

    @IBAction func describeAgain(_ sender: Any) {
        VhistaSpeechManager.shared.sayText(stringToSpeak: "Reconociendo Ubicación", isProtected: true, rate: Float(globalRate))
        getCurrentPlace()
    }
    
    @IBAction func goBack(_ sender: Any) {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { $0.cancel() }
            uploadData.forEach { $0.cancel() }
            downloadData.forEach { $0.cancel() }
        }
        self.dismiss(animated: false, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension SonarViewController {
    
    func getCurrentPlace() {
        GMSPlacesClient.shared().currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                self.currentPlace = nil
                self.addNearbyPlaces()
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.currentPlace = place
                } else {
                    self.currentPlace = nil
                }
            } else {
                self.currentPlace = nil
            }
            
            self.addNearbyPlaces()
            
        })
    }
    
    func addNearbyPlaces() {
        places = [Place]()
        let parameters: Parameters = ["latitude": userLocation.coordinate.latitude, "longitude":userLocation.coordinate.longitude]
        print(parameters)
        Alamofire.request("https://us-central1-vhistaapp.cloudfunctions.net/getNearbyPlaces", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success:
                if let json = response.result.value {
                    let places = json as! Dictionary<String, Any>
                    for place in places {
                        let placeDict = place.value as! Dictionary<String, Any>
                        let newPlace = Place.init(name: placeDict["name"] as! String, type: placeDict["type"] as! String,address: placeDict["address"] as! String, latitude: placeDict["latitude"] as! Double, longitude: placeDict["longitude"] as! Double, thumbnailURL: placeDict["thumbnailURL"] as! String, pinType: placeDict["pinType"] as! String)
                        self.places.append(newPlace)
                    }
                    self.recognizeLocationDanger()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func recognizeLocationDanger() {
        let parameters: Parameters = ["latitude": userLocation.coordinate.latitude, "longitude":userLocation.coordinate.longitude]
        print(parameters)
        Alamofire.request("https://us-central1-vhistaapp.cloudfunctions.net/getCurrentLocationSecurity", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success:
                if let json = response.result.value {
                    let response = json as! Dictionary<String, Any>
                    self.currentPlaceDanger = response["dangerLevel"] as! String
                    self.describeLocation()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
    func describeLocation() {
        if sonarView != nil {
            sonarView.reloadData()
        } else {
            return
        }
    }
    
}

extension SonarViewController: SonarViewDelegate, SonarViewDataSource {
    
    func setUpRadar() {
        
        sonarView.delegate = self
        sonarView.dataSource = self
        SonarView.lineColor = UIColor(white: 0.95, alpha: 1.0)
        SonarView.lineShadowColor = UIColor(white: 0.95, alpha: 1.0)
        SonarView.distanceTextColor = UIColor(white: 0.95, alpha: 1.0)
        
    }
    
    func sonarView(sonarView: SonarView, textForWaveAtIndex waveIndex: Int) -> String? {
        return ""
    }
    
    func sonarView(sonarView: SonarView, numberOfItemForWaveIndex waveIndex: Int) -> Int {
        switch waveIndex {
        case 0:
            return self.currentPlace != nil ? 1 : 0
        default:
            return waveIndex*3 <= places.count ? 3 : 3+(places.count - waveIndex*3)
        }
    }
    
    func sonarView(sonarView: SonarView, itemViewForWave waveIndex: Int, atIndex: Int) -> SonarItemView {
        print("Wave: " + String(waveIndex) + " and Index " + String(atIndex))
        switch waveIndex {
        case 0:
            let itemView = self.newItemView()
            itemView.imageView.image = UIImage(named: "MyLocation")
            
            let stringName =  self.currentPlace != nil ? "Tu ubicación es: " + currentPlace!.name + (currentPlaceDanger != nil ? ". Te encuentras en un sitio catalogado como " + currentPlaceDanger! : "") + ". Desliza tu dedo para escuchar lugares cercanos." : "Error Obteniendo Ubicación"
            itemView.nameLabel.text = stringName
            
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, itemView.nameLabel);

            
            return itemView
        default:
            let itemView = self.newItemView()
            let currentPlace = places[(waveIndex-1)*3 + atIndex]
            print(currentPlace)
            itemView.imageView.setImageWith(URL(string: currentPlace.thumbnailURL)!)
            
            
            let myCoordinate = CLLocation(coordinate: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude), altitude: 2600)
            let placeCoordinate = CLLocation(coordinate: CLLocationCoordinate2D(latitude: currentPlace.latitude, longitude: currentPlace.longitude), altitude: 2600)
            let distanceInMeters = myCoordinate.distance(from: placeCoordinate)
            
            itemView.nameLabel.text = currentPlace.name + ". \n A " + String(Int(distanceInMeters.rounded())) + " metros, con dirección: " + currentPlace.address
            
            return itemView
        }
        
    }
    
    func numberOfWaves(sonarView: SonarView) -> Int {
        return Int(1 + ceil(Double(places.count)/3.0))
    }
    
    func sonarView(sonarView: SonarView, didSelectObjectInWave waveIndex: Int, atIndex: Int) {
        
    }
    
    fileprivate func newItemView() -> SonarItem {
        return Bundle.main.loadNibNamed("SonarItem", owner: self, options: nil)!.first as! SonarItem
    }
}
