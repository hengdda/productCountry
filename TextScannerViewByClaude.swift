import SwiftUI
import Vision
import VisionKit
import GoogleGenerativeAI
import UIKit

struct TextScannerViewByVisionAPI: View {
    let image: UIImage
    @State private var extractedText: String = "Scanning..."
    @State private var aiResponse: String = "Please press Analyze button..."
    @State private var isScanning = true
    @State private var analysisFailed = false
    @State private var isAnalyzing = false
    @State private var detectProductOrigin: String = ""
    @State private var productManufacturer: String = ""
    @State private var detectedBarcode: String = "No barcode detected"
    @State private var productBrand: String = "No productBrand detected"
    @State private var productOrigin: String = "Unknown"
    @State private var brandOwnership: String = "Checking..."
    @State private var brandOwnedByCanadian: String?
    @State private var fullyCanadianOwned: String?
    @State private var parentCompany: String?
    @State private var canadianAlternatives: String?
    @State private var isOCRComplete = false
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4") // Replace with your actual API key
    let openFoodFactsApiUrl = "https://world.openfoodfacts.org/api/v0/product/"
    
    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.22)
                    .clipped()
            }
            .frame(width: UIScreen.main.bounds.width * 0.9)
            .background(Color.white)
            
            Text("Analysis Results")
                .font(.title3)
                .bold()
                .padding()
            
            if isAnalyzing {
                ProgressView("Analyzing...")
                    .padding()
            } else if analysisFailed {
                Text("❌ Analysis Failed. Try again.")
                    .foregroundColor(.red)
                    .padding()
            } else {
                List {
                    /*AnalysisRow(imageName: "text.viewfinder", label: "Detected Text", value: extractedText)*/
                    
                    AnalysisRow(imageName: "text.viewfinder", label: "detectProductOrigin", value: self.detectProductOrigin)
                    AnalysisRow(imageName: "text.viewfinder", label: "detect Manufacture", value: self.productManufacturer)
                    AnalysisRow(imageName: "barcode", label: "Detected Barcode", value: detectedBarcode)
                    AnalysisRow(imageName: "building.2", label: "Product Brand", value: productBrand)
                    AnalysisRow(imageName: "globe", label: "Product Origin", value: productOrigin)
                    AnalysisRow(imageName: "factory", label: "Brand Ownership", value: brandOwnership)
                    AnalysisRow(imageName: "brand", label: "Brand Owned By Canadian", value: brandOwnedByCanadian ?? "Unknown")
                    AnalysisRow(imageName: "canadian", label: "Details Break down", value: fullyCanadianOwned ?? "Unknown")
                    AnalysisRow(imageName: "parent", label: "parent Company", value: parentCompany ?? "Unknown")
                    AnalysisRow(imageName: "alter", label: "Canadian Alternatives", value: canadianAlternatives ?? "Unknown")
                }
                .listStyle(.plain)
            }
            
            Spacer()
            
            Button(action: {
                isOCRComplete = false // Reset flag
                analyzeImage()
            }) {
                Text("Analyze Image")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue).shadow(radius: 3))
            }
            .frame(width: UIScreen.main.bounds.width * 0.9)
            .padding()
        }
        .onChange(of: aiResponse) { newResponse in
            if newResponse != "Please press Analyze button..." && !newResponse.isEmpty && newResponse !=  "AI analysis failed. Please try again."    {
                print("🔄 AI Response Changed, Extracting Values...")
                extractValues()
            } else {
                print("⚠️ AI Response is still not updated.")
            }
        }
        
        .navigationBarTitle("Scanned Image", displayMode: .inline)
    }
    
    private func analyzeImage() {
        guard let cgImage = image.cgImage else { return }
        isAnalyzing = true
        analysisFailed = false
        isOCRComplete = false // Reset OCR flag before analysis
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        detectedBarcode = "No barcode detected" // Reset barcode detection
        extractedText = "Scanning..." // Reset text extraction
        
        let dispatchGroup = DispatchGroup()
        
        // ✅ Start OCR (Text Recognition)
        dispatchGroup.enter()
        let textRequest = VNRecognizeTextRequest { request, error in
            defer { dispatchGroup.leave() }
            
            if let observations = request.results as? [VNRecognizedTextObservation] {
                DispatchQueue.main.async {
                    let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    print("✅ OCR Result: \(recognizedText)")
                    
                    self.extractedText = recognizedText.isEmpty ? "No text detected" : recognizedText
                    self.productOrigin = self.detectProductOrigin(from: recognizedText)
                }
            }
        }
        textRequest.usesLanguageCorrection = true
        
        // ✅ Start Barcode Detection
        dispatchGroup.enter()
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            defer { dispatchGroup.leave() }
            
            if let results = request.results as? [VNBarcodeObservation], let barcode = results.first?.payloadStringValue {
                DispatchQueue.main.async {
                    print("✅ Detected Barcode: \(barcode)")
                    self.detectedBarcode = barcode
                }
            }
        }
        
        // Run Vision requests
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([textRequest, barcodeRequest])
                print("🚀 Vision Requests Started!")
            } catch {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.analysisFailed = true
                    print("❌ Vision Request Failed: \(error.localizedDescription)")
                }
            }
        }
        
        // ✅ Ensure text extraction and barcode scanning complete before AI starts
        dispatchGroup.notify(queue: .main) {
            self.isAnalyzing = false
            self.isOCRComplete = true // ✅ Mark OCR as complete
            
            print("✅ OCR and Barcode Detection Completed!")
            print("Final Extracted Text: \(self.extractedText)")
            print("Final Barcode: \(self.detectedBarcode)")
            
            if self.detectedBarcode != "No barcode detected" {
                self.fetchProductBrand(from: self.detectedBarcode) { brand, manufacture, origin in
                    DispatchQueue.main.async {
                        self.productBrand = brand ?? "Unknown"
                        self.productOrigin = origin ?? "Unknown"
                        self.productManufacturer = manufacture ?? "Unknown"
                    }
                    
                    self.fetchBrandOwnershipOnline(brand: brand ?? "Unknown") { ownership in
                        DispatchQueue.main.async {
                            self.brandOwnership = ownership ?? "Not available"
                            self.startAIAnalysis(brand: brand ?? "Unknown", text: self.extractedText, productOrigin: self.productOrigin)
                        }
                    }
                }
            }
        }
    }
    
    
    // ✅ Detect product origin based on extracted text
    private func detectProductOrigin(from text: String) -> String {
        let lowercasedText = text.lowercased()
        
        let originKeywords = [
            "made in", "bottled in", "manufactured in",
            "produced in", "product of", "packed in", "assembled in",
            "designed in", "developed in", "origin:", "distributed by",
            "imported by", "exported by", "packed by", "bottled in",
            "blended in", "formulated in", "manufactured for",
            "imported", "domestic"
        ]
        
        for keyword in originKeywords {
            if let range = lowercasedText.range(of: keyword) {
                let startIndex = range.upperBound
                let substring = lowercasedText[startIndex...]
                
                // Find the first newline or period to limit the extraction
                if let endIndex = substring.firstIndex(where: { $0.isNewline || $0 == "." }) {
                    return String(substring[..<endIndex]).trimmingCharacters(in: .whitespaces)
                } else {
                    return String(substring).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        return "Unknown"
    }
    
    // ✅ Fetch product brand from OpenFoodFacts API
    private func fetchProductBrand(from barcode: String, completion: @escaping (String?, String?,String?) -> Void) {
        guard let url = URL(string: "\(openFoodFactsApiUrl)\(barcode).json") else {
            completion(nil, nil,nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil, nil,nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let product = json["product"] as? [String: Any] {
                    let brand = product["brands"] as? String
                    let manufacturer = product["manufacturing_places"] as? String ?? product["manufacturers"] as? String ?? "Unknown Manufacturer"
                    let origin = product["origins"] as? String ?? "Unknown"
                    completion(brand, manufacturer, origin)
                } else {
                    completion(nil,nil, nil)
                }
            } catch {
                completion(nil,nil, nil)
            }
        }
        task.resume()
    }
    
    private func fetchBrandOwnershipOnline(brand: String, completion: @escaping (String?) -> Void) {
        let encodedBrand = brand.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let searchURL = "https://www.ic.gc.ca/app/scr/cc/CorporationsCanada/api/v1/company?name=\(encodedBrand)"
        
        guard let url = URL(string: searchURL) else {
            completion("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ API Request Failed: \(error?.localizedDescription ?? "Unknown error")")
                completion("Could not retrieve ownership details.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    if let company = json.first, let name = company["name"] as? String, let jurisdiction = company["jurisdiction"] as? String {
                        let ownershipInfo = "Company: \(name), Jurisdiction: \(jurisdiction)"
                        completion(ownershipInfo)
                    } else {
                        completion("No company ownership information found.")
                    }
                } else {
                    completion("Invalid response format.")
                }
            } catch {
                completion("Failed to parse response.")
            }
        }
        task.resume()
    }
    private func extractValues() {
        guard !aiResponse.isEmpty else {
            print("AI reponse is empty!")
            return } // ✅ Ensure AI response exists
        self.detectProductOrigin = aiResponse.extractValue(between: "(QUESTION1)", and: "(QUESTION2)") ?? "Processing.."
        self.productManufacturer = aiResponse.extractValue(between: "(QUESTION2)", and: "(QUESTION3)") ?? "Processing.."
        fullyCanadianOwned = aiResponse.extractValue(between: "(QUESTION3)", and: "(QUESTION4)") ?? "Processing.."
        parentCompany = aiResponse.extractValue(between: "(QUESTION4)", and: "(QUESTION5)") ?? "Processing.."
        canadianAlternatives = aiResponse.extractValue(between: "(QUESTION5)", and: nil) ?? "Processing.." // Last question has no end marker
    }
    // ✅ Run AI Analysis
    /*
     */
    /*
     private func startAIAnalysis(brand: String, text: String, productOrigin: String) {
     guard !text.isEmpty, text != "No text detected" else {
     print("⚠️ AI Analysis Skipped: No valid text found.")
     return
     }
     let prompt = """
     Analyze this product's origion.
     - Brand: \(brand)
     - Product Origin: \(productOrigin)
     - Extracted Text: \(text)
     
     Respond to each question with a concise answer.  Use ONLY the format below, with each answer on a new line:
     (QUESTION1) [Your Answer Here]
     (QUESTION2) [Your Answer Here]
     (QUESTION3) [Your Answer Here]
     (QUESTION4) [Your Answer Here]
     (QUESTION5) [Your Answer Here]
     Below are questions:
     (QUESTION1) What is the product name and was this product made by a Canadian company?
     (QUESTION2) What is the brand name and is the brand owned by a Canadian company?
     (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
     (QUESTION4) Who is the parent company, and is it based in Canada?
     (QUESTION5) Based on the brand information, are there any Canadian alternatives to this product?  Please provide a concise answer (Yes/No/Uncertain) and explain your reasoning. If yes, name a few potential alternatives.
     """
     
     Task {
     let response = try? await model.generateContent(prompt)
     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 🔄 Add slight delay
     if let textResponse = response?.text, !textResponse.isEmpty {
     self.aiResponse = textResponse
     // extractValues() // ✅ Extract values immediately
     } else {
     print("❌ AI response is empty or invalid")
     }
     }
     }
     }
     */
    private func startAIAnalysis(brand: String, text: String, productOrigin: String) {
        guard !text.isEmpty, text != "No text detected" else {
            print("⚠️ AI Analysis Skipped: No valid text found.")
            return
        }

        let prompt = """
        Analyze this product's origin.
        - Brand: \(brand)
        - Product Origin: \(productOrigin)
        - Extracted Text: \(text)

        Respond to each question with a concise answer. Use ONLY the format below, with each answer on a new line:
        (QUESTION1) [Your Answer Here]
        (QUESTION2) [Your Answer Here]
        (QUESTION3) [Your Answer Here]
        (QUESTION4) [Your Answer Here]
        (QUESTION5) [Your Answer Here]

        Below are the questions:
        (QUESTION1) What is the product name and was this product made by a Canadian company?
        (QUESTION2) What is the brand name and is the brand owned by a Canadian company?
        (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
        (QUESTION4) Who is the parent company, and is it based in Canada?
        (QUESTION5) Based on the brand information, are there any Canadian alternatives to this product? Please provide a concise answer (Yes/No/Uncertain) and explain your reasoning. If yes, name a few potential alternatives.
        """

        print("🚀 Sending AI Prompt:\n\(prompt)")

        Task {
            do {
                let response = try await model.generateContent(prompt)

                DispatchQueue.main.async {
                    if let textResponse = response.text, !textResponse.isEmpty {
                        print("✅ AI Response Received:\n\(textResponse)")

                        self.aiResponse = "" // 🔄 Force SwiftUI to detect change
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.aiResponse = textResponse
                        }
                    } else {
                        print("❌ AI response is empty or invalid.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ AI API Request Failed: \(error.localizedDescription)")
                    self.aiResponse = "AI analysis failed. Please try again."
                }
            }
        }
    }

}


