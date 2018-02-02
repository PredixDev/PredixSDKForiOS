import UIKit
import PredixSDK

class ViewController: UIViewController {
    
    private var timeSeriesManager: TimeSeriesManager?
    @IBOutlet weak var tagNamesTextView: UITextView!
    @IBOutlet weak var tagNamesLabel: UITextField!
    @IBOutlet weak var dataPointsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create a Time Sereies configuration that contains the details about the Time Series instance we are tageting.
        var config: TimeSeriesManagerConfiguration = TimeSeriesManagerConfiguration()
        //The host for the Time Series Service
        config.hostUrl = "https://time-series-store-predix.run.aws-usw02-pr.ice.predix.io"
        //The Zone ID for the Time Series Service
        config.predixZoneId = "e52ee381-897a-4313-80da-6ca2f0a17bd4"

        //Create a Time Series Manager that will be used to fetch Time Series data.
        self.timeSeriesManager = TimeSeriesManager(configuration: config)
    }
    
    @IBAction func fetchTags(_ sender: Any) {
        self.tagNamesTextView.text = "Fetching tags..."
        //Fetch all the tags that are available for the configured Time Series Service
        self.timeSeriesManager?.fetchTagNames { (tags, error) in
            DispatchQueue.main.async {
                if tags.count > 0 {
                    self.tagNamesTextView.text = tags.joined(separator: ",")
                } else if let anError = error {
                    self.tagNamesTextView.text = anError.localizedDescription
                } else {
                    //We didn't get any tags and there were't any errors!
                    self.tagNamesTextView.text = "No tags available"
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
        //Fetch the Time Series data points for the tags specified.
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
