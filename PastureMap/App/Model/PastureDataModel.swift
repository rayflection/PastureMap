//
//  PastureDataModel.swift
//  PastureMap
//
//  Created by Mike Yost on 2/24/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import CoreLocation

class PastureDataModel {
    var vertices : [CLLocationCoordinate2D] = []
    var pasture_id:Int64?
    
    init () {
        vertices = []
    }
    init (_ verts:[CLLocationCoordinate2D]) {
        vertices = verts
    }
    init (_ verts:[(Double,Double)] ) {
        for (lat,lon) in verts {
            vertices.append(CLLocationCoordinate2D(latitude:lat, longitude:lon))
        }
    }
    
    func save() {       // returns a status or throws or what?
        // DOES THIS GUY SAVE, or Does the DBMgr save, or MapVC?
    }
}
