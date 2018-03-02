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
    var name: String=""
    var pasture_id:Int64?
    
    init () {
        vertices = []
    }
    init(_ id:Int64) {
        vertices = []
        pasture_id = id
    }
    init (_ id:Int64, _ verts:[CLLocationCoordinate2D]) {
        pasture_id = id
        vertices = verts
    }
    init (_ verts:[CLLocationCoordinate2D]) {
        vertices = verts
    }
    init (_ verts:[(Double,Double)] ) {
        for (lat,lon) in verts {
            vertices.append(CLLocationCoordinate2D(latitude:lat, longitude:lon))
        }
    }
}
