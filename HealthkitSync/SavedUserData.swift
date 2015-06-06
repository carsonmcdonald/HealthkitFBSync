import Foundation

class SavedUserData: NSObject {
    
    var lastSyncTimestamp: NSDate!
    var oauthToken: String?
    var oauthSecret: String?
    
    class func loadUserData() -> SavedUserData {
        let savedData = SavedUserData()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let lastSync = defaults.objectForKey(Config.Preferences.LastSyncTime) as? NSDate {
            savedData.lastSyncTimestamp = lastSync
        } else {
            let startDateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitYear, fromDate: NSDate())
            let calendar = NSCalendar.currentCalendar()
            if let startDate = NSCalendar(identifier: NSCalendarIdentifierGregorian)?.dateFromComponents(startDateComponents) {
                savedData.lastSyncTimestamp = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: -12, toDate: startDate, options: NSCalendarOptions.allZeros)!
            } else {
                savedData.lastSyncTimestamp = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: -12, toDate: NSDate(), options: NSCalendarOptions.allZeros)!
            }
        }
        
        if let token = defaults.objectForKey(Config.Preferences.OauthToken) as? String {
            savedData.oauthToken = token
        }
        
        if let secret = defaults.objectForKey(Config.Preferences.OauthSecret) as? String {
            savedData.oauthSecret = secret
        }

        return savedData
    }
    
    func syncUserData() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(self.lastSyncTimestamp, forKey: Config.Preferences.LastSyncTime)
        if self.oauthToken == nil {
            defaults.removeObjectForKey(Config.Preferences.OauthToken)
        } else {
            defaults.setObject(self.oauthToken, forKey: Config.Preferences.OauthToken)
        }
        if self.oauthSecret == nil {
            defaults.removeObjectForKey(Config.Preferences.OauthSecret)
        } else {
            defaults.setObject(self.oauthSecret, forKey: Config.Preferences.OauthSecret)
        }
        defaults.synchronize()
        
    }
    
    func isAuthed() -> Bool {
        return self.oauthSecret != nil && self.oauthToken != nil
    }

}
