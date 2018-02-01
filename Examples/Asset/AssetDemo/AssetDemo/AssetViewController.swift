//
//  AssetViewController.swift
//  AssetDemo
//
//  Created by Jeremy Osterhoudt on 1/30/18.
//  Copyright © 2018 General Electric. All rights reserved.
//

import UIKit
import PredixSDK

class AssetViewController: UIViewController {

    @IBOutlet weak var fetchAssetTextArea: UITextView!
    @IBOutlet weak var createAssetTextArea: UITextView!
    @IBOutlet weak var assetTypeTextField: UITextField!
    @IBOutlet weak var createAssetStatusLabel: UILabel!
    private var assetManager: AssetManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createAssetTextArea.text = """
        [{"coords":{"lat":33.914605000000002,"lng":-117.25337399999999},"uri":"/locomotives/1","installedOn":"01/12/2005",
            "type":"Diesel-electric","manufacturer":"/manufacturers/GE","engine":"/engines/v12-1"
        }]
        """

        let configuration = AssetManagerConfiguration(instanceID: "4532487d-70c3-4bb8-889d-6e04e8edadc0")
        assetManager = AssetManager(configuration: configuration)
        assetTypeTextField.text = "locomotives"
    }
    
    @IBAction func createAssetPressed(_ sender: Any) {
        createAssetStatusLabel.text = "Attempting to create asset..."
        if let data = createAssetTextArea.text.data(using: String.Encoding.utf8), let rawJson = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)), let json = rawJson as? [[String: Any]] {
            assetManager?.createAssets(jsonAssets: json , completionHandler: { (asset, status) in
                DispatchQueue.main.async {
                    self.createAssetStatusLabel.text = "Asset Status: \(status)"
                }
            })
        } else {
            createAssetStatusLabel.text = "error, invalid JSON received!"
        }
    }
    
    @IBAction func fetchAssetPressed(_ sender: Any) {
        fetchAssetTextArea.text = "Fetching Asset..."
        assetManager?.fetchAssets(assetType: assetTypeTextField.text ?? "", query: AssetQuery(), completionHandler: { (asset, status) in
            DispatchQueue.main.async {
                self.fetchAssetTextArea.text = asset?.results.description ?? status.description
            }
        })
    }
}
