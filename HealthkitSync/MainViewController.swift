import UIKit
import HealthKit
import JGProgressHUD

class MainViewController: UIViewController {
    
    let healthKitStore = HKHealthStore()
    let fbAPI = FBAPI()

    @IBOutlet weak var fitbitSyncButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    
    private let loadingHUD = JGProgressHUD(style: JGProgressHUDStyle.Dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.fitbitSyncButton.enabled = false
        
        self.updateLastSyncTime()
        
        if !HKHealthStore.isHealthDataAvailable() {
            
            self.showAlert("HealthKit is not available on this device.")
            self.statusLabel.text = "HealthKit is not available on this device."
            
        } else {
            
            healthKitStore.requestAuthorizationToShareTypes(
                   [HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage),
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)],
                readTypes: [HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
                            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage),
                            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)],
                completion: { (success:Bool, error:NSError!) -> Void in
                    
                    if !success {
                        self.showAlert("HealthKit authorization failed: \(error.description)")
                        self.statusLabel.text = "HealthKit authorization failed"
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.fitbitSyncButton.enabled = true
                            self.statusLabel.text = "Ready to sync."
                        })
                    }
                    
            })
            
        }
    }

    @IBAction func fitbitSyncAction(sender: AnyObject) {
        
        loadingHUD.textLabel.text = "Loading"
        loadingHUD.showInView(self.view)
        
        self.statusLabel.text = "Sync started."
        
        let userData = SavedUserData.loadUserData()
        
        self.fbAPI.fetchSortedWeightDataFromDateTime(userData.lastSyncTimestamp, success: { (weightData:[FBWeightData]) -> Void in
            
            self.syncSortedFBToHK(weightData)
            
            if weightData.count > 0 {
                userData.lastSyncTimestamp = weightData[weightData.count-1].dateTime
                userData.syncUserData()
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateLastSyncTime()
                
                self.statusLabel.text = "Sync complete."
                self.loadingHUD.dismiss()
            })
            
        }, onError: { (error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.loadingHUD.dismiss()
                
                self.statusLabel.text = "Error requesting FitBit sync data"
                self.showAlert("Error requesting FitBit sync data: \(error.description)")
            })
            
        })
        
    }
    
    private func updateLastSyncTime() {
        let userData = SavedUserData.loadUserData()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        self.lastUpdatedLabel.text = dateFormatter.stringFromDate(userData.lastSyncTimestamp)
    }
    
    private func syncSortedFBToHK(weightData:[FBWeightData]) {
        
        if weightData.count > 0 {
            let startDate = weightData[0].dateTime.yesterday()
            let endDate = weightData[weightData.count-1].dateTime.tomorrow()
            
            self.queryForExistingHKDataWithDateRange(HKQuantityTypeIdentifierBodyMass, startDate: startDate, endDate: endDate, success: { (hkWeightValues) -> Void in

                for weightEntry in weightData {
                    
                    if (hkWeightValues.filter { $0.endDate == weightEntry.dateTime }.count) == 0 {
                        self.createHKWeightEntry(weightEntry)
                    }
                    
                }

            })
            
            self.queryForExistingHKDataWithDateRange(HKQuantityTypeIdentifierBodyFatPercentage, startDate: startDate, endDate: endDate, success: { (hkFatValues) -> Void in
                
                for weightEntry in weightData {
                    
                    if (hkFatValues.filter { $0.endDate == weightEntry.dateTime }.count) == 0 {
                        self.createHKFatEntry(weightEntry)
                    }
                    
                }
                
            })
            
            self.queryForExistingHKDataWithDateRange(HKQuantityTypeIdentifierBodyMassIndex, startDate: startDate, endDate: endDate, success: { (hkBMIValues) -> Void in
                
                for weightEntry in weightData {
                    
                    if (hkBMIValues.filter { $0.endDate == weightEntry.dateTime }.count) == 0 {
                        self.createHKBMIEntry(weightEntry)
                    }
                    
                }
                
            })
        }

    }
    
    private func queryForExistingHKDataWithDateRange(quantityTypeForIdentifier:String, startDate: NSDate, endDate: NSDate, success: (results:[HKQuantitySample]) -> Void) {
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let limit = 10000
        
        let sampleQuery = HKSampleQuery(
            sampleType: HKObjectType.quantityTypeForIdentifier(quantityTypeForIdentifier),
            predicate: HKQuery.predicateForSamplesWithStartDate(startDate, endDate:endDate, options: .None),
            limit: limit,
            sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error ) -> Void in
                
                if let queryError = error {
                    
                    self.showAlert("Error running HK query: \(queryError.description)")
                    
                } else {
                    
                    if let hkqsResults = results as? [HKQuantitySample] {
                        success(results: hkqsResults)
                    } else {
                        self.showAlert("Error running HJ query: Unexpected results type")
                    }
                    
                }
                
        }
        
        self.healthKitStore.executeQuery(sampleQuery)
        
    }
    
    private func createHKWeightEntry(weightData:FBWeightData) {

        let weightType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(), doubleValue: Double(weightData.weightInKilograms * 1000.0))
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, startDate: weightData.dateTime, endDate: weightData.dateTime)
        
        self.healthKitStore.saveObject(weightSample, withCompletion: { (success, error) -> Void in
            
            if error != nil {
                self.showAlert("Error saving HealthKit sample: \(error.description)")
            }
            
        })
        
    }
    
    private func createHKFatEntry(weightData:FBWeightData) {
        
        let fatType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)
        let fatQuantity = HKQuantity(unit: HKUnit.percentUnit(), doubleValue: Double(weightData.fat/100.0))
        let fatSample = HKQuantitySample(type: fatType, quantity: fatQuantity, startDate: weightData.dateTime, endDate: weightData.dateTime)
        
        self.healthKitStore.saveObject(fatSample, withCompletion: { (success, error) -> Void in
            
            if error != nil {
                self.showAlert("Error saving HealthKit sample: \(error.description)")
            }
            
        })
        
    }
    
    private func createHKBMIEntry(weightData:FBWeightData) {
        
        let bmiType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)
        let bmiQuantity = HKQuantity(unit: HKUnit.countUnit(), doubleValue: Double(weightData.bmi))
        let bmiSample = HKQuantitySample(type: bmiType, quantity: bmiQuantity, startDate: weightData.dateTime, endDate: weightData.dateTime)
        
        self.healthKitStore.saveObject(bmiSample, withCompletion: { (success, error) -> Void in
            
            if error != nil {
                self.showAlert("Error saving HealthKit sample: \(error.description)")
            }
            
        })
        
    }
    
    private func showAlert(message:String) {
        var alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

}

