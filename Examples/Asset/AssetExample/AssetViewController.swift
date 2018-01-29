//
//  AssetViewController.swift
//  AssetExample
//
//  Created by Jeremy Osterhoudt on 1/25/18.
//  Copyright © 2018 Jeremy Osterhoudt. All rights reserved.
//

import UIKit
import PredixSDK

class AssetViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendCreateAssetRequest(_ sender: Any) {
        var config : AssetManagerConfiguration = AssetManagerConfiguration()
        config.tenantId = "4532487d-70c3-4bb8-889d-6e04e8edadc0"
        config.URL = "https://predix-asset.run.aws-usw02-pr.ice.predix.io"

        let manager = AssetManager(configuration: config)
        
        
//        manager.fetchAssets(assetType: "locomotives", query: AssetQuery()) { (asset, status) in
//            print(status)
//            print(asset)
//        }
        manager.createAssets(jsonAssets: [["uri": "/locomotives/1",
                                           "type": "Diesel-electric",
                                           "model": "ES44AB",
                                           "manufacturer": "/manufacturers/GE",
                                           "engine": "/engines/v12-1",
                                           "installedOn": "01/12/2005",
                                           "coords": [
                                            "lat": 33.914605,
                                            "lng": -117.253374
            ]
            ]]) { (asset, status) in
                print(status)
        }
    }
}
