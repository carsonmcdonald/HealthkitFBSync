import Foundation
import OAuthSwift

class FBAPI: NSObject {
    
    let oauthswift = OAuth1Swift(
        consumerKey:     Config.FBOauth.Key,
        consumerSecret:  Config.FBOauth.Secret,
        requestTokenUrl: "https://api.fitbit.com/oauth/request_token",
        authorizeUrl:    "https://www.fitbit.com/oauth/authorize",
        accessTokenUrl:  "https://api.fitbit.com/oauth/access_token"
    )
    
    override init() {
        if let webViewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("FBAuthWebViewController") as? FBAuthWebViewController {
            oauthswift.authorize_url_handler = webViewController
        }
    }

    func fetchSortedWeightDataFromDateTime(startDateTime:NSDate, success: (weightData:[FBWeightData]) -> Void, onError: (error: NSError) -> Void) {
        
        self.performOauthIfNeeded({ (client) -> Void in

            let requestDatePairs = self.createRequestDatePairsFromStartDateToNow(startDateTime)
            var rdpCount = 0
            var requestDatePairGen = GeneratorOf<[NSDate]> {
                if rdpCount < requestDatePairs.count {
                    return requestDatePairs[rdpCount++]
                }
                return nil
            }
            
            var allWeightData = [FBWeightData]()
            self.makeWeightRequestForDates(&requestDatePairGen, client: client, success: { (weightData) -> Void in
                
                if weightData == nil {
                    allWeightData.sort { $0.dateTime.compare($1.dateTime) == NSComparisonResult.OrderedAscending }
                    success(weightData: allWeightData)
                } else {
                    allWeightData += weightData!
                }
                
            }, onError: onError)
            
        }, onError: { (error) -> Void in
            
            onError(error: error)
            
        })
        
    }
    
    private func makeWeightRequestForDates(inout requestDatePairGen: GeneratorOf<[NSDate]>, client:OAuthSwift.OAuthSwiftClient, success: (weightData:[FBWeightData]?) -> Void, onError: (error: NSError) -> Void) {
        
        if let requestDatePair = requestDatePairGen.next() {
        
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let start = dateFormatter.stringFromDate(requestDatePair[0])
            let end = dateFormatter.stringFromDate(requestDatePair[1])
            
            let requestString = "https://api.fitbit.com/1/user/-/body/log/weight/date/\(start)/\(end).json"
            
            client.get(requestString, parameters: Dictionary<String, AnyObject>(), success: { (data: NSData, response: NSHTTPURLResponse) -> Void in
                
                if response.statusCode >= 200 && response.statusCode <= 299 {
                    
                    var jsonError: NSError?
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
                    
                    if let e = jsonError {
                        onError(error: e)
                    } else {
                        success(weightData: FBWeightData.parseWeightData(jsonDict))
                        
                        self.makeWeightRequestForDates(&requestDatePairGen, client: client, success: success, onError: onError)
                    }
                    
                } else {
                    var dataAsString = NSString(data: data, encoding: NSUTF8StringEncoding)
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
        var endDate = NSDate()
        var startDateTime = startDateTimeIn
        var nextDateTime = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: 1, toDate: startDateTime, options: NSCalendarOptions.allZeros)!
        
        // While nextDateTime is before endDate
        while(nextDateTime.compare(endDate) == NSComparisonResult.OrderedAscending) {
            
            requestDatePairs.append([startDateTime, nextDateTime])
            
            startDateTime = nextDateTime
            nextDateTime = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: 1, toDate: startDateTime, options: NSCalendarOptions.allZeros)!

        }
        
        requestDatePairs.append([startDateTime, endDate])
        
        return requestDatePairs
        
    }

    private func performOauthIfNeeded(withOauth: (client:OAuthSwift.OAuthSwiftClient) -> Void, onError: (error: NSError) -> Void) {
        
        let userData = SavedUserData.loadUserData()
        
        if userData.isAuthed() {
            let client = OAuthSwift.OAuthSwiftClient(consumerKey: Config.FBOauth.Key, consumerSecret: Config.FBOauth.Secret, accessToken: userData.oauthToken!, accessTokenSecret: userData.oauthSecret!)
            
            withOauth(client: client)
        } else {
            oauthswift.authorizeWithCallbackURL(NSURL(string: "oauth-hksync://oauth-callback/fitbit")!, success: { (credential: OAuthSwift.OAuthSwiftCredential, response: NSURLResponse?) -> Void in
                
                    userData.oauthToken = credential.oauth_token
                    userData.oauthSecret = credential.oauth_token_secret
                    userData.syncUserData()
                
                    withOauth(client: self.oauthswift.client)
                
                }, failure: { (error: NSError) -> Void in
                    
                    userData.oauthToken = nil
                    userData.oauthToken = nil
                    userData.syncUserData()
                    
                    onError(error: error)
                    
                })
        }

    }
    
}
