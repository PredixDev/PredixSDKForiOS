import UIKit
import PredixSDK

class OnlineAPIViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var responseLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func sendOnlineRequest(_ sender: Any) {
        let url = URL(string: "https://predixsdkhelloapi.run.aws-usw02-pr.ice.predix.io/hello")!
        self.statusLabel.text = "sending request to \(url.absoluteString)"
        let task = URLSession.predix.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let urlResponse = response as? HTTPURLResponse {
                    self.statusLabel.text = "got a response from \(url.absoluteString): statusCode: \(urlResponse.statusCode)"
                } else {
                    self.statusLabel.text = "got a response"
                }

                if let requestError = error {
                    self.statusLabel.text = "bad response from request: \(requestError)"
                    return
                }

                if let jsonData = data, let json = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions(rawValue: 0)) {
                    self.responseLabel.text = "\(json)"
                } else {
                    self.statusLabel.text = "could not parse response data"
                }

            }
        }

        task.resume()
    }

}
