//
//  DBManager.swift
//  PastureMap
//
//  Created by Mike Yost on 2/24/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import Foundation
import SQLite
import CoreLocation


class DBManager {
    private var db:Connection?
    private static var mgr = DBManager()
    static func shared() -> DBManager {
        return mgr
    }
    private let pastureTable = Table("pasture")
    private let cornerTable  = Table("corner")
    let pastureFK  = Expression<Int64>("pasture_id")
    let order      = Expression<Int64>("order")
    let latitude   = Expression<Double>("latitude")
    let longitude  = Expression<Double>("longitude")
    let id         = Expression<Int64>("id")
    let name       = Expression<String>("name")
    
    init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!

        do {
            db = try Connection("\(path)/db.sqlite3")
        } catch( _ ) {
            print ("create DB Connection error")
        }

        createDBTables()
    }
    func createDBTables() {


        // create a pasture table
        do {
            try db!.run(pastureTable.create(ifNotExists: true) { t in    // CREATE TABLE "pasture" (
                t.column(id,     primaryKey: .autoincrement) // "id" INTEGER PRIMARY KEY NOT NULL,
                t.column(name)                 //     "name" TEXT
                // t.column(createdAt, DateTime)
            })
        } catch ( _ ) {
            print ("Create pasture table error")
        }
        
        // create a fence_post table (corners, or vertices, or coordinates)
        do {
            try db!.run(cornerTable.create(ifNotExists:true) { t in
                t.column(id,         primaryKey: .autoincrement)
                t.column(pastureFK)
                t.column(order)
                t.column(longitude)
                t.column(latitude)
            })
        } catch ( _ ) {
            print("Create corner table error")
        }
    }
    // =================================================================
    // MARK: Pasture CRUD - called from app code
    func createPasture(_ viewModel: PastureViewModel) {
        let corners = viewModel.polygonVertices.map { $0.coordinate }
        let pdm = PastureDataModel(corners)
        // write pdm to the database
        do {
            let row = try db!.run(pastureTable.insert(name <- "pasture_1")) // @TODO _ Increment NAME!!
            pdm.pasture_id = row
            print("inserted id: \(row)")
        } catch {                                 // @TODO - better catch, more specific
            print("insertion pasture failed: \(error)") //Just show error, don't return anything.
        }
        
        // write the corners to the database
        if let pk = pdm.pasture_id {
            do {
                var rank:Int64 = 0
                for coord in corners {
                    try db!.run(cornerTable.insert(
                        pastureFK <- pk,
                        order     <- rank,
                        longitude <- coord.latitude,
                        latitude  <- coord.longitude
                    ))
                    rank = rank + 1
                }   // for
            } catch {                 // @TODO - better catch, more specific
                print("Insert corner failed: \(error).")
            }
        }
        viewModel.id = pdm.pasture_id
        viewModel.isComplete = true

    }
    //
    // WRITE ME!  - also use the 2nd panel to fetch the whole database so I can see it.
    //
    func getPastures() -> [PastureDataModel] {
        return [PastureDataModel([CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)])] // just to compile
    }
    func getPasture(_ pastureID:Int) -> PastureDataModel {
        return PastureDataModel()           // just to compile
    }
    func deletePasture(_ pastureID:Int) {
        // delete this sucker
    }
    func updatePasture(_ pasture:PastureDataModel) {
        pasture.save() // just to compile.
    }
}

