//
//  Copyright © 2017 GE. All rights reserved.
//

import UIKit
import PredixSDK

class LoginViewController: UIViewController {

    @IBOutlet var dismissButton: UIButton!
    @IBOutlet var webView: UIWebView!

    var loginURL: URL?
    var shouldFollowRedirect: ((URL) -> (Bool))?

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func unwindToMainView() {
        Logger.info("\(type(of: self)): \(#function) calling unwindSegue")
        self.performSegue(withIdentifier: "unwindSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        Logger.info("\(type(of: self)): \(#function)")
    }
}

extension LoginViewController: BrowserBasedAuthenticationHandlerDelegate {
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, loadWebAuthenticationUrl url: URL, shouldFollowRedirect: @escaping (URL) -> (Bool)) {

        self.webView.loadRequest(URLRequest(url: url))
        self.shouldFollowRedirect = shouldFollowRedirect
    }
}

extension LoginViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if let url = request.url {
            return self.shouldFollowRedirect?(url) ?? true
        }
        return true
    }
}
