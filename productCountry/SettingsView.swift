//
//  SettingsView.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-06.
//

import SwiftUI
struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings & History of Records")
                .font(.title)
                .padding()
            
            List {
                Text("Scan History Record 1")
                Text("Scan History Record 2")
                // Here, you would show the scan history stored by the user
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
}
