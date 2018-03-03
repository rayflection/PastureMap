//
//  SecondViewController.swift
//  PastureMap
//
//  Created by Mike Yost on 2/19/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit

class ListVC: UITableViewController {

    //
    // @TODO - edit name from here
    // @TODO - each sort button: off, asc, desc
    //
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
    @IBAction func loadButtonTapped(_ sender: Any) {
        refresh()
    }
    @objc func refresh() {
        refreshData()
        refreshUI()
    }
    func refreshData() {
        pastures = DBManager.shared().getAllPastures()
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

