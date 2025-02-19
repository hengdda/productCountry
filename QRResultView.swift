//
//  QRResultView.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-07.
//
import SwiftUI

struct QRResultView: View {
    let image: UIImage?
    let qrCodeText: String

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Text("No Image Captured")
                    .foregroundColor(.red)
            }

            Text("Scanned QR Code:")
                .font(.headline)
                .padding(.top, 20)

            Text(qrCodeText)
                .font(.body)
                .padding()
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("Scan Result")
    }
}


