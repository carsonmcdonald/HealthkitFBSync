import UIKit
import OAuthSwift
import JGProgressHUD

class FBAuthWebViewController: OAuthWebViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    var targetURL : NSURL = NSURL()
    
    private let loadingHUD = JGProgressHUD(style: JGProgressHUDStyle.Dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.frame = UIScreen.mainScreen().applicationFrame
        self.webView.scalesPageToFit = true
        self.webView.delegate = self

        self.webView.loadRequest(NSURLRequest(URL: self.targetURL))
    }

    override func handle(url: NSURL) {
        self.targetURL = url
        super.handle(url)
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        loadingHUD.textLabel.text = "Loading"
        loadingHUD.showInView(self.view)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        loadingHUD.dismiss()
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if (request.URL!.scheme == Config.FBOauth.CallbackURLScheme){
            self.dismissWebViewController()
        }
        
        return true
    }
    
}
