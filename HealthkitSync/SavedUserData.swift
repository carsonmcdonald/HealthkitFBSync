import Foundation

class SavedUserData: NSObject {
    
    var lastSyncTimestamp: NSDate!
    
    class func loadUserData() -> SavedUserData {
        let savedData = SavedUserData()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let lastSync = defaults.objectForKey(Config.Preferences.LastSyncTime) as? NSDate {
            savedData.lastSyncTimestamp = lastSync
        } else {
            let startDateComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Month, NSCalendarUnit.Year], fromDate: NSDate())
            let calendar = NSCalendar.currentCalendar()
            if let startDate = NSCalendar(identifier: NSCalendarIdentifierGregorian)?.dateFromComponents(startDateComponents) {
                savedData.lastSyncTimestamp = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: -12, toDate: startDate, options: NSCalendarOptions())!
            } else {
                savedData.lastSyncTimestamp = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: -12, toDate: NSDate(), options: NSCalendarOptions())!
            }
        }
        
        return savedData
    }
    
    func syncUserData() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setObject(self.lastSyncTimestamp, forKey: Config.Preferences.LastSyncTime)
        
        defaults.synchronize()
        
    }
    
}
