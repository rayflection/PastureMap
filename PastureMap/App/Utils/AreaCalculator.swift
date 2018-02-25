//
//  AreaCalculator.swift
//  PastureMap
//
//  Created by Mike Yost on 2/20/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import CoreLocation

class AreaCalculator {

    static let kEarthRadius = 6378137.0
    
    // CLLocationCoordinate2D uses degrees but we need radians
    static func radians(degrees: Double) -> Double {
        return degrees * Double.pi / 180;
    }
    
    // https://stackoverflow.com/questions/22038925/mkpolygon-area-calculation?rq=1
    static func regionArea(locations: [CLLocationCoordinate2D]) -> Double {
        
        guard locations.count > 2 else { return 0 }
        var area = 0.0
        
        for i in 0..<locations.count {
            let p1 = locations[i > 0 ? i - 1 : locations.count - 1]
            let p2 = locations[i]
            
            area += radians(degrees: p2.longitude - p1.longitude) * (2 + sin(radians(degrees: p1.latitude)) + sin(radians(degrees: p2.latitude)) )
        }
        
        area = -(area * kEarthRadius * kEarthRadius / 2);
        
        return max(area, -area) // In order not to worry about is polygon clockwise or counterclockwise defined.
    }
    static func areaInAcres(squareMeters:Double) -> Double {
        return squareMeters / 4046.86
    }
    
    static func acres(locations: [CLLocationCoordinate2D]) -> Double {
        let squareMeters = AreaCalculator.regionArea(locations: locations)
        return areaInAcres(squareMeters: squareMeters)
    }
}
