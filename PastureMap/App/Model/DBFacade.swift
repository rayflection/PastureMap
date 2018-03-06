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

class DBFacade:DataBaseInterface {
    private var caller:UIViewController?
    init(_ callingVC:UIViewController) {
        caller = callingVC
    }
    func create(_ pasture:PastureViewModel) {       // should this return a pastureDataModel?
        DBManager.shared().createPasture(pasture)
        post()
    }
    func getAll() -> [PastureDataModel] {
        return DBManager.shared().getAllPastures()
    }
    func delete(_ pastureID:Int64) {
        DBManager.shared().deletePasture(pastureID)
        post()
    }
    func update(_ pastureID:Int64, name:String) {
        DBManager.shared().updatePastureName(pastureID,name)
        post()
    }
    func update(_ pastureID:Int64, rank:Int64, coordinate:CLLocationCoordinate2D) {
        DBManager.shared().updatePastureCoordinate(pastureID,rank,coordinate)
        post()
    }
    private func post() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKey.DatabaseChanged), object: caller)
    }
}
