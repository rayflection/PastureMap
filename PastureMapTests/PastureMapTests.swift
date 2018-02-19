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
        XCTAssertEqual(Pasture.regionArea(locations: points), 23780.0, accuracy: 1.0)
    }
    func testPolygonAreaLittleSquare() {
        let points = [
            CLLocationCoordinate2D(latitude: 39.0000,longitude: -77.0000 ),
            CLLocationCoordinate2D(latitude: 39.0000,longitude: -77.0001 ),
            CLLocationCoordinate2D(latitude: 39.0001,longitude: -77.0001 ),
            CLLocationCoordinate2D(latitude: 39.0001,longitude: -77.0000 )
        ]
        XCTAssertEqual(Pasture.regionArea(locations: points), 0.023780, accuracy: 0.0001)
    }
    func testPolygonAreaCrossedLinesReturnsZero() {
        let points = [
            CLLocationCoordinate2D(latitude: 39.0,longitude: -77.0 ),
            CLLocationCoordinate2D(latitude: 39.1,longitude: -77.1 ),
            CLLocationCoordinate2D(latitude: 39.0,longitude: -77.1 ),
            CLLocationCoordinate2D(latitude: 39.1,longitude: -77.0 )
        ]
        XCTAssertEqual(Pasture.regionArea(locations: points), 0.0, accuracy: 0.0)
    }
    func testAcreConversion() {
        XCTAssertEqual(Pasture.areaInAcres(squareMeters: 4046.86), 1.0, accuracy: 0.0)
    }
}
