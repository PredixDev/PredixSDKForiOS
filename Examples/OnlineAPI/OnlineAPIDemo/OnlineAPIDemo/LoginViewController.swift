//
//  Copyright © 2017 GE. All rights reserved.
//

import UIKit
import PredixSDK

class LoginViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!

    fileprivate var credentialProvider: AuthenticationCredentialsProvider?
    fileprivate var authenticationManager: AuthenticationManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        //Creates an authentication manager configuration configured for your UAA instance.  The baseURL, clientId and clientSecret can also be defined in your info.plist if you wish but for simplicity I've added them to the config below.
        var configuration = AuthenticationManagerConfiguration()
        configuration.baseURL = URL(string: "https://predixsdkforiosexampleuaa.predix-uaa.run.aws-usw02-pr.ice.predix.io")
        configuration.clientId = "NativeClient"
        configuration.clientSecret = "test123"

        //Create an online handler so that we can tell the authentication manager we want to authenticate online
        let onlineHandler = UAAServiceAuthenticationHandler()
        onlineHandler.authenticationServiceDelegate = self

        //Create an authentication manager with our UAA configuration, set UAA as our authorization source, set the online handler so that the manager knows we want to autenticate online
        authenticationManager = AuthenticationManager(configuration: configuration)
        authenticationManager?.authorizationHandler = UAAAuthorizationHandler()
        authenticationManager?.onlineAuthenticationHandler = onlineHandler

        //Tell authentication manager we are ready to authenticate, once we call authenticate it will call our delegate with the credential provider
        authenticationManager?.authenticate { status in
            self.updateStatusText(message: "Authentication \(status)")
            switch status {
            case .success(_, _):
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "onlineAPI", sender: self)
                }
                break
            default: break
            }
        }

        self.updateStatusText(message: "Authentication Started")
    }

    @IBAction func signInPressed(_ sender: Any) {
        updateStatusText(message: "Authentication credentials received, sending request to UAA")
        //Give the username and password to the credential provider
        credentialProvider?(self.usernameTextField.text ?? "", self.passwordTextField.text ?? "")
    }

    fileprivate func updateStatusText(message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
}

extension LoginViewController: ServiceBasedAuthenticationHandlerDelegate {
    public func authenticationHandler(_ authenticationHandler: PredixSDK.AuthenticationHandler, didFailWithError error: Error) {
        updateStatusText(message: "Authentication failed: \(error)")
    }

    public func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        updateStatusText(message: "Invalid username and/or password")
    }

    public func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        //Set our credential provider so that when we sign in we can pass the username and password from the text fields to the authentication manager
        credentialProvider = completionHandler
    }
}
