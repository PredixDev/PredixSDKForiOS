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
            DispatchQueue.main.async {
                if tags.count > 0 {
                    self.tagNamesTextView.text = tags.joined(separator: ",")
                } else if let anError = error {
                    self.tagNamesTextView.text = anError.localizedDescription
                } else {
                    self.tagNamesTextView.text = "unknown issue fetching tags"
                }
            }
        }
    }
    
    @IBAction func fetchDataPoints(_ sender: Any) {
        guard let tagNames = tagNamesLabel.text?.split(separator: ",") else {
            self.dataPointsTextView.text = "can't fetch tags unless the tag names are in the proper format.  The tag names input format should look like: tag1,tag2"
            return
        }
        
        //convert the array of substrings into strings
        var tagNameStrings = [String]()
        for tagName in tagNames {
            tagNameStrings.append(String(tagName))
        }
        
        //A Time Range lets you specify a start and an end.  0... means all data since epoc ms time 0 (since 1970).  An example would be if you wanted all data from 2 years ago to 1 year ago you would use 63113852000...31556926000
        let dataPointsRequest = DataPointRequest(tagNames: tagNameStrings, timeRange: TimeRange(0...))
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            DispatchQueue.main.async {
                if let anError = error {
                    self.dataPointsTextView.text = anError.localizedDescription
                } else if let dataPoints = results?.dataPoints {
                    var responseString = ""
                    for dataPoint in dataPoints {
                        responseString = responseString + "------------------------------------------\n"
                        responseString = responseString + "\(dataPoint.tagName): \(String(describing: dataPoint.results))\n"
                        responseString = responseString + "------------------------------------------\n"
                    }
                    self.dataPointsTextView.text = responseString
                } else {
                    self.dataPointsTextView.text = "unknown issue fetching data points"
                }
            }
        }
    }
}
