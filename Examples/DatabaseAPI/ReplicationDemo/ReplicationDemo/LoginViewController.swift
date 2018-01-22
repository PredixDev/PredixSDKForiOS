//
//  LoginViewController.swift
//  ReplicationDemo
//
//  Created by Johns, Andy (GE Corporate) on 1/17/18.
//  Copyright © 2018 GE. All rights reserved.
//

import UIKit
import PredixSDK

// Intial startup ViewController, will prompt for user login, and then start replication
// To show replication better, any existing database will be deleted when the ViewController is loaded,
// Then replication will download a fresh database each time.

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    fileprivate var credentialProvider: AuthenticationCredentialsProvider?
    fileprivate var authenticationManager: AuthenticationManager?
    
    fileprivate var database: Database?
    fileprivate var rowCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.signInButton.isEnabled = false
        self.statusLabel.text = "Retrieving configured UAA URL"
        
        DispatchQueue.main.async {
            self.setupDatabase()
            self.setupAuthentication()
        }
    }
    
    func setupDatabase() {
        
        // For this demo we're showing replication from the server, so we'll ensure
        // the local database doesn't exist first.
        //
        // Obviously in a real application you wouldn't delete the database every launch.
        Database.delete(Database.OpenDatabaseConfiguration.default)
        
        // now open the database normally
        do {
            // Open the database
            let database = try Database.open(with: Database.OpenDatabaseConfiguration.default, create: true)
            // set self to replication delegate, so we can show replication status information
            // see ReplicationStatusDelegate extension below for these methods.
            database?.replicationStatusDelegate = self
            
            self.database = database
            
        } catch let error {
            Logger.error("Error opening database: \(error)")
        }
    }
    
    func setupAuthentication() {
        //Creates an authentication manager configuration configured for your UAA instance.
        //The PredixSync URL, Client Id, and Client Secret are loaded from the info.plist.
        
        guard let predixSyncURL = Utilities.predixSyncURL else {
            updateStatusText(message: "Predix Sync URL not configured in info.plist")
            return
        }
        
        guard let authenticationURL = AuthenticationManagerConfiguration.fetchAuthenticationBaseURL(serverEndpointURL: predixSyncURL)  else {
            updateStatusText(message: "Unable to retrieve configured UAA URL.")
            return
        }

        self.signInButton.isEnabled = true
        self.signInButton.setNeedsDisplay()
        self.updateStatusText(message: "")
        
        var configuration = AuthenticationManagerConfiguration()
        configuration.baseURL = authenticationURL
        
        //Create an authentication manager with our UAA configuration, set UAA as our authorization source, set the online handler so that the manager knows we want to autenticate online
        self.authenticationManager = AuthenticationManager(configuration: configuration)
        
        //Create an online handler so that we can tell the authentication manager we want to authenticate online
        let onlineHandler = UAAServiceAuthenticationHandler()
        onlineHandler.authenticationServiceDelegate = self
        
        self.authenticationManager?.onlineAuthenticationHandler = onlineHandler
        
        //Use the PredixSync authorization handler, to enable our user to replication with PredixSync
        self.authenticationManager?.authorizationHandler = PredixSyncAuthorizationHandler()
        
        self.performLogin()

    }
    
    @IBAction func signInPressed(_ sender: Any) {
        
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()

        //Give the username and password to the credential provider
        if let user = self.usernameTextField.text, let pass = self.passwordTextField.text, !user.isEmpty, !pass.isEmpty {
            self.updateStatusText(message: "Signing in...")
            self.credentialProvider?(user, pass)
        } else {
            self.updateStatusText(message: "Invalid username and/or password")
        }
    }
    
    fileprivate func updateStatusText(message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.statusLabel.setNeedsDisplay()
        }
    }
    
    private func performLogin() {
        
        //Tell authentication manager we are ready to authenticate, once we call authenticate it will call our delegate with the credential provider
        authenticationManager?.authenticate { status in
            switch status {
            case .success(_, _):
                self.updateStatusText(message: "Authenticated")
                // Now that we're authenticated, start replication
                self.startReplication()
                break
            default: break
            }
        }
    }
    
    private func startReplication() {
        
        guard let predixSyncURL = Utilities.predixSyncURL else {
            return
        }
        
        // start replication, for this example we're doing a non-repeating, one-direction replication.
        let replicationConfig = Database.ReplicationConfiguration.oneTimeServerToClientReplication(with: predixSyncURL)
        self.updateStatusText(message: "Starting replication")
        self.database?.startReplication(with: replicationConfig)
        
        // See ReplicationStatusDelegate methods below to follow the logic after replication starts
    }
    
    //MARK: Transition to fruit list ViewController, after replication completes.
    fileprivate func showFruitList() {
        
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showFruitList", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let fruitListController = segue.destination.childViewControllers.first as? FruitListViewController else {
            return
        }
        
        fruitListController.rowCount = self.rowCount
        fruitListController.database = self.database
    }
}

//MARK: ServiceBasedAuthenticationHandlerDelegate

// These methods handle login

extension LoginViewController: ServiceBasedAuthenticationHandlerDelegate {
    public func authenticationHandler(_ authenticationHandler: PredixSDK.AuthenticationHandler, didFailWithError error: Error) {
        self.updateStatusText(message: "Authentication failed: \(error)")
    }
    
    public func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        self.updateStatusText(message: "Invalid username and/or password")
    }
    
    public func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        self.credentialProvider = completionHandler
    }
}

//MARK: ReplicationStatusDelegate

// extension to handle the ReplicationStatusDelegate.
// These methods provide information for the replication process

extension LoginViewController: ReplicationStatusDelegate {
    
    // Since this replication is one-direction, we won't have any "sending"
    func database(_ database: Database, replicationIsSending details: ReplicationDetails, sent: Int, totalToSend: Int) {
    }

    // This method is called as each batch of data is received.
    func database(_ database: Database, replicationIsReceiving details: ReplicationDetails, received: Int, totalToReceive: Int) {
        
        Logger.info("\(#function):  \(received) :  \(totalToReceive)")
        self.rowCount = totalToReceive - 1
        self.updateStatusText(message: "Received \(received) of \(totalToReceive)")
    }
    
    // Replication failure. The Error object will contain details as to the error
    func database(_ database: Database, replicationFailed details: ReplicationDetails, error: Error) {
        
        Logger.error("\(#function): \(error)")
        self.rowCount = 0
        self.updateStatusText(message: "Replication failed: \(error)")

    }
    
    // Called replication is complete, even if replication failed.
    func database(_ database: Database, replicationDidComplete details: ReplicationDetails) {
        
        Logger.info("\(#function): rows: \(self.rowCount)")
        if self.rowCount > 0 {
            self.updateStatusText(message: "Replication completed")
            self.showFruitList()
        }

    }
}
