//
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

         // create an AuthenticationManagerConfiguration, and load associated UAA endpoint from our Predix Mobile server endpoint
        var config = AuthenticationManagerConfiguration()
        config.baseURL = URL(string: "https://predixsdkforiosexampleuaa.predix-uaa.run.aws-usw02-pr.ice.predix.io")

        // Client Id and Client secret are are loaded from Info.plist in this example
        //config.clientId = <<my UAA client id>>
        //config.clientSecret = <<my UAA client secret>>

        // we want to enable TouchId usage
        config.useTouchID = true

        // Create our AuthenticationManager with our configuration
        let manager = AuthenticationManager(configuration: config)

        // Create an OnlineAuthenticationHandler object -- in this case an our online handler subclass is designed to work with a UAA login web page. The redirectURI is setup in the UAA configuration
        let handler = UAABrowserAuthenticationHandler(redirectURI: "predixsdk://predixsdkforios.io/authorization_grant")

        // Associate a RefreshAuthenticationHandler -- in this case our refresh handler is design to work with UAA.
        handler.refreshAuthenticationHandler = UAARefreshAuthenticationHandler()

        // Set delegate for handling events.
        handler.authenticationBrowserDelegate = self

        //associate our OnlineAuthenticationHandler with the AuthenticationManager
        manager.onlineAuthenticationHandler = handler

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

//BrowserBasedAuthenticationHandlerDelegate methods
extension ViewController: BrowserBasedAuthenticationHandlerDelegate {

    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, loadWebAuthenticationUrl url: URL, shouldFollowRedirect: @escaping (URL) -> (Bool)) {

        // In this case when we have a login URL to display, we'll create a SafariViewController and use it to display the login URL.

        (UIApplication.shared.delegate as? AppDelegate)?.checkAuthRedirect = shouldFollowRedirect
        self.createAndShowSVC(url)
    }

    public func authenticationHandler(_ authenticationHandler: PredixSDK.AuthenticationHandler, willStoreQueryParameters queryStringInfo: [String: String]) -> [String: Any] {
        print("did we get here?")
        return queryStringInfo
    }

    private func createAndShowSVC(_ url: URL?) {

        let svc = SFSafariViewController(url: url!, entersReaderIfAvailable: false)

        svc.delegate = self

        self.present(svc, animated: true, completion: nil)

        NotificationCenter.default.addObserver(forName: Notification.Name.PredixAuthenticationComplete, object: nil, queue: OperationQueue.main) { _ in
            svc.dismiss(animated: true, completion: nil)
        }

    }
}

// If the user choses to exit the SafariViewController without logging in, we cancel the authentication process
extension ViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let mgr = self.authMan, mgr.isAuthenticationInProgress {
            mgr.cancelAuthentication()
        }
    }
}
