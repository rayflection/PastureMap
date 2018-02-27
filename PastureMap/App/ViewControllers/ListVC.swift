//
//  SecondViewController.swift
//  PastureMap
//
//  Created by Mike Yost on 2/19/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit

class ListVC: UITableViewController {

    var pastures:[PastureDataModel]=[]
    @IBOutlet weak var totalLabel: UILabel!
    
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
        pastures = DBManager.shared().getAllPastures()
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
}

