//
//  DetailViewController.swift
//  IndexAndQueryDemo
//
//  Created by Johns, Andy (GE Corporate) on 1/10/18.
//  Copyright © 2018 GE. All rights reserved.
//

import UIKit
import PredixSDK

class DetailViewController: UIViewController {

    var word: String?
    var definition: String?
    @IBOutlet var definitionText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.populateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.definitionText.setContentOffset(CGPoint.zero, animated: false)
    }
    
    func populateView() {
        
        self.title = word
        self.definitionText.text = self.definition
        
    }
    
}
