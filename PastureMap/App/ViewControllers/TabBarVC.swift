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

    override func viewDidLoad() {
        super.viewDidLoad()

        if let nav = self.viewControllers?[0] as? UINavigationController {
            if let map = nav.viewControllers[0] as? MapVC {
                let mapDBFacade = DBFacade(map)
                map.dbi = mapDBFacade
            }
        }
        if let list = self.viewControllers?[1] as? ListVC {
            let listDBFacade = DBFacade(list)
            list.dbi = listDBFacade
        }
    }
}

