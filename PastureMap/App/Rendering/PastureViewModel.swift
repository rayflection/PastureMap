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
    var pastureName=""
    var polygonVertices:[MKPointAnnotation]=[]
    var polygonOverlay:MKPolygon?
    var polylines:[MKPolyline]=[]
    var sizeLabel = UILabel(frame: CGRect(x:0, y:0, width:200, height:20))
    private var pastureIsComplete=false
    var area=0.0
    var deleteAnnotation:MKPointAnnotation?
    
    init() {}
    
    init(dataModel:PastureDataModel) {
        id = dataModel.pasture_id
        pastureName = dataModel.name
    }
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
// MARK: - helper functions for pasture delete
class AnnotationWithPasture: MKPointAnnotation {
    var pasture:PastureViewModel?
}
class FencePostAnnotation: MKPointAnnotation {
    
}
class ButtonWithPasture: UIButton {
    var pasture:PastureViewModel?
}
extension Array {
    func findIndexOf(_ pasture:PastureViewModel)  -> Int? {
        for (index,item) in self.enumerated() {
            if item is PastureViewModel {
                let foo = item as! PastureViewModel
                if let itemID = foo.id, let pastID = pasture.id {
                    if itemID == pastID {
                        return index
                    }
                }
            }
        }
        return nil
    }
}
