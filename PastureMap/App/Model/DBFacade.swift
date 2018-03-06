//
//  DBFacade.swift
//  PastureMap
//
//  Created by Mike Yost on 3/5/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit
import CoreLocation

//
// protocol for db functions, inject an object that follows the protocol to main VC's
//
protocol DataBaseInterface {
    func create(_ pasture:PastureViewModel)
    func getAll() -> [PastureDataModel]
    func delete(_ pastureID:Int64)
    func update(_ pastureID:Int64, name:String)
    func update(_ pastureID:Int64, rank:Int64, coordinate:CLLocationCoordinate2D)
}
protocol DataBaseManagerInterface {
    func createPasture(_ viewModel: PastureViewModel)
    func getAllPastures() -> [PastureDataModel]
    func deletePasture(_ pastureID:Int64 )
    func updatePastureCoordinate(_ pasture_id:Int64,_ theRank:Int64,_ coord:CLLocationCoordinate2D)
    func updatePastureName(_ pastureID:Int64, _ name:String)
}
class DBFacade:DataBaseInterface {
    private var caller:UIViewController?
    init(_ callingVC:UIViewController) {
        caller = callingVC
    }
    private func activeDB() -> DataBaseManagerInterface {
        //
        // This is a great spot to choose what database implementation to use
        //
        return DBManager_SQLite.shared()
        // return DBManager_RealmIO.shared()
    }
    // ---------------------------------------
    // MARK: CRUD
    func create(_ pasture:PastureViewModel) {       // this populates/updates the viewModel with id,name
        activeDB().createPasture(pasture)
        post()
    }
    func getAll() -> [PastureDataModel] {
        return activeDB().getAllPastures()
    }
    func delete(_ pastureID:Int64) {
        activeDB().deletePasture(pastureID)
        post()
    }
    func update(_ pastureID:Int64, name:String) {
        activeDB().updatePastureName(pastureID,name)
        post()
    }
    func update(_ pastureID:Int64, rank:Int64, coordinate:CLLocationCoordinate2D) {
        activeDB().updatePastureCoordinate(pastureID,rank,coordinate)
        post()
    }
    private func post() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKey.DatabaseChanged), object: caller)
    }
}
