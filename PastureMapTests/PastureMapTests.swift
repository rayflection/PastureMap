//
//  PastureMapTests.swift
//  PastureMapTests
//
//  Created by Mike Yost on 2/19/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import XCTest
import MapKit
@testable import PastureMap

class PastureMapTests: XCTestCase {
    
    func testPolygonAreaBigSquare() {
        let points = [
            CLLocationCoordinate2D(latitude: 39.0,longitude: -77.0 ),
            CLLocationCoordinate2D(latitude: 39.0,longitude: -77.1 ),
            CLLocationCoordinate2D(latitude: 39.1,longitude: -77.1 ),
            CLLocationCoordinate2D(latitude: 39.1,longitude: -77.0 )
        ]
        XCTAssertEqual(AreaCalculator.regionArea(locations: points), 96236049.0, accuracy: 1.0)
    }
    func testPolygonAreaLittleSquare() {
        let points = [
            CLLocationCoordinate2D(latitude: 39.0000,longitude: -77.0000 ),
            CLLocationCoordinate2D(latitude: 39.0000,longitude: -77.0001 ),
            CLLocationCoordinate2D(latitude: 39.0001,longitude: -77.0001 ),
            CLLocationCoordinate2D(latitude: 39.0001,longitude: -77.0000 )
        ]
        XCTAssertEqual(AreaCalculator.regionArea(locations: points), 96.304, accuracy: 0.001)
    }
    func testPolygonAreaCrossedLinesReturnsZero() {
        let points = [
            CLLocationCoordinate2D(latitude: 39.0,longitude: -77.0 ),
            CLLocationCoordinate2D(latitude: 39.1,longitude: -77.1 ),
            CLLocationCoordinate2D(latitude: 39.0,longitude: -77.1 ),
            CLLocationCoordinate2D(latitude: 39.1,longitude: -77.0 )
        ]
        XCTAssertEqual(AreaCalculator.regionArea(locations: points), 0.0, accuracy: 0.0)
    }
    func testAcreConversion() {
        XCTAssertEqual(AreaCalculator.areaInAcres(squareMeters: 4046.86), 1.0, accuracy: 0.0)
    }
}
