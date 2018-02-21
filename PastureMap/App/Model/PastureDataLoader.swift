//
//  PastureDataLoader.swift
//  PastureMap
//
//  Created by Mike Yost on 2/20/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import MapKit

class PastureDataLoader {
    
    func go(_ mapVC: MapVC ) {
        let pastures = getSomeData()
        for pastureDM in pastures {
            create(pastureDM, mapVC)
        }
    }
    
    func getSomeData() -> [PastureDataModel] {
        var models : [PastureDataModel] = []
        let pdm = PastureDataModel()
        pdm.vertices.append(CLLocationCoordinate2D(latitude: 39.41, longitude: -77.81))
        pdm.vertices.append(CLLocationCoordinate2D(latitude: 39.41, longitude: -77.82))
        pdm.vertices.append(CLLocationCoordinate2D(latitude: 39.42, longitude: -77.82))
        pdm.vertices.append(CLLocationCoordinate2D(latitude: 39.42, longitude: -77.81))

        models.append(pdm)
        return models
    }
    
    func create(_ data:PastureDataModel, _ mapVC:MapVC) {
        let fakeButton = UIButton()
        mapVC.createPastureButtonTapped( fakeButton )
        
        for point in data.vertices {
            mapVC.addToPolygon(pasture: mapVC.currentPasture, coord:point, isComplete:false)
        }
        
        mapVC.finishButtonTapped(fakeButton)
    }
}

import CoreLocation
class PastureDataModel {
    var vertices : [CLLocationCoordinate2D] = []
}
