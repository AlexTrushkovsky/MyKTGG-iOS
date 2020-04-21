//
//  ViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 17.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import WebKit

class NewsWebView: UIViewController, WKUIDelegate {
    var webView: WKWebView!
    var url: String?
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string:"https://ktgg.kiev.ua\(url!)")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
}
