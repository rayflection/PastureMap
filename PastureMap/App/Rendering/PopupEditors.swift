//
//  PopupEditors.swift
//  PastureMap
//
//  Created by Mike Yost on 3/4/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit

class PopupEditors {    // NOT USED, YET
    func promptUserForBetterPastureName(_ pasture:PastureViewModel, presentingVC:UIViewController) {
        let ac = UIAlertController (title:"Pasture Name", message:"", preferredStyle: .alert)
        ac.addTextField { (textField) in
            textField.text = pasture.pastureName
        }
        ac.addAction(UIAlertAction(title:"OK", style: .destructive,
                                   handler: {(action) in
                                    if let textField = ac.textFields?.first {
                                        if textField.text != pasture.pastureName {
                                            if let pid=pasture.id, let newName=textField.text {
                                                pasture.pastureName = newName
                                                DBManager.shared().updatePastureName(pid, newName) // he should b'cast, vc's listen
                                                //renderCompletePolygon(pasture)
                                            }
                                        }
                                    }
        }))
        if UI_USER_INTERFACE_IDIOM() == .pad {
            ac.popoverPresentationController?.sourceView = pasture.sizeLabel
        } else {
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in }))
        }
        presentingVC.present(ac, animated:true, completion:nil)
    }
}
