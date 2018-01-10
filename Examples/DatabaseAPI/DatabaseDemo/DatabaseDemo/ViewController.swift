//
//  ViewController.swift
//  DatabaseDemo
//
//  Created by Johns, Andy (GE Corporate) on 1/9/18.
//  Copyright © 2018 GE. All rights reserved.
//

import UIKit
import PredixSDK

let fruitNameKey = "fruit"
let notesKey = "notes"

class ViewController: UITableViewController {

    var database: Database?
    var rowCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        do {
            // Open the database
            self.database = try Database.open(with: Database.OpenDatabaseConfiguration.default, create: true)
            
            // see if we have document "0", if so we've already loaded the sample data
            self.database?.fetchDocument("0", completionHandler: { document in
                if document == nil {
                    self.loadSampleData()
                } else {
                    self.rowCount = self.createSampleData().count
                    self.tableView.reloadData()
                }
                
            })
        } catch let error {
            Logger.error("Error opening database: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadSampleData() {
        
        let sampleData = createSampleData()
        
        self.rowCount = sampleData.count
        
        var rowsAdded = 0
        
        for rowIndex in 0..<sampleData.count {

            let item = sampleData[rowIndex]
            
            // create a simple document.
            // The id of the document will be the row number,
            // the only data in the document will be the sample data item.
            let document: Document = ["id": "\(rowIndex)", fruitNameKey: item, notesKey: ""]

            // add the document to the database
            self.database?.add(document, completionHandler: { _ in
                
                // if we've added all the rows we expect, then refresh the page
                rowsAdded += 1
                if rowsAdded >= self.rowCount {
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    private func createSampleData() -> [String] {

        return ["Papaya", "Peach", "Pitaya", "Passion fruit", "Banana", "Pear", "Mango", "Cherry", "Plum", "Apricot", "Lemon", "Avocado", "Fig", "Lychee", "Coconut", "Cantaloupe", "Tangerine", "Clementine", "Pineapple", "Grape", "Grapefruit", "Pomelo", "Orange", "Date palm", "Watermelon", "Kumquat", "Breadfruit", "Blueberry", "Honeydew", "Lime", "Raspberry", "Strawberry", "Blueberry"]
    }
}

// MARK: UITableViewDataSourceDelegate implementation
extension ViewController {
    
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
            cell.detailTextLabel?.text = document?[notesKey] as? String
            cell.setNeedsLayout()
        }
        
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? UITableViewCell,
              let detailVC = segue.destination as? DetailViewController,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        detailVC.documentIdentifier = "\(indexPath.row)"
    }
}

