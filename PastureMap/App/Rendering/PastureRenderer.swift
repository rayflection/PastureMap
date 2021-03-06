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
    static let formatter6 = { () -> NumberFormatter in
        let temp = NumberFormatter()
        temp.usesGroupingSeparator = true
        temp.numberStyle = .decimal
        temp.maximumFractionDigits = 6
        return temp
    }()
}
class PastureRenderer {

    static func formattedAcres(pasture:PastureDataModel) -> String {
        let number = NSNumber(value:  AreaCalculator.acres(locations: pasture.vertices)  )
        if let formattedNumber = PastureNumberFormatter.formatter.string(from:number) {
            return formattedNumber
        } else {
            return String(describing: number)
        }
    }
    static func displayAcreageLabel(pasture:PastureViewModel, mapView:MKMapView) {
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
            //let corners = pasture.polygonVertices.map { $0.coordinate }
            let area = AreaCalculator.regionArea(pasture:pasture)
            pasture.area = area
            let number = NSNumber(value:  AreaCalculator.areaInAcres(squareMeters:area)  )
            if let formattedNumber = PastureNumberFormatter.formatter.string(from:number) {
                let formattedArea = "\(pasture.pastureName) : \(formattedNumber) acres"
                size.text = formattedArea
                mapView.addSubview(size)
            }
        }
    }
}
class LineLengthRenderer {
    static func display(_ p1:CLLocationCoordinate2D, _ p2:CLLocationCoordinate2D, _ label:UILabel) {
        let length = p2.distanceFrom(p1)
        let title = "\(length.formatted()) meters"
        label.text = title
    }
}
class PastureSummaryRenderer {
    static func updateSummary(_ pastures:[PastureViewModel],_ label:UILabel) {
        var totalArea = 0.0
        for pasture in pastures {
            totalArea += pasture.area
        }
        totalArea = AreaCalculator.areaInAcres(squareMeters: totalArea)
        let message = "# Pastures: \(pastures.count)  Total: \(totalArea.formatted()) acres."
        label.text = message
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
// ===============================================
// MARK: Extensions
extension CLLocationCoordinate2D {
    func to_s() -> String {
        return "\(String(format: "%.4f", latitude)),  \(String(format: "%.4f", longitude))"
    }
    func distanceFrom(_ coordinate:CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return loc2.distance(from:loc1)
    }
}
extension Double {
    func formatted() -> String {
        if let string =  PastureNumberFormatter.formatter.string(from: NSNumber(value:self)) {
            return string
        }
        return "0.0"
    }
    func formatted6() -> String {
        if let string =  PastureNumberFormatter.formatter6.string(from: NSNumber(value:self)) {
            return string
        }
        return "0.0"    }
}
