//
//  productCountryApp.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-06.
//

import SwiftUI


@main
struct productCountryApp: App {
    // To handle app delegate callbacks in an app that uses the SwiftUI lifecycle,
    // you must create an application delegate and attach it to your `App` struct
    // using `UIApplicationDelegateAdaptor`.
    // Register AppDelegate for Firebase setup

    
    var body: some Scene {
        
        WindowGroup {
            AnimatedScanPage()
            //ContentView()
            //CameraPreviewView()
        }
    }
}
