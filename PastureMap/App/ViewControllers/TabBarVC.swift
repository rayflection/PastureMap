//
//  TabBarVC.swift
//  PastureMap
//
//  Created by Mike Yost on 3/5/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit
import CoreLocation

class TabBarVC: UITabBarController {
    var mapVC:MapVC?
    var listVC:ListVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let nav = self.viewControllers?[0] as? UINavigationController {
            if let map = nav.viewControllers[0] as? MapVC {
                mapVC = map
                let mapDBFacade = DBFacade(map)
                map.dbi = mapDBFacade
            }
        }
        if let list = self.viewControllers?[1] as? ListVC {
            listVC = list
            let listDBFacade = DBFacade(list)
            list.dbi = listDBFacade
            NotificationCenter.default.addObserver(self, selector: #selector(handleDBChangeNotification), name: NSNotification.Name(rawValue: NotificationKey.DatabaseChanged), object: nil)
        }
    }
    @objc func handleDBChangeNotification(note:Notification) {
        print("Got notification: \(note)")
        
        if (note.object as? ListVC) != nil {
            if let mapVC = mapVC {
                mapVC.refreshAllPastures()
            }
        } else if (note.object as? MapVC) != nil {
            if let listVC = listVC {
                listVC.refresh()
            }
        } else {
            // huh?
        }
    }
}

