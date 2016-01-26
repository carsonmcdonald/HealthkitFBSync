import Foundation
import OAuthSwift

class FBAPI: NSObject {
    
    let oauthswift = OAuth2Swift(
        consumerKey:     Config.FBOauth.Key,
        consumerSecret:  Config.FBOauth.Secret,
        authorizeUrl:   "https://www.fitbit.com/oauth2/authorize",
        accessTokenUrl: "https://api.fitbit.com/oauth2/token",
        responseType:   "code"
    )
    var isAuthenticated = false
    
    override init() {
        if let webViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("FBAuthWebViewController") as? FBAuthWebViewController {
            oauthswift.authorize_url_handler = webViewController
        }
    }

    func fetchSortedWeightDataFromDateTime(startDateTime:NSDate, success: (weightData:[FBWeightData]) -> Void, onError: (error: NSError) -> Void) {
        
        self.performOauthIfNeeded({ (client) -> Void in

            let requestDatePairs = self.createRequestDatePairsFromStartDateToNow(startDateTime)
            var rdpCount = 0
            var requestDatePairGen = anyGenerator({ () -> [NSDate]? in
                if rdpCount < requestDatePairs.count {
                    return requestDatePairs[rdpCount++]
                }
                return nil
            })
            
            var allWeightData = [FBWeightData]()
            self.makeWeightRequestForDates(&requestDatePairGen, client: client, success: { (weightData) -> Void in

                if weightData == nil {
                    allWeightData.sortInPlace { $0.dateTime.compare($1.dateTime) == NSComparisonResult.OrderedAscending }
                    success(weightData: allWeightData)
                } else {
                    allWeightData += weightData!
                }
                
            }, onError: onError)
            
        }, onError: { (error) -> Void in
            
            onError(error: error)
            
        })
        
    }
    
    private func makeWeightRequestForDates(inout requestDatePairGen: AnyGenerator<[NSDate]>, client:OAuthSwiftClient, success: (weightData:[FBWeightData]?) -> Void, onError: (error: NSError) -> Void) {
        
        if let requestDatePair = requestDatePairGen.next() {
        
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let start = dateFormatter.stringFromDate(requestDatePair[0])
            let end = dateFormatter.stringFromDate(requestDatePair[1])
            
            let requestString = "https://api.fitbit.com/1/user/-/body/log/weight/date/\(start)/\(end).json"
            
            client.get(requestString, parameters: Dictionary<String, AnyObject>(), success: { (data: NSData, response: NSHTTPURLResponse) -> Void in
                
                if response.statusCode >= 200 && response.statusCode <= 299 {
                    
                    do {
                        
                        let jsonDict = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        
                        success(weightData: FBWeightData.parseWeightData(jsonDict))
                        
                        self.makeWeightRequestForDates(&requestDatePairGen, client: client, success: success, onError: onError)
                        
                    } catch let e as NSError {
                        onError(error: e)
                    }
                    
                } else {
                    let dataAsString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    onError(error: NSError(domain: Config.Errors.Domain,
                        code: Config.Errors.NetworkResponseError,
                        userInfo: [NSLocalizedDescriptionKey:"Request error (\(requestString)): code=\(response.statusCode) -> message=\(dataAsString)"]))
                }
                
            }, failure: onError)
            
        } else {
            success(weightData:nil)
        }
        
    }
    
    private func createRequestDatePairsFromStartDateToNow(startDateTimeIn: NSDate) -> [[NSDate]] {
        
        var requestDatePairs = [[NSDate]]()
        
        let calendar = NSCalendar.currentCalendar()
        let endDate = NSDate()
        var startDateTime = startDateTimeIn
        var nextDateTime = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: 1, toDate: startDateTime, options: NSCalendarOptions())!
        
        // While nextDateTime is before endDate
        while(nextDateTime.compare(endDate) == NSComparisonResult.OrderedAscending) {
            
            requestDatePairs.append([startDateTime, nextDateTime])
            
            startDateTime = nextDateTime
            nextDateTime = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: 1, toDate: startDateTime, options: NSCalendarOptions())!

        }
        
        requestDatePairs.append([startDateTime, endDate])
        
        return requestDatePairs
        
    }

    private func performOauthIfNeeded(withOauth: (client:OAuthSwiftClient) -> Void, onError: (error: NSError) -> Void) {
        
        if !isAuthenticated {
            guard let callbackURL = NSURL(string: Config.FBOauth.CallbackURL) else {
                onError(error: NSError(domain: Config.Errors.Domain,
                    code: Config.Errors.NetworkResponseError,
                    userInfo: [NSLocalizedDescriptionKey:"Invalid callback URL"]))
                return
            }
            
            oauthswift.accessTokenBasicAuthentification = true
            
            let state : String = generateStateWithLength(20) as String
            
            oauthswift.authorizeWithCallbackURL(callbackURL,
                scope: "weight", // Only asking for weight data access
                state: state,
                success: { (credential, response, parameters) -> Void in
                    
                    withOauth(client: self.oauthswift.client)
                    
                }, failure: { (error) -> Void in
                    
                    onError(error: error)
                    
            })
        } else {
            withOauth(client: self.oauthswift.client)
        }

    }
    
}
