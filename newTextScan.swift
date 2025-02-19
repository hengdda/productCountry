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
 import GoogleGenerativeAI
 import UIKit
 import GoogleMobileAds

 struct TextScannerView: View {
     let image: UIImage
     @State private var extractedText: String = "Scanning..."
     @State private var aiResponse: String = "Please press Analyze button..."
     @State private var storedAIResponse: AIAnalysisResponse? // ✅ Stores AI JSON response
     let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4")// ✅ Replace with your actual API key
     @Environment(\.presentationMode) var presentationMode

     var body: some View {
         VStack {
             // Scanned Image with Rounded Bottom Corners
             Image(uiImage: image)
                 .resizable()
                 .scaledToFill() // 🔥 Fills the width, may crop the image
                 .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height * 0.25)
                 .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                 .padding(.top, 10)

             // 📜 Display Extracted Text
                   Text(extractedText)
                       .font(.body)
                       .lineLimit(nil)
                       .foregroundColor(.black)
                       .padding()
                       .frame(maxWidth: UIScreen.main.bounds.width * 0.9, maxHeight: UIScreen.main.bounds.height * 0.3 )
                       .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                       .padding(.bottom, 10) // Add space before "Analysis"
             // Analysis Section
             VStack(alignment: .leading) {
                 Text("Analysis")
                     .font(.title3).bold()
                     .padding(.horizontal)
                 
                 ScrollView {
                     VStack{
                         if let aiData = storedAIResponse {
                             AIAnalysisView(aiData: aiData)
                         } else {
                             Text(aiResponse)
                                 .font(.body)
                                 .padding()
                         }
                     }.frame(maxWidth: .infinity, maxHeight: .infinity)
                 }
                 .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.6)
                 .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.2))) // ✅ Background with rounded corners
                 .padding(.horizontal)
             }
             Spacer()
             HStack{
                 // Back Button
                 Button(action: {
                         // Action to go back (Dismiss view or pop navigation)
                         presentationMode.wrappedValue.dismiss()
                     }) {
                         Image(systemName: "arrow.left") // Back arrow icon
                             .font(.title2)
                             .foregroundColor(.white)
                             .padding()
                             .background(
                                 Circle()
                                     .fill(Color.gray.opacity(0.8))
                                     .shadow(radius: 3)
                             )
                     }
             // Analyze Button
             Button(action: {
                 //fetchAIAnalysis(for: extractedText)
                 fetchAIAnalysis(for: "DJI Neo")
             }) {
                 Text("Analyze")
                     .font(.title2)
                     .foregroundColor(.white)
                     .padding()
                     .frame(maxWidth: .infinity)
                     .background(Color.red)
                     .cornerRadius(10)
             }
             .padding(.horizontal)
             // end of HSTACK
         }
             Spacer()
         }
         .onAppear { extractText(from: image) }
         .navigationBarHidden(true)
     }

     private func extractText(from image: UIImage) {
         guard let cgImage = image.cgImage else { return }

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

    // private func fetchAIAnalysis(for text: String) {
     private func fetchAIAnalysis(for text: String) {
         Task {
             do {
                 let prompt = """
                     Based on the Product Description to analyst below questions. Return the results in JSON format.
                     Product Description:
                     \(text)  // The text you scanned
                     
                     {
                         "quickVerdict": "The percentage indicating how Canadian this product is...",
                         "productSummary": "Brief description of the product",
                         "parentCompany": { "name": "Company Name", "isCanadian": "Yes/No" },
                         "canadianProbability": "Percentage value in string",
                         "detailedBreakdown": {
                             "ingredients": { "isCanadian": "Yes/No", "source": "Country of origin" },
                             "manufacturing": { "isCanadian": "Yes/No", "location": "Where it's made" },
                             "parentCompany": { "isCanadian": "Yes/No", "name": "Parent company" },
                             "brand": { "isCanadian": "Yes/No", "name": "Brand name" },
                             "countryContributions": { "CountryName": Percentage Value in the format of double },
                             "supplyChainDetails": ["Description1", "Description2"],
                             "alternativeCompanies": [
                                 {
                                     "name": "Name of an alternative company.",
                                     "website": "Website URL of the alternative company.",
                                     "isCanadian": "Yes/No/Unknown",
                                     "country": "Country where the alternative company is based."
                                 }
                             ]
                     
                         }
                     }
                     Text: \(text)
                     """

                 let response = try await model.generateContent(prompt)

                 if let rawText = response.text {
                     print("🔍 Raw AI Response: \n\(rawText)")

                     // Directly decode the rawText (no extractJSON needed)
                     if let jsonData = rawText.data(using: .utf8) {
                         let decoder = JSONDecoder()
                         decoder.keyDecodingStrategy = .convertFromSnakeCase // Important!

                         do {
                             let decodedResponse = try decoder.decode(AIAnalysisResponse.self, from: jsonData)
                             storedAIResponse = decodedResponse
                             print("🎉 JSON decoded successfully!")
                         } catch let decodingError {
                             print("🚨 JSON Decoding Error: \(decodingError)")
                             // ... (Detailed error printing as before)
                             aiResponse = "Error: Could not parse JSON. Check the console for details."
                         }
                     } else {
                         print("🚨 Error: Could not convert JSON string to data.")
                         aiResponse = "Error: Invalid JSON data."
                     }
                 } else {
                     print("🚨 Error: AI response is empty.")
                     aiResponse = "Error: No response from AI."
                 }
             }
         }
     }
     func fetchFakeAIAnalysis(for text: String) {
     Task {
         do {
             // Use the fake JSON for testing
             /*let fakeJSON = #"""
             {
                 "quickVerdict": "The DJI Neo is not made in Canada.",
                 "productSummary": "The DJI Neo is a drone manufactured by DJI, a Chinese company.",
                 "parentCompany": { "name": "DJI", "isCanadian": "No" },
                 "canadianProbability": "0%",
                 "detailedBreakdown": {
                     "ingredients": { "isCanadian": "No", "source": "China" },
                     "manufacturing": { "isCanadian": "No", "location": "China" },
                     "parentCompany": { "isCanadian": "No", "name": "DJI" },
                     "brand": { "isCanadian": "No", "name": "DJI" },
                     "countryContributions": { "China": 100.0 },  // ✅ Fix: Ensure it's a Double
                     "supplyChainDetails": ["Components are sourced from China.", "Assembly takes place in China."]
                 },
                 "alternativeCompanies": []  // ✅ Fix: Ensure it's an empty array, not null
             }*/
             let fakeJSON = #"""
                 {
                                 "quickVerdict": "The DJI Neo is not made in Canada.",
                                 "productSummary": "The DJI Neo is a drone manufactured by DJI, a Chinese company.",
                                 "parentCompany": { "name": "DJI", "isCanadian": "No" },
                                 "canadianProbability": "0%",
                                 "detailedBreakdown": {
                                     "ingredients": { "isCanadian": "No", "source": "China" },
                                     "manufacturing": { "isCanadian": "No", "location": "China" },
                                     "parentCompany": { "isCanadian": "No", "name": "DJI" },
                                     "brand": { "isCanadian": "No", "name": "DJI" },
                                     "countryContributions": { "China": 100 },
                                     "supplyChainDetails": ["Components are sourced from China.", "Assembly takes place in China."]
                                 }
                             }
             """#


             // ✅ Step 1: Print raw JSON for debugging
             print("🔍 Fake JSON being used: \n\(fakeJSON)")

             // ✅ Step 2: Convert JSON string to Data
             guard let jsonData = fakeJSON.data(using: .utf8) else {
                 print("🚨 Error: Could not convert JSON string to data.")
                 aiResponse = "Error: Invalid JSON data."
                 return
             }

             // ✅ Step 3: Print raw JSON Data for debugging
             print("📄 JSON Data: \(jsonData)")

             // ✅ Step 4: Decode the JSON into AIAnalysisResponse
             let decoder = JSONDecoder()
             decoder.keyDecodingStrategy = .convertFromSnakeCase
             let decodedResponse = try decoder.decode(AIAnalysisResponse.self, from: jsonData)

             // ✅ Step 5: Store the AI response
             DispatchQueue.main.async {
                 storedAIResponse = decodedResponse
                 print("🎉 JSON decoded successfully!")
             }

         } catch let decodingError {
             print("🚨 JSON Decoding Error: \(decodingError)")

             // ✅ Step 6: More specific error handling
             if let errorContext = decodingError as? DecodingError {
                 switch errorContext {
                 case .typeMismatch(let type, let context):
                     print("🚨 Type mismatch: Expected \(type), Context: \(context.debugDescription)")
                 case .valueNotFound(let type, let context):
                     print("🚨 Value not found: \(type), Context: \(context.debugDescription)")
                 case .keyNotFound(let key, let context):
                     print("🚨 Key not found: \(key), Context: \(context.debugDescription)")
                 case .dataCorrupted(let context):
                     print("🚨 Data corrupted: \(context.debugDescription)")
                 @unknown default:
                     print("🚨 Unknown decoding error.")
                 }
             }

             aiResponse = "Error: Could not parse JSON. Check the console for details."
         }
     }
 }
 /*
     func extractJSON(from text: String) -> String? {
        let regexPattern = "\\{(?:[^{}]|\\n|(?R))*\\}"  // Supports nested braces and newlines

         guard let range = text.range(of: regexPattern, options: .regularExpression) else {
             print("❌ No JSON found")
             return nil
         }

         var jsonString = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
         
         // ✅ Fix invalid percentage formatting: Convert "80%" to "80.0"
         jsonString = jsonString.replacingOccurrences(of: "(\\d+)%", with: "$1.0", options: .regularExpression)
         
         // ✅ Replace invalid "N/A" occurrences with null (optional, based on requirements)
         jsonString = jsonString.replacingOccurrences(of: "\"N/A\"", with: "null")

         // Debugging: Print extracted and cleaned JSON
         print("✅ Cleaned JSON: \n\(jsonString)")
         
         // Validate extracted JSON
         guard let data = jsonString.data(using: .utf8) else {
             print("❌ Unable to convert JSON string to Data")
             return nil
         }
         
         do {
             let _ = try JSONSerialization.jsonObject(with: data, options: [])
             return jsonString
         } catch {
             print("❌ Extracted JSON is invalid: \(error.localizedDescription)")
             return nil
         }
     }
  */
  }

 struct AIAnalysisView: View {
     let aiData: AIAnalysisResponse

     var body: some View {
         VStack(alignment: .leading, spacing: 10) {
             Spacer()
             // Quick Verdict with Icon
             HeaderView(title: "Product Evaluation:", iconName: verdictIcon(for: aiData.quickVerdict), color: verdictColor(for: aiData.quickVerdict))
             
             Text(aiData.quickVerdict)
                 .font(.body)
                 .padding(.horizontal, 35)
             // Canadian Probability
           
             HeaderView(title: "Canadian Probability:")
             Spacer()
             Text(aiData.canadianProbability)
                 .font(.title2) // Or .title3, .headline, .system(size:weight:design), etc.
                 .foregroundColor(.red)
                 .padding(.horizontal, 35)
             // Canadian Probability Visualization
           
              CanadaFlagView(probability: aiData.canadianProbability)
                 .frame(width: UIScreen.main.bounds.width, height: 125)
           
             // Product Breakdown Table
             HeaderView(title: "Product Breakdown:")
        
             BreakdownTable(breakdown: aiData.detailedBreakdown)
             
             // Country Contributions
             HeaderView(title: "Country Contributions:")
             
             ForEach(aiData.detailedBreakdown.countryContributions.sorted(by: { $0.value > $1.value }), id: \.key) { country, percentage in
                 HStack {
                     Text(country)
                         .font(.body)
                     Spacer()
                     Text("\(percentage, specifier: "%.1f")%")
                         .font(.body)
                         .foregroundColor(.gray)
                 }
                 .padding(.horizontal, 35)
             }
             //////////////aurora temp////////////
           
             // Alternative Products Section
             if let alternatives = aiData.alternativeCompanies, !alternatives.isEmpty {
                 AlternativeProductsView(alternatives: alternatives)
             }
             //////////////aurora temp end////////////
         }
         .padding(.bottom, 10)
     }
 }
 struct BreakdownTable: View {
     let breakdown: DetailedBreakdown
     var body: some View {
         VStack {
             HStack {
                 Text("Category").bold().frame(maxWidth: .infinity, alignment: .leading)
                 Text("Analysis").bold().frame(maxWidth: .infinity, alignment: .leading)
             }
             .padding()
             .background(Color.gray.opacity(0.3))
             .cornerRadius(8)
             
             BreakdownRow(category: "Ingredients", answer: breakdown.ingredients.isCanadian)
             BreakdownRow(category: "Manufacturing", answer: breakdown.manufacturing.isCanadian)
             BreakdownRow(category: "Parent Company", answer: breakdown.parentCompany.isCanadian)
             BreakdownRow(category: "Brand", answer: breakdown.brand.isCanadian)
         }
         .padding(.horizontal, 35)
     }
 }
 struct AlternativeProductsView: View {
     let alternatives: [AlternativeCompany]

     var body: some View {
         VStack(alignment: .leading, spacing: 10) {
             HeaderView(title: "Alternative Products:")
             LazyVStack(spacing: 10) {
                 ForEach(alternatives, id: \.name) { alternative in
                     AlternativeProductRow(alternative: alternative)
                 }
             }
             .padding(.horizontal, 35)
         }
     }
 }

 struct AlternativeProductRow: View {
     let alternative: AlternativeCompany

     var body: some View {
         HStack {
             Text(alternative.name)
                 .font(.body)
                 .bold()
             
             Spacer()
             
             Text(alternative.website)
                 .font(.body)
         }
         .padding(.vertical, 5)
         .padding(.horizontal, 15)
         .background(Color.gray.opacity(0.2))
         .cornerRadius(8)
     }
 }

 struct HeaderView: View {
     let title: String
     var iconName: String? = nil
     var color: Color = .black

     var body: some View {
         HStack {
             if let iconName = iconName {
                 Image(systemName: iconName)
                     .resizable()
                     .scaledToFit()
                     .frame(width: 25, height: 25)
                     .foregroundColor(color)
             }
             Text(title)
                 .font(.title)
                 .foregroundColor(.black)
         }
         .padding(.horizontal, 35)
     }
 }

 // MARK: - Table Row Component
 struct BreakdownRow: View {
     let category: String
     let answer: String
     
     var body: some View {
         HStack {
             Text(category)
                 .frame(maxWidth: .infinity, alignment: .leading)
             
             HStack {
                 Image(systemName: answerIcon(for: answer)) // ✅ Adds appropriate icon
                     .resizable()
                     .scaledToFit()
                     .frame(width: 20, height: 20)
                     .foregroundColor(answerColor(for: answer))
                 
                 Text(answer)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .foregroundColor(answerColor(for: answer))
             }
         }
         .padding()
         .background(Color.gray.opacity(0.1))
         .cornerRadius(8)
     }
 }
 // MARK: - Flag View
 struct CanadaFlagView: View {
     var probability: String

     var imageName: String {
         switch probability {
         case "Not Made in Canada":
             return "4flag"
         case "May Not Be Canada Made":
             return "4flag"
         case "Possibly Canada Made":
             return "4flag"
         default:
             return "4flagwhite"
         }
     }
     var body: some View {
                Image(imageName)
                 .resizable()
                 .aspectRatio(contentMode: .fit) // Ensures correct proportions
                 .frame(width: UIScreen.main.bounds.width * 0.8, height: 150)
     }
 }

 // MARK: - Helper Functions for Icons and Colors
 func verdictIcon(for verdict: String) -> String {
     if verdict.lowercased().contains("canadian") {
         return "flag.fill"
     } else if verdict.lowercased().contains("not canadian") {
         return "xmark.circle.fill"
     } else {
         return "lightbulb.fill"
     }
 }

 func verdictColor(for verdict: String) -> Color {
     if verdict.lowercased().contains("canadian") {
         return .red
     } else if verdict.lowercased().contains("not canadian") {
         return .gray
     } else {
         return .yellow
     }
 }

 func answerIcon(for answer: String) -> String {
     switch answer.lowercased() {
     case "yes":
         return "checkmark.circle.fill" // ✅ Green check
     case "no":
         return "xmark.circle.fill" // ❌ Red cross
     case "maybe", "unknown":
         return "questionmark.circle.fill" // ❓ Yellow question mark
     default:
         return "exclamationmark.circle.fill" // ⚠️ Generic alert
     }
 }

 func answerColor(for answer: String) -> Color {
     switch answer.lowercased() {
     case "yes":
         return .green
     case "no":
         return .red
     case "maybe", "unknown":
         return .yellow
     default:
         return .black
     }
 }
 // ✅ Root Response Struct
 struct AIAnalysisResponse: Codable {
     let quickVerdict: String
     let productSummary: String
     let parentCompany: ParentCompany
     let canadianProbability: String
     let detailedBreakdown: DetailedBreakdown
     let alternativeCompanies: [AlternativeCompany]?  // ✅ Optional array
 }

 // ✅ Parent Company Struct
 struct ParentCompany: Codable {
     let name: String
     let isCanadian: String
 }

 // ✅ Detailed Breakdown
 struct DetailedBreakdown: Codable {
     let ingredients: IngredientInfo
     let manufacturing: ManufacturingInfo
     let parentCompany: ParentCompanyInfo
     let brand: BrandInfo
     let countryContributions: [String: Double] // ✅ Matches JSON
     let supplyChainDetails: [String]
 }

 // ✅ Nested Breakdown Categories
 struct IngredientInfo: Codable {
     let isCanadian: String
     let source: String
 }

 struct ManufacturingInfo: Codable {
     let isCanadian: String
     let location: String
 }

 struct ParentCompanyInfo: Codable {
     let isCanadian: String
     let name: String
 }

 struct BrandInfo: Codable {
     let isCanadian: String
     let name: String
 }

 // ✅ Alternative Company Struct
 struct AlternativeCompany: Codable {
     let name: String
     let website: String
 }
 struct ProductCategoryTableView: Codable {
     let categories: [ProductCategory]
 }

 struct ProductCategory: Codable {
     let name: String
     let percentage: Double
 }




*/
