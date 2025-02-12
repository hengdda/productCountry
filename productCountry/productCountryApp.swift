//
//  productCountryApp.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-06.
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency
import UIKit

@main
struct productCountryApp: App {
    // To handle app delegate callbacks in an app that uses the SwiftUI lifecycle,
    // you must create an application delegate and attach it to your `App` struct
    // using `UIApplicationDelegateAdaptor`.
    // Register AppDelegate for Firebase setup
    init() {
        MobileAds.shared.start(completionHandler: nil)
       }
    var body: some Scene {
        
        WindowGroup {
            AnimatedScanPage()
            //ContentView()
            //CameraPreviewView()
        }
    }
}
