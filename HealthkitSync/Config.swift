import Foundation

struct Config {
    struct FBOauth {
        @availability(iOS, deprecated=1.0, message="You need to add a FitBit key and remove this")
        static let Key = "<Need FitBit key here>"
        @availability(iOS, deprecated=1.0, message="You need to add a FitBit secret and remove this")
        static let Secret = "<Need FitBit secret here>"
    }
    struct Preferences {
        static let OauthToken = "HSOauthToken"
        static let OauthSecret = "HSOauthSecret"
        static let LastSyncTime = "HSLastSyncTime"
    }
    struct Errors {
        static let Domain = "hks.error.domain"
        static let NetworkResponseError = 10001
    }
}