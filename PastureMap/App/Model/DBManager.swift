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
    let pasturePK  = Expression<Int64>("pasturePK")
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
            try db!.run(pastureTable.create(ifNotExists: true) { t in
                t.column(pasturePK,     primaryKey: .autoincrement)
                t.column(name)
                // t.column(createdAt, DateTime)    // @TODO
            })
        } catch ( _ ) {
            print ("Create pasture table error")
        }
        
        // create a fence_post table (corners, or vertices, or coordinates)
        do {
            try db!.run(cornerTable.create(ifNotExists:true) { t in
                t.column(pasturePK,         primaryKey: .autoincrement)
                t.column(pastureFK)
                t.column(rank)
                t.column(latitude)
                t.column(longitude)
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
            let row = try db!.run(pastureTable.insert(name <- "new_pasture"))
            pdm.pasture_id = row
            pdm.name = "pasture_\(row)"
            updatePastureName(row, pdm.name)
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
                        self.rank <- rank,
                        latitude  <- coord.latitude,
                        longitude <- coord.longitude
                    ))
                    rank = rank + 1
                }   // for
            } catch {                 // @TODO - better catch, more specific
                print("Insert corner failed: \(error).")
            }
        }
        if let pastID = pdm.pasture_id {
            viewModel.id = pdm.pasture_id
            viewModel.pastureName = pdm.name
            viewModel.setIsComplete(pastureID: pastID)
        }
    }
    // -------------------------------
    func getAllPastures() -> [PastureDataModel] {
        var pastureDBModels:[PastureDataModel]=[]
        if db != nil {
            do {
                let all = Array(try db!.prepare(pastureTable))
                // unpack into PastureDataModel instances
                for pasture in all {
                    let pastureID = pasture[pasturePK]
                    let aPastureModel = PastureDataModel(pastureID)
                    aPastureModel.name = pasture[name]
                    pastureDBModels.append(aPastureModel)
                
                    for coords in try db!.prepare(cornerTable.select(rank,latitude,longitude)
                        .filter(pastureFK == pastureID)
                        .order(self.rank.asc)) {
                        let latitude  = coords[self.latitude]
                        let longitude = coords[self.longitude]
                            let loc2d = CLLocationCoordinate2D(latitude:latitude, longitude: longitude)
                            aPastureModel.vertices.append(loc2d)
                    }
                }       // each row in pasture table
            } catch {
                print ("Fetch all pastures error")
            }
        }
        return pastureDBModels
    }
    
    // ------------------------------------------
    // Who would call this? What's the Use case?
    func getPasture(_ pastureID:Int) -> PastureDataModel {
        //     let joinTable = pastureTable.join(cornerTable, on: pastureFK == pastureTable[id])
        return PastureDataModel()           // just to compile
    }
    // -------------------------------------------
    // This would get called when I let the user delete a pasture, NIY.
    func deletePasture(_ pastureID:Int64 ) {
        let pasture = pastureTable.filter(pasturePK == pastureID)
        let corner  = cornerTable.filter(pastureFK == pastureID)
        do {
            try db?.run(pasture.delete())
            try db?.run(corner.delete())
        } catch {
            print ("delete error: \(error)")
        }
    }
    // ----------------------------------------------
    // This gets called every time user moves a fence post, to update the corners.
    // Or if they change the name of the pasture (NIY)
    func updatePastureCoordinate(_ pasture_id:Int64,_ theRank:Int64,_ coord:CLLocationCoordinate2D) {
        
        print("Update called.")
        let fencePost = cornerTable.filter(pastureFK == pasture_id && rank==theRank)
      //  try db.run(alice.update(email <- "alice@me.com"))
        // UPDATE "users" SET "email" = 'alice@me.com' WHERE ("id" = 1)
        do {
            let numberOfRows = try db?.run(fencePost.update(latitude <- coord.latitude, longitude <- coord.longitude ))
            if numberOfRows == 1 {
                print("updated fencePost success")
            } else {
                print("Number updated is \(String(describing: numberOfRows))")
            }
        } catch {
            print("update failed: \(error)")
        }
    }
    func updatePastureName(_ pastureID:Int64, _ name:String) {
        do {
            print("Update pasture \(pastureID) name to \(name)")
            try db?.run(pastureTable.filter(pasturePK == pastureID).update(self.name <- name))
        } catch {
            print("Update Name failed: \(error)")
        }
    }
}

