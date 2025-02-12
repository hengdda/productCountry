//
//  ProductListView.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-06.
//

import SwiftUI

struct ProductListView: View {
    var body: some View {
        VStack {
            Text("List of Products Produced in Canada, US, and China")
                .font(.title)
                .padding()
            
            List {
                Text("Product 1 - Canada")
                Text("Product 2 - US")
                Text("Product 3 - China")
                // You can populate this list with data from your backend or local data
            }
            .padding()
        }
    }
}



#Preview {
    ProductListView()
}
