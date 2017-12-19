//
//  ViewController.swift
//  PredixMobileSVCDemo
//
//  Created by Johns, Andy (GE Corporate) on 7/28/17.
//  Copyright © 2017 GE. All rights reserved.
//

import UIKit
import PredixSDK
import SafariServices

class ViewController: UIViewController {

    @IBOutlet var loginResult: UILabel!
    @IBOutlet var userInfo: UILabel!
    var authMan: AuthenticationManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //In this case we'll update this part of the UI via these notifications.
        NotificationCenter.default.addObserver(forName: Notification.Name.PredixAuthenticationComplete, object: nil, queue: OperationQueue.main) { (notification) in

            if let status = notification.userInfo?[authenticationNotificationCompletionStatusKey] as? AuthenticationManager.AuthenticationCompletionStatus {

                switch status {
                case .success(let type, let user):
                    if let userName = user.userName() {
                        self.userInfo.text = "Authenticated user: \(userName)\nAuthenticated via: \(type)"
                    }
                default: break
                }
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.PredixAuthenticationHasLoggedOut, object: nil, queue: OperationQueue.main) { (_) in

            self.userInfo.text = ""
        }
    }

    @IBAction func loginTapped(_ sender: Any) {

        self.loginResult.text = ""
        self.userInfo.text = ""

        //Creates an authentication manager configuration configured for your UAA instance.  The baseURL, clientId and clientSecret can also be defined in your info.plist if you wish but for simplicity I've added them to the config below.
        var configuration = AuthenticationManagerConfiguration()
        configuration.baseURL = URL(string: "https://predixsdkforiosexampleuaa.predix-uaa.run.aws-usw02-pr.ice.predix.io")
        configuration.clientId = "NativeClient"
        configuration.clientSecret = "test123"
        configuration.useTouchID = true

        // Create our AuthenticationManager with our configuration
        let manager = AuthenticationManager(configuration: configuration)

        // Create an OnlineAuthenticationHandler object -- in this case an our online handler subclass is designed to work with a UAA login web page. The redirectURI is setup in the UAA configuration
        let handler = SFAuthenticationSessionHandler(redirectURI: "predixsdk://predixsdkforios.io/authorization_grant")

        // Associate a RefreshAuthenticationHandler -- in this case our refresh handler is design to work with UAA.
        handler.refreshAuthenticationHandler = UAARefreshAuthenticationHandler()

        //associate our OnlineAuthenticationHandler with the AuthenticationManager
        manager.onlineAuthenticationHandler = handler
        handler.manager = manager

        //associate an AuthorizationHandler with the AuthenticationManager
        manager.authorizationHandler = UAAAuthorizationHandler()

        manager.authenticate { (status) in
            print("Authentication Completed")
            DispatchQueue.main.async {
                self.loginResult.text = "Authentication Status:\n \(status)"

                if case AuthenticationManager.AuthenticationCompletionStatus.failed(let error) = status {
                    // Failed, show error message
                    self.loginResult.text = "\(self.loginResult.text ?? "")\nError:\n \(error.localizedDescription)"
                }
            }
        }

        // retain a refererence to our AuthenticationManager
        self.authMan = manager

    }

    @IBAction func logoutTapped(_ sender: Any) {

        // perform logout
        self.authMan?.logout {
            DispatchQueue.main.async {
                self.loginResult.text = "Logout complete"
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
