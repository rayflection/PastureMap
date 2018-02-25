//
//  PastureCornerCell.swift
//  PastureMap
//
//  Created by Mike Yost on 2/25/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit
import CoreLocation

class PastureCornerCell: UITableViewCell {

    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    
    func render(_ coord:CLLocationCoordinate2D) {
        latitudeLabel.text = coord.latitude.formatted()
        longitudeLabel.text = coord.longitude.formatted()
    }
}
