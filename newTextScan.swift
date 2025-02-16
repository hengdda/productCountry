//
//  newTextScan.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-15.
//
/*
import SwiftUI
import Vision
import VisionKit
import UIKit
import WebKit
import Foundation

struct TextScannerView: View {
    let image: UIImage?
    @State private var quickVerdict: String = "Checking..."
    @State private var product: String = "Unknown"
    @State private var confidence: String = "0%" // Initialize with a default value
    @State private var detailedBreakdown: [ProductInfo] = []
    @State private var parentCompany: [ParentCompany] = []
    @State private var resume: String = "Fetching..."
    @State private var companyHistory: String = "Fetching..."
    // Declare extractedText as a State *before* using it:
   @State private var extractedText: String = "Scanning..." // Initialize it!
   @State private var brandName: String = "Unknown" // Declare and initialize brandName
    @State private var productName: String = "Unknown" // Declare and initialize productName
    
    // Declare and initialize the missing state variables:
        @State private var isCanadianBrand: String = "Checking..."
        @State private var isProductMadeInCanada: String = "Checking..."
        @State private var ingredientOrigins: String = "Checking..."
        @State private var brandHistory: String = "Fetching..." // Consistent with other history states
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Quick Verdict
                Text("Quick Verdict:")
                    .font(.title2.bold())
                Text(quickVerdict)
                    .foregroundColor(quickVerdict.contains("Canadian") ? .green : .red)

                // Product Information
                Text("Product: \(product)")
                Text("Confidence in verdict: \(confidence)")

                // Detailed Breakdown
                Text("Detailed Breakdown:")
                    .font(.title3.bold())
                ForEach(detailedBreakdown) { info in
                    HStack {
                        Text(info.category + ":").bold()
                        Spacer()
                        Text(info.answer)
                    }
                }

                // Resume
                Text("Resume:")
                    .font(.title3.bold())
                Text(resume)

                // Parent Company
                Text("Parent Company:")
                    .font(.title3.bold())
                ForEach(parentCompany) { company in
                    HStack {
                        Text(company.category + ":").bold()
                        Spacer()
                        Text(company.name)
                        Text(company.country)
                    }
                }

                // Company History
                Text("Company History")
                    .font(.title3.bold())
                Text(companyHistory)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)

                // Start Over Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Start Over")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .onAppear {
                DispatchQueue.main.async {
                    extractText(from: image)
                }
            }
        }
    }

    // Function to Extract Text from Image
    private func extractText(from image: UIImage?) {
        guard let cgImage = image?.cgImage else { return }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                return
            }

            let recognizedStrings = request.results?
                .compactMap { $0 as? VNRecognizedTextObservation }
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            DispatchQueue.main.async {
                self.extractedText = recognizedStrings ?? "No text detected"
                extractBrandAndProduct()
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
            }
        }
    }

    // Function to Extract Brand & Product Name
    private func extractBrandAndProduct() {
            let brandPattern = #"Brand:\s*(.*?)\n"#
            let productPattern = #"Product:\s*(.*?)\n"#
            let confidencePattern = #"Confidence in verdict:\s*(.*?)\n"# // Capture confidence

            let extractedBrand = extractValue(from: extractedText, for: brandPattern)
            let extractedProduct = extractValue(from: extractedText, for: productPattern)
            let extractedConfidence = extractValue(from: extractedText, for: confidencePattern)

            brandName = extractedBrand
            productName = extractedProduct
            confidence = extractedConfidence

            if brandName != "Unknown" && productName != "Unknown" && confidence != "0%" { // Check if all values are extracted
                processExtractedInformation()
            }
        }
    private func processExtractedInformation() {
            // 1. Quick Verdict (Simplified):
            quickVerdict = (extractedText.contains("Canadian")) ? "Canadian" : "Not Canadian"

            // 2. Detailed Breakdown (Parsing):
            let detailedBreakdownText = extractSection(from: extractedText, title: "Detailed Breakdown:")
            detailedBreakdown = parseDetailedBreakdown(detailedBreakdownText)

            // 3. Resume (Direct Extraction):
            resume = extractSection(from: extractedText, title: "Resume:")

            // 4. Parent Company (Parsing):
            let parentCompanyText = extractSection(from: extractedText, title: "Parent Company:")
            parentCompany = parseParentCompany(parentCompanyText)

            // 5. Company History (Direct Extraction):
            companyHistory = extractSection(from: extractedText, title: "Company History")
        }
    private func parseDetailedBreakdown( _ text: String) -> [ProductInfo] {
            var breakdown: [ProductInfo] = []
            let lines = text.components(separatedBy: .newlines)

            for line in lines {
                let components = line.components(separatedBy: ":")
                if components.count == 2 {
                    let category = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let answer = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    breakdown.append(ProductInfo(category: category, answer: answer))
                }
            }
            return breakdown
        }

     private func extractSection(from text: String, title: String) -> String {
            let pattern = "\(title)\\n(.*?)\\n\\n" // Matches the section including the title
            let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let range = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text))?.range(at: 1) // Capture group 1

            if let range = range, let swiftRange = Range(range, in: text) {
                return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return "" // Return empty string if section not found
        }

    // Function to Extract Specific Information
    private func extractValue(from text: String, for regexPattern: String) -> String {
        let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
        let range = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text))?.range(at: 1)

        if let range = range, let swiftRange = Range(range, in: text) {
            return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return "Unknown"
    }

    // Search Online for Brand & Product Information
    private func searchBrandInformation(brandName: String) {
        Task {
            let searchResults = await fetchWebData(for: "Is \(brandName) a Canadian brand?")
            DispatchQueue.main.async {
                isCanadianBrand = searchResults
            }
        }
        
        Task {
            let searchResults = await fetchWebData(for: "Is \(productName) made in Canada?")
            DispatchQueue.main.async {
                isProductMadeInCanada = searchResults
            }
        }
        
        Task {
            let searchResults = await fetchWebData(for: "\(productName) ingredient origins")
            DispatchQueue.main.async {
                ingredientOrigins = searchResults
            }
        }
        
        Task {
            let searchResults = await fetchWebData(for: "\(brandName) company history")
            DispatchQueue.main.async {
                companyHistory = searchResults
            }
        }
        
        Task {
            let searchResults = await fetchWebData(for: "\(brandName) brand history")
            DispatchQueue.main.async {
                brandHistory = searchResults
            }
        }
    }
}
// Reusable Section View
struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title3).bold()
            Text(content)
                .font(.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}
private func parseParentCompany(_ text: String) -> [ParentCompany] {
       var companies: [ParentCompany] = []
       let lines = text.components(separatedBy: .newlines)

       for line in lines {
           let components = line.components(separatedBy: " ")
           if components.count >= 3 { // Ensure at least 3 components (Category, Name, Country)
               let category = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
               let name = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
               let country = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
               companies.append(ParentCompany(category: category, name: name, country: country))
           }
       }
       return companies
   }

// Data Structures (same as before)
struct ProductInfo: Identifiable {
    let id = UUID()
    let category: String
    let answer: String
}

struct ParentCompany: Identifiable {
    let id = UUID()
    let category: String
    let name: String
    let country: String
}
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

func fetchWebData(for query: String) async -> String {
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let searchURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)")! // Force-unwrap is okay here

    // Instead of returning a string, create a WebView to display the search
    return "" // Return an empty string as a placeholder
}

*/
