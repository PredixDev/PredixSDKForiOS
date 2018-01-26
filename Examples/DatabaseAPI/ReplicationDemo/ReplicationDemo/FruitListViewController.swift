//
//  ViewController.swift
//  ReplicationDemo
//
//  Created by Johns, Andy (GE Corporate) on 1/9/18.
//  Copyright © 2018 GE. All rights reserved.
//

import UIKit
import PredixSDK

let fruitNameKey = "fruit"
let notesKey = "notes"

class FruitListViewController: UITableViewController {

    var database: Database?
    var rowCount = 0
    
    var replicationDisplay: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {

        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? UITableViewCell,
            let detailVC = segue.destination as? DetailViewController,
            let indexPath = tableView.indexPath(for: cell) else {
                return
        }
        
        detailVC.database = self.database
        detailVC.documentIdentifier = "\(indexPath.row)"
    }

}

// MARK: UITableViewDataSourceDelegate implementation
extension FruitListViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rowCount
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        // fetch the document for this row from the database
        self.database?.fetchDocument("\(indexPath.row)") { document in
            
            // when we have the document, update the cell text label with the data from the document
            cell.textLabel?.text = document?[fruitNameKey] as? String
            if document?.attachments.count ?? 0 > 0, let imageData = document?.attachments[0].data {
                cell.imageView?.image = UIImage(data: imageData)
            } else {
                cell.imageView?.image = UIImage()
            }
            cell.setNeedsLayout()
        }
        
        return cell
    }
}

