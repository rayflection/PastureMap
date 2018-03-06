//
//  ListVC.swift
//  PastureMap
//
//  Created by Mike Yost on 2/19/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit

class ListVC: UITableViewController {

    var dbi:DataBaseInterface?

    var pastures:[PastureDataModel]=[]
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var sortByAreaButton: UIButton!
    @IBOutlet weak var sortByNameButton: UIButton!
    let up = " ⬆"
    let down = " ⬇"
    
    enum sortMethod {
        case no_sort
        case sort_by_name_asc
        case sort_by_name_desc
        case sort_by_area_asc
        case sort_by_area_desc
    }
    var currentSortMethod = sortMethod.no_sort
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = setUpRefreshControl()
        refresh()
    }
    func setUpRefreshControl() -> UIRefreshControl{
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refresh), for: UIControlEvents.allEvents)
        return rc
    }
    
    // ------------- button handlers
    @IBAction func loadButtonTapped(_ sender: Any) {
        refresh()
    }
    @objc func refresh() {
        refreshData()
        refreshUI()
    }
    func refreshData() {
        if let dbi = dbi {
            pastures = dbi.getAll()
        }
    }
    func refreshUI() {
        applySort()
        tableView.reloadData()
        self.refreshControl?.endRefreshing()
        updateTotalLabel(pastures.count)
    }
    func updateTotalLabel(_ count:Int) {
        var string=""
        if count == 1 {
            string = "1 Pasture"
        } else {
            string = "\(count) Pastures"
        }
        totalLabel.text = string
    }
    // MARK: Data souce
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pastures[section].vertices.count + 1
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return pastures.count
    }
    
    // MARK: Delegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisPasture = pastures[indexPath.section]
        if indexPath.row == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PastureHeaderCell") as? PastureHeaderCell {
                cell.render(thisPasture)
                return cell
            }
        } else {
            // each coordinate
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PastureCornerCell") as? PastureCornerCell {
                cell.render(thisPasture.vertices[indexPath.row-1])
                return cell
            }
        }
        return UITableViewCell()
    }
    
    // ------------------------------------------------------------------
    // MARK: Edit and Delete
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row == 0
    }
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.row == 0 {
            let pasture = pastures[indexPath.section]
            let edit = UITableViewRowAction(style:.default, title:"Edit") { (UITableViewRowActionStyle,IndexPath) in
                print("Edit pasture #: \(indexPath.section)")
                //
                // show a popup with a name editing field, persist change.
                let ac = UIAlertController (title:"Pasture Name", message:"", preferredStyle: .alert)
                ac.addTextField { (textField:UITextField) in
                    textField.text = pasture.name
                }
                ac.addAction(UIAlertAction(title:"OK", style: .destructive,
                                           handler: {(action) in
                                            if let textField = ac.textFields?.first {
                                                if textField.text != pasture.name {
                                                    if let pid=pasture.pasture_id, let newName=textField.text, let dbi=self.dbi {
                                                        pasture.name = newName
                                                        dbi.update(pid, name: newName)
                                                        self.refresh()
                                                    }
                                                }
                                            }
                }))
                if UI_USER_INTERFACE_IDIOM() == .pad {
                    ac.popoverPresentationController?.sourceView = tableView
                } else {
                    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in }))
                }
                self.present(ac, animated:true, completion:nil)
            }
            let delete = UITableViewRowAction(style:.default, title:"Delete") { (UITableViewRowActionStyle,IndexPath) in
                print("Delete pasture #: \(indexPath.section)")
                let ac = UIAlertController(title:"Delete pasture \(pasture.name)?", message:"Are you sure you want to delete this pasture?", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title:"Delete it!", style: .destructive,
                                           handler: {(action) in
                                            if let pid = pasture.pasture_id, let dbi=self.dbi {
                                                dbi.delete(pid)
                                                self.refresh()
                                            }
                }))
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in }))
                if UI_USER_INTERFACE_IDIOM() == .pad {
                    ac.popoverPresentationController?.sourceView = tableView
                }
                self.present(ac, animated:true, completion:nil)
            }
            return [edit,delete]
        }
        return nil
    }
    
    
    // ------------------------------------------------------------------
    // MARK: Button handlers - sort
    func applySort() {
        switch currentSortMethod {
        case .sort_by_name_asc:
            pastures.sort(by: { (one, two) -> Bool in
                return one.name < two.name  })
        case .sort_by_name_desc:
            pastures.sort(by: { (one, two) -> Bool in
                return one.name > two.name })
        case .sort_by_area_asc:
            pastures.sort(by: { (one, two) -> Bool in
                return AreaCalculator.regionArea(pastureData:one) < AreaCalculator.regionArea(pastureData:two) })
        case .sort_by_area_desc:
            pastures.sort(by: { (one, two) -> Bool in
                return AreaCalculator.regionArea(pastureData:one) > AreaCalculator.regionArea(pastureData:two) })
        default:
            pastures.sort(by: { (one, two) -> Bool  in
                one.pasture_id! < two.pasture_id! })
        }
    }
    @IBAction func sortByNameTapped(_ sender: Any) {
        sortByAreaButton.setTitle("Area", for: UIControlState.normal)
        switch currentSortMethod {
        case .sort_by_name_asc :
            currentSortMethod = .sort_by_name_desc
            sortByNameButton.setTitle("Name \(down)", for:UIControlState.normal)
        case .sort_by_name_desc :
            currentSortMethod = .no_sort
            sortByNameButton.setTitle("Name", for:UIControlState.normal)
        default:
            currentSortMethod = .sort_by_name_asc
            sortByNameButton.setTitle("Name \(up)", for:UIControlState.normal)
        }
        refreshUI()
    }
    @IBAction func sortByAreaTapped(_ sender: Any) {
        sortByNameButton.setTitle("Name", for: UIControlState.normal)
        switch currentSortMethod {
        case .sort_by_area_asc :
            currentSortMethod = .sort_by_area_desc
            sortByAreaButton.setTitle("Area \(down)", for:UIControlState.normal)
        case .sort_by_area_desc :
            currentSortMethod = .no_sort
            sortByAreaButton.setTitle("Area ", for:UIControlState.normal)
        default:
            currentSortMethod = .sort_by_area_asc
            sortByAreaButton.setTitle("Area \(up)", for:UIControlState.normal)
        }
        refreshUI()
    }
    
}

