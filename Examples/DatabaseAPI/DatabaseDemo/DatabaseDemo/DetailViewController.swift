//
//  DetailViewController.swift
//  DatabaseDemo
//
//  Created by Johns, Andy (GE Corporate) on 1/10/18.
//  Copyright © 2018 GE. All rights reserved.
//

import UIKit
import PredixSDK

class DetailViewController: UIViewController {

    var documentIdentifier: String?
    var database: Database?
    var document: Document?
    
    let dateFormatter = DateFormatter()
    
    @IBOutlet var createDateLabel: UILabel!
    @IBOutlet var identifierLabel: UILabel!
    @IBOutlet var updateDateLabel: UILabel!
    @IBOutlet var noteText: UITextView!
    @IBOutlet var fruitNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        guard let documentId = self.documentIdentifier else {
            return
        }
        
        // Get a reference to the database
        self.database = Database.openedWith(Database.OpenDatabaseConfiguration.default)
        
        // fetch the document
        self.database?.fetchDocument(documentId, completionHandler: { document in
            self.document = document
            self.populateView()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func populateView() {
        
        guard let document = self.document else {
            
            // if no document is available, clear all the fields
            self.identifierLabel.text = ""
            self.createDateLabel.text = ""
            self.updateDateLabel.text = ""
            self.noteText.text = ""
            return
        }
        
        self.identifierLabel.text = document.id
        
        populate(field: self.createDateLabel, withDate: document.metaData.createDate)
        populate(field: self.updateDateLabel, withDate: document.metaData.lastChange)
        
        self.fruitNameLabel.text = document[fruitNameKey] as? String
        self.noteText.text = document[notesKey] as? String
    }
    
    func populate(field: UILabel, withDate: Date?) {
        if let date = withDate {
            field.text = self.dateFormatter.string(from: date)
        } else {
            field.text = "None"
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        
        self.noteText.resignFirstResponder()
        
        guard let document = self.document else {
            return
        }
        
        // Update the document
        document[notesKey] = self.noteText.text
        
        self.saveDocumentChanges(document)

    }
    
    func saveDocumentChanges(_ document: Document) {
        
        // Save the changed document
        self.database?.save(document, completionHandler: { result in
            
            // Handle results of the update
            
            switch result {
            case .failed(let error):
                // the update failed. Log the error and inform user
                Logger.error("Save failed: \(error)")
                self.showAlert("Save failed")
                
            case .success(let document):
                // the update succeeded, inform the user and update the UI
                self.showAlert("Saved")
                self.document = document
                self.populateView()
                
            }
        })
    }
        
    func showAlert(_ message: String) {
        
        // show a message, then automatically dismiss the message after one second
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        self.present(alert, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                alert.dismiss(animated: true, completion: nil)
            })
        })

    }
}
