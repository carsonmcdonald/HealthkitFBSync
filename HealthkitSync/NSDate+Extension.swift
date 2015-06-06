import Foundation

extension NSDate {
    
    func tomorrow() -> NSDate {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate + (86400 * Double(1))
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }
    
    func yesterday() -> NSDate {
        let interval: NSTimeInterval = self.timeIntervalSinceReferenceDate - (86400 * Double(1))
        return NSDate(timeIntervalSinceReferenceDate: interval)
    }

}
