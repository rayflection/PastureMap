//
//  PastureModel.swift
//  Map1
//
//  Created by Mike Yost on 2/18/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import MapKit

class Pasture {
    var polygonVertices:[MKPointAnnotation]=[]
    var polygonOverlay:MKPolygon?
    var polylines:[MKPolyline]=[]
    var sizeLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:20))
    var isComplete=false
    var area=0.0
    
    func clear() {
        polygonVertices.removeAll()
        polygonOverlay = nil
        polylines.removeAll()
        sizeLabel.text = ""
        isComplete = false
        area = 0.0
    }

}
