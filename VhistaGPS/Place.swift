//
//  Place.swift
//  VhistaGPS
//
//  Created by Juan David Cruz Serrano on 10/9/17.
//  Copyright © 2017 Juan David Cruz Serrano. All rights reserved.
//

import Foundation
import UIKit

struct Place: Codable {
    var name: String
    var type: String
    var address: String
    var latitude: Double
    var longitude: Double
    var thumbnailURL: String
    var pinType: String
}
