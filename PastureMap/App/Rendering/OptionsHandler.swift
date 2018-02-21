//
//  OptionsHandler.swift
//  PastureMap
//
//  Created by Mike Yost on 2/20/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class OptionsHandler {


    func getOptionsMenuActionSheet(_ button:UIButton,_ mapView:MKMapView) -> UIAlertController {
        let ac = UIAlertController(title: "Map Options", message: "", preferredStyle: .actionSheet)
        
        if mapView.showsUserLocation {
            ac.addAction(UIAlertAction(title: "Hide User", style: .default, handler: { (action) in
                mapView.showsUserLocation = false }))
        } else {
            ac.addAction(UIAlertAction(title: "Show User Location", style: .default, handler: { (action) in
                mapView.showsUserLocation = true}))
        }
        
        if mapView.showsScale {
            ac.addAction(UIAlertAction(title: "Hide Scale", style: .default, handler: { (action) in
                mapView.showsScale = false }))
        } else {
            ac.addAction(UIAlertAction(title: "Show Scale when zooming", style: .default, handler: { (action) in
                mapView.showsScale = true }))
        }
        
        if mapView.mapType != .hybrid {
            ac.addAction(UIAlertAction(title: "Use Hybrid Map", style: .default, handler: { (action) in
                mapView.mapType = .hybrid }))
        }
        if mapView.mapType != .satellite {
            ac.addAction(UIAlertAction(title: "Use Satellite Map", style: .default, handler: { (action) in
                mapView.mapType = .satellite }))
        }
        if mapView.mapType != .standard {
            ac.addAction(UIAlertAction(title: "Use Standard Map", style: .default, handler: { (action) in
                mapView.mapType = .standard }))
        }

        if UI_USER_INTERFACE_IDIOM() == .pad {
            ac.popoverPresentationController?.sourceView = button
        } else {
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                print("Chose Cancel")
            }))
        }
        return ac
    }
}
