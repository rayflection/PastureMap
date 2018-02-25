//
//  PastureHeaderCell.swift
//  PastureMap
//
//  Created by Mike Yost on 2/25/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit
import CoreLocation

class PastureHeaderCell: UITableViewCell {

    @IBOutlet weak var pastureID: UILabel!
    @IBOutlet weak var area: UILabel!
    
    func render(_ pasture:PastureDataModel) {
        pastureID.text = "\(pasture.pasture_id ?? -1)"
        area.text = "\(PastureRenderer.formattedAcres(pasture: pasture)) acres."
    }
}
