//
//  Copyright © 2017 GE. All rights reserved.
//

import UIKit
import PredixSDK

class ViewController: UIViewController {

    @IBOutlet var loginResult: UILabel!
    @IBOutlet var userInfo: UILabel!
    var authMan: AuthenticationManager?
    var browserHandler: BrowserBasedAuthenticationHandler?
    var dismissLogin: (() -> Void)?

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginTapped(_ sender: Any) {
        Logger.shared.loggerLevel = .trace
        self.loginResult.text = ""
        self.userInfo.text = ""

        let authenticationURL = URL(string: "https://predixsdkforiosexampleuaa.predix-uaa.run.aws-usw02-pr.ice.predix.io")!
        Reachability.sharedInstance = Reachability(configuration: Reachability.ReachabilityConfiguration(authorizationURL: authenticationURL))
        
        // create an AuthenticationManagerConfiguration, and load associated UAA endpoint from our Predix Mobile server endpoint
        var config = AuthenticationManagerConfiguration()
        config.baseURL = authenticationURL

        // Client Id and Client secret are are loaded from Info.plist in this example
        //config.clientId = <<my UAA client id>>
        //config.clientSecret = <<my UAA client secret>>

        // we want to enable TouchId usage
        config.useBiometricAuthentication = true

        // Create our AuthenticationManager with our configuration
        let manager = AuthenticationManager(configuration: config)

        // Create an OnlineAuthenticationHandler object -- in this case an our online handler subclass is designed to work with a UAA login web page. The redirectURI is setup in the UAA configuration
        let browserHandler = UAABrowserAuthenticationHandler(redirectURI: "https://predixsdkforios.io/authorization_grant")

        // Set delegate for handling UI display events.
        browserHandler.authenticationUIDelegate = self

        // Associate a RefreshAuthenticationHandler -- in this case our refresh handler is design to work with UAA.
        browserHandler.refreshAuthenticationHandler = UAARefreshAuthenticationHandler()

        // retain a reference to our online authentication handler for later when the login page segue launches
        self.browserHandler = browserHandler

        //associate our OnlineAuthenticationHandler with the AuthenticationManager
        manager.onlineAuthenticationHandler = browserHandler

        //associate an AuthorizationHandler with the AuthenticationManager -- in this case an authorization handler that will perform authorization with a PredixMobile service backend.
        manager.authorizationHandler = UAAAuthorizationHandler()

        // Start the authentication process
        manager.authenticate { (status) in
            Logger.info("\(type(of: self)): \(#function): Authentication Completed: \(status)")
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // This segue opens a seperate login UIViewController to show our web view. Since it's a seperate UIViewController, we'll set the online handler's authenticationBrowserDelegate to its instance.

        if let loginView = segue.destination as? LoginViewController, let browserHandler = self.browserHandler {
            browserHandler.authenticationBrowserDelegate = loginView

            // we'll hold onto a closure for unwinding the segue later
            dismissLogin = loginView.unwindToMainView
        }
    }

    @IBAction func prepareForUnwind(_ segue: UIStoryboardSegue) {
        // Needed to unwind the segue
    }
}

// AuthenticationHandlerUIDelegate methods
extension ViewController: AuthenticationHandlerUIDelegate {

    func presentAuthenticationUI(for authenticationHandler: AuthenticationHandler) {

        // perform the "showLogin" segue to show the login UIViewController
        self.performSegue(withIdentifier: "showLogin", sender: self)
    }

    func dismissAuthenticationUI(for authenticationHandler: AuthenticationHandler) {
        // call the closure we captured previously to unwind the display segue
        self.dismissLogin?()
    }
}
