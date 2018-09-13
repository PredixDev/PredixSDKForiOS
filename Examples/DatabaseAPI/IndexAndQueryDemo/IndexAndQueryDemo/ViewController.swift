//
//  ViewController.swift
//  IndexAndQueryDemo
//
//  Created by Johns, Andy (GE Corporate) on 1/9/18.
//  Copyright © 2018 GE. All rights reserved.
//

import UIKit
import PredixSDK

fileprivate let indexName = "wordIndex"
fileprivate let wordKey = "word"
fileprivate let definitionKey = "definition"


class ViewController: UITableViewController {

    var database: Database?

    var currentSearchResults = [QueryResultRow]()
    var alert: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.openDatabase()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openDatabase() {
        
        do {
            // Create our index
            let index = Database.Index(name: indexName, version: "1.0", map: { (document, addIndexRow) in
                // This index will have a row for each document, keyed by the "word", and having a value of the "definition"
                if let word = document[wordKey] {
                    addIndexRow(word, document[definitionKey])
                }
            })
            
            // Creates a dabase configuration with default name and location, and the provided index(s)
            let configuration = Database.OpenDatabaseConfiguration(indexes: [index])
            
            // Open the database
            self.database = try Database.open(with: configuration, create: true)
            
            self.createSampleDocumentsIfNeeded()
            
        } catch let error {
            Logger.error("Error opening database: \(error)")
        }
    }

    func createSampleDocumentsIfNeeded() {

        // search for the word "a", which we know is in the dictionary....
        let query = QueryByKeyList(keys: ["a"])
        
        self.database?.runQuery(on: indexName, with: query, completionHandler: { results in
            
            if results.count == 0 {
                // No results means the inital database for this demo has not been created, so sample data will now be created.
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Please wait...", message: "Creating sample documents", preferredStyle: UIAlertController.Style.alert)
                    self.present(alert, animated: true, completion: {
                        self.createSampleDocuments()
                    })
                    self.alert = alert
                }
            } else {
                // The database has already been loaded, so we'll continue with page initialization
                self.queryDatabase("")
            }
        })
    }
    
    func createSampleDocuments() {

        // For this simple demonstration we'll create the sample data from the information in the "dictionary.json" file.
        let dictionaryFile = Bundle.main.resourceURL!.appendingPathComponent("dictionary.json")
        let dictionaryData = try? Data(contentsOf: dictionaryFile)
        let rawDictionary = try! JSONSerialization.jsonObject(with: dictionaryData!, options: JSONSerialization.ReadingOptions(rawValue: 0))
        let sampleData = rawDictionary as! [String: String]
        
        var rowsAdded = 0
        
        for (word, definition) in sampleData {

            // create a simple document.
            // The id of the document will be automatically generated
            // the only data in the document will be the word and the definition
            let document: Document = [wordKey: word, definitionKey: definition]

            // add the document to the database
            self.database?.add(document, completionHandler: { _ in
                
                rowsAdded += 1
                if rowsAdded >= sampleData.count {
                    // if we've added all the rows we expect, then continue with page initialization
                    self.queryDatabase("")
                }
            })
        }
    }
    
    func queryDatabase(_ searchText: String) {
        
        // Query the index by range. This will find all keys between the start and end keys, inclusive.
        let endKey = calculateEndKey(startKey: searchText)
        let query = QueryByKeyRange.init(startKey: searchText, endKey: endKey)
        
        self.database?.runQuery(on: indexName, with: query, completionHandler: { resultsEnumerator in
            
            let results = [QueryResultRow](resultsEnumerator)

            DispatchQueue.main.async {
                self.processResults(results)
            }
        })
    }
    
    func processResults(_ results: [QueryResultRow]) {
        
        Logger.info("Found \(results.count) words")
        self.currentSearchResults = results
        self.tableView.reloadData()
        self.alert?.dismiss(animated: true, completion: nil)
    }
    
    func calculateEndKey(startKey: String) -> String? {
        
        guard !startKey.isEmpty else {
            return nil
        }
        
        var startKey = startKey
        
        let lastChar = startKey.removeLast()
        
        guard let unicode = lastChar.unicodeScalars.first else {
            return nil
        }
        
        if case "a"..<"z" = unicode {
            if let next = UnicodeScalar(unicode.value + 1) {
                return startKey + String(next)
            }
        }
        return nil
    }

}

// MARK: UITableViewDataSourceDelegate implementation
extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentSearchResults.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        if indexPath.row < currentSearchResults.count {
            
            let result = currentSearchResults[indexPath.row]
            cell.textLabel?.text = result.key as? String
            cell.detailTextLabel?.text = result.value as? String
        }
        
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? UITableViewCell,
              let detailVC = segue.destination as? DetailViewController,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        if indexPath.row < currentSearchResults.count {
            // Since we included the definition field in our index value,
            // the search results have all the information we need to display the detail page.
            detailVC.word = currentSearchResults[indexPath.row].key as? String
            detailVC.definition = currentSearchResults[indexPath.row].value as? String
        }
    }
}

extension ViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // with each change in the search bar, we requery the database.
        queryDatabase(searchText.lowercased())
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
