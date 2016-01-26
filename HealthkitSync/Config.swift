import Foundation

struct Config {
    struct FBOauth {
        @available(iOS, deprecated=1.0, message="You need to add a FitBit key and remove this")
        static let Key = "<Need FitBit key here>"
        @available(iOS, deprecated=1.0, message="You need to add a FitBit secret and remove this")
        static let Secret = "<Need FitBit secret here>"
        @available(iOS, deprecated=1.0, message="You need to add a FitBit callback URL and remove this")
        static let CallbackURLScheme = "oauth-hksync"
        static let CallbackURL = "\(CallbackURLScheme)://oauth-callback/fitbit"
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