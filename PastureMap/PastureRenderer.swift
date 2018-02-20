//
//  PastureRenderer.swift
//  PastureMap
//
//  Created by Mike Yost on 2/20/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import MapKit

class PastureNumberFormatter {
    static let formatter = { () -> NumberFormatter in
        let temp = NumberFormatter()
        temp.usesGroupingSeparator = true
        temp.numberStyle = .decimal
        temp.maximumFractionDigits = 2
        return temp
    }()
}
class PastureRenderer {

    static func displayAcreageLabel(pasture:Pasture, mapView:MKMapView) {
        let count = pasture.polygonVertices.count
        if count > 2 {
            var lat = 0.0, lon = 0.0
            for ann in pasture.polygonVertices {
                lat += ann.coordinate.latitude
                lon += ann.coordinate.longitude
            }
            lat = lat / Double(count)
            lon = lon / Double(count)
            
            let centerPoint = mapView.convert(CLLocationCoordinate2DMake(lat, lon), toPointTo: mapView)
            
            let size = pasture.sizeLabel
            size.center = centerPoint
            size.textAlignment = .center
            let corners = pasture.polygonVertices.map { $0.coordinate }
            let area = Pasture.regionArea(locations: corners)
            pasture.area = area
            let number = NSNumber(value:  Pasture.areaInAcres(squareMeters:area)  )
            if let formattedNumber = PastureNumberFormatter.formatter.string(from:number) {
                let formattedArea = "Area is \(formattedNumber) acres"
                size.text = formattedArea
                mapView.addSubview(size)
            }
        }
    }
}

class PastureSummaryRenderer {
    static func updateSummary(_ pastures:[Pasture],_ label:UILabel) {
        var totalArea = 0.0
        for pasture in pastures {
            totalArea += pasture.area
        }
        totalArea = Pasture.areaInAcres(squareMeters: totalArea)
        if let foobar = PastureNumberFormatter.formatter.string(from: NSNumber(value:totalArea)) {
            let message = "# Pastures: \(pastures.count)  Total: \(foobar) acres."
            label.text = message
        }
    }
}

class PolylineRendererFactory {
    static func rendererFor(overlay:MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 2.0
        renderer.strokeColor = UIColor.red
        return renderer
    }
}

class PolygonRendererFactory {
    static func rendererFor(overlay:MKOverlay) -> MKPolygonRenderer {
        if let sub = overlay.subtitle! {
            let renderer = MKPolygonRenderer(overlay: overlay)
            if sub.isEqual("complete") {
                renderer.fillColor = UIColor.green
                renderer.strokeColor = UIColor.black
                renderer.lineWidth = 2.0
            } else if sub.isEqual("incomplete") {
                renderer.fillColor = UIColor.yellow
            }
            renderer.alpha = 0.4
            return renderer
        }
        return MKPolygonRenderer(overlay:overlay)
    }
}
