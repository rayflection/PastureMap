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
    let rank       = Expression<Int64>("rank")
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
                t.column(rank)
                t.column(longitude)
                t.column(latitude)
            })
        } catch ( _ ) {
            print("Create corner table error")
        }
    }
    // =================================================================
    // MARK: Pasture CRUD - called from app code
    func createPasture(_ corners: [CLLocationCoordinate2D]) -> PastureDataModel {
        let pdm = PastureDataModel(corners)
        // write pdm to the database
        do {
            let row = try db!.run(pastureTable.insert(name <- "pasture_1")) // @TODO _ Increment NAME!!
            pdm.pasture_id = Int(row)
            print("inserted id: \(row)")
        } catch {
            print("insertion failed: \(error)")
        }
        return pdm
    }
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
    // ------------------------------------------
    // MARK: Pasture CRUD - actual db writes
    func createDBPasture(_ model: PastureDataModel) {
        
    }
}

