import Foundation

class FBWeightData: NSObject, Printable
{
    var bmi: Float = 0.0
    var dateTime: NSDate!
    var fat: Float = 0.0
    var logId: Int = 0
    var weightInKilograms: Float = 0.0
    
    override var description : String {
        return "{bmi=\(bmi),dateTime=\(dateTime),fat=\(fat),logId=\(logId),weight=\(weightInKilograms)}"
    }
    
    class func parseWeightData(weightWrapperDict: AnyObject!) -> [FBWeightData] {
        var parsedWeightList = [FBWeightData]()
        
        if let weightArray = weightWrapperDict["weight"] as? NSArray {
            
            for weightDict in weightArray {
                var weightEntry = FBWeightData()
                
                if let bmi = weightDict["bmi"] as? Float {
                    weightEntry.bmi = bmi
                }
                
                if let fat = weightDict["fat"] as? Float {
                    weightEntry.fat = fat
                }
                
                if let weight = weightDict["weight"] as? Float {
                    weightEntry.weightInKilograms = weight
                }
                
                if let logId = weightDict["logId"] as? Int {
                    weightEntry.logId = logId
                }
                
                if let date = weightDict["date"] as? String {
                    if let time = weightDict["time"] as? String {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        weightEntry.dateTime = dateFormatter.dateFromString("\(date) \(time)")
                    }
                }
                
                if weightEntry.dateTime != nil {
                    parsedWeightList.append(weightEntry)
                }
            }
            
        }
        
        parsedWeightList.sort { $0.dateTime.compare($1.dateTime) == NSComparisonResult.OrderedAscending }
        
        return parsedWeightList
    }
}