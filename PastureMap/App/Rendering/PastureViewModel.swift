//
//  PastureViewModel.swift
//  Map
//
//  Created by Mike Yost on 2/18/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import MapKit

class PastureViewModel {
    var id:Int64?
    var polygonVertices:[MKPointAnnotation]=[]
    var polygonOverlay:MKPolygon?
    var polylines:[MKPolyline]=[]
    var sizeLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:20))
    private var pastureIsComplete=false
    var area=0.0
    var deleteAnnotation:MKPointAnnotation?
    
    func setIsComplete(pastureID:Int64) {
        id = pastureID
        pastureIsComplete = true
    }
    func isComplete() -> Bool {
        return pastureIsComplete
    }
    func clear() {
        polygonVertices.removeAll()
        polygonOverlay = nil
        polylines.removeAll()
        sizeLabel.text = ""
        deleteAnnotation = nil
        pastureIsComplete = false
        area = 0.0
    }
}
