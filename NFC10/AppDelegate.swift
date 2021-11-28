//
//  AppDelegate.swift
//  NFC10
//ㄙㄟ
//  Created by HAN PO CHENG on 2021/11/6.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = CameraViewController()

        return true
    }



}

