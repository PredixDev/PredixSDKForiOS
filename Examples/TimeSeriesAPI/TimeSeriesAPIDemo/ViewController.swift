import UIKit
import PredixSDK

class ViewController: UIViewController {
    
    private var timeSeriesManager: TimeSeriesManager?
    @IBOutlet weak var tagNamesTextView: UITextView!
    @IBOutlet weak var tagNamesLabel: UITextField!
    @IBOutlet weak var dataPointsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var config: TimeSeriesManagerConfiguration = TimeSeriesManagerConfiguration()

        config.hostUrl = "https://time-series-store-predix.run.aws-usw02-pr.ice.predix.io"
        config.predixZoneId = "6a1487bd-afb6-40b8-929c-ca872c958f74"
        config.UAABaseUrl = "https://3311caf6-6548-4c24-a86c-29ee5c6acc5c.predix-uaa.run.aws-usw02-pr.ice.predix.io"
        config.UAAClientId = "app_client_id"
        config.UAAClientSecret = "secret"

        self.timeSeriesManager = TimeSeriesManager(configuration: config)
    }
    
    @IBAction func fetchTags(_ sender: Any) {
        self.timeSeriesManager?.fetchTagNames { (tags, error) in
            if let tagNames = tags {
                tagNamesTextView.text = tagNames.joined(separator: ",")
            } else if let anError = error {
                tagNamesTextView.text = error?.localizedDescription
            } else {
                tagNamesTextView.text = "unknown issue fetching tags"
            }
        }
    }
    
    @IBAction func fetchDataPoints(_ sender: Any) {
        guard let tagNames = tagNamesLabel.text?.split(separator: ",") else {
            self.dataPointsTextView.text = "can't fetch tags unless the tag names are in the proper format.  The tag names input format should look like: tag1,tag2"
            return
        }
        
        let dataPointsRequest = DataPointRequest(tagNames: tagNames)
        self.timeSeriesManager?.fetchLatestDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                dataPointsTextView.text = error?.localizedDescription
            } else if let dataPoints = results?.dataPoints {
                var responseString = ""
                for dataPoint in dataPoints {
                    responseString = responseString + "------------------------------------------\n"
                    responseString = responseString + "\(dataPoint.tagName): \(dataPoint.results)\n"
                    responseString = responseString + "------------------------------------------\n"
                }
                dataPointsTextView.text = responseString
            } else {
                dataPointsTextView.text = "unknown issue fetching data points"
            }
        }
    }
}
