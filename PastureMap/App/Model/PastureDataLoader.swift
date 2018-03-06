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
    
    func loadDataFromDB(_ mapVC: MapVC, db:DataBaseInterface ) {
        let pastures = db.getAll()
        for pastureDM in pastures {
            injectPasture(pastureDM, mapVC)
        }
    }
    func injectPasture(_ data:PastureDataModel, _ mapVC:MapVC) {
        let viewModel = PastureViewModel(dataModel:data)
        if !mapVC.installExistingPastureIfNotAlreadyThere(viewModel) {
            for point in data.vertices {
                mapVC.addToPolygon(pasture: mapVC.currentPasture, coord:point, isComplete:false)
            }
            mapVC.finishButtonTapped(viewModel)
        }
    }
    // ----------------------------
    func loadTestData(_ mapVC: MapVC) {
        let userLoc = mapVC.mapView.userLocation.coordinate
        
        let pastures = getSomeData(userLoc)
        for pastureDM in pastures {
            create(pastureDM, mapVC)
        }
    }
    func getSomeData(_ center:CLLocationCoordinate2D) -> [PastureDataModel] {
        var models : [PastureDataModel] = []

        models.append(PastureDataModel(squareArountPoint(center)))
        models.append(PastureDataModel(squareArountPoint(center.offsetBy( 0.020,  0.020))))
        models.append(PastureDataModel(squareArountPoint(center.offsetBy(-0.025,  0.025))))
        models.append(PastureDataModel(squareArountPoint(center.offsetBy(-0.010, -0.020))))

        let arrayOfTuplesOfDoubles = [
            (39.37, -77.70),
    //        (39.37, -77.75),
            (39.38, -77.75),
            (39.38, -77.70)
        ]
        let pastureFromRawData = PastureDataModel(arrayOfTuplesOfDoubles)
        models.append(pastureFromRawData)
        
        return models
    }
    
    func squareArountPoint(_ point:CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let deltaX = 0.0075
        let deltaY = 0.0075
        let one = CLLocationCoordinate2D(latitude: point.latitude + deltaX, longitude: point.longitude + deltaY )
        let two = CLLocationCoordinate2D(latitude: point.latitude + deltaX, longitude: point.longitude - deltaY )
        let tre = CLLocationCoordinate2D(latitude: point.latitude - deltaX, longitude: point.longitude - deltaY )
        let fur = CLLocationCoordinate2D(latitude: point.latitude - deltaX, longitude: point.longitude + deltaY )
        
        return [one, two, tre, fur]
    }
    
    func create(_ data:PastureDataModel, _ mapVC:MapVC) {

        let fakeButton = UIButton()
        mapVC.createPastureButtonTapped( fakeButton )
        
        for point in data.vertices {
            mapVC.addToPolygon(pasture: mapVC.currentPasture, coord:point, isComplete:false)
        }
        let fakeNotAButton = UIView()
        mapVC.finishButtonTapped(fakeNotAButton)
    }
}
extension CLLocationCoordinate2D {
    func offsetBy(_ x:CLLocationDegrees, _ y:CLLocationDegrees) -> CLLocationCoordinate2D{
        return CLLocationCoordinate2D(latitude: self.latitude + x, longitude: self.longitude + y)
    }
}

