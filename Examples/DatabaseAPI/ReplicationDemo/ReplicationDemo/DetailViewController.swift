//
//  DetailViewController.swift
//  DatabaseDemoWithImages
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
    
    @IBOutlet var noteLabel: UILabel!
    @IBOutlet var fruitNameLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard let documentId = self.documentIdentifier else {
            return
        }
        
        // Get a reference to the database if needed
        if self.database == nil {
            self.database = Database.openedWith(Database.OpenDatabaseConfiguration.default)
        }
        
        // fetch the document
        self.database?.fetchDocument(documentId, completionHandler: { document in
            self.document = document
            
            DispatchQueue.main.async {
                self.populateView()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func populateView() {
        
        guard let document = self.document else {
            
            // if no document is available, clear all the fields
            self.fruitNameLabel.text = ""
            self.noteLabel.text = ""
            return
        }
        
        self.fruitNameLabel.text = document[fruitNameKey] as? String
        self.noteLabel.text = document[notesKey] as? String
        if document.attachments.count > 0, let data = document.attachments[0].data {
            self.imageView.image = UIImage(data: data)
        }
    }
}

