import SwiftUI
import Vision
import VisionKit
import GoogleGenerativeAI
import UIKit
/*
struct TextScannerViewByVisionAPI: View {
    let image: UIImage
    @State private var extractedText: String = "Scanning..."
    @State private var aiResponse: String = "Please press Analyze button..."
    @State private var storedAIResponse: AIAnalysisResponse?
    @State private var isScanning = true
    @State private var showAIAlert = false
    
    @State private var madeIn = "Press Analysis button..."
    @State private var expiration = "Press Analysis button..."
    @State private var ingredients = "Press Analysis button..."
    @State private var otherInfo = "Press Analysis button..."
    @State private var analysisInProgress = false // Track analysis state
    @State private var analysisFailed = false
 
    @State private var isAnalyzing = false
    @State private var detectedBarcode: String = "No barcode detected"
    @State private var productBrand: String = "No productBrand detected"
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4") // Replace with your actual API key
    @Environment(\.presentationMode) var presentationMode
    @State private var madeByCanadian: String? // Make them optional
    @State private var brandOwnedByCanadian: String?
    @State private var fullyCanadianOwned: String?
    @State private var parentCompany: String?
    @State private var canadianAlternatives: String?
    // State for the prompt
    @State private var showPrompt: Bool = false // State to show the prompt field
   
    //let visionApiKey = "AIzaSyAvxXhFhAtgM_rAZ-nqFQAnL5nQSnVxc-4"  // Replace with your actual key
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
                             AnalysisRow(imageName: "text.viewfinder", label: "Detected Text", value: extractedText)
                             AnalysisRow(imageName: "barcode", label: "Detected Barcode", value: detectedBarcode)
                             AnalysisRow(imageName: "globe", label: "Made By Canada", value: madeByCanadian ?? "Unknown")
                             AnalysisRow(imageName: "building.2", label: "Brand Owned By Canadian", value: brandOwnedByCanadian ?? "Unknown")
                             AnalysisRow(imageName: "factory", label: "Parent Company", value: parentCompany ?? "Unknown")
                             AnalysisRow(imageName: "leaf", label: "Canadian Alternatives", value: canadianAlternatives ?? "Unknown")
                         }
                         .listStyle(.plain)
                     }
                     
                     Spacer()

                     // Analyze Button
                     Button(action: {
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
                 .navigationBarTitle("Scanned Image", displayMode: .inline)
             }
    //go back to apple's ocr and abstract apple's barcode if possible
    /*
    private func analyzeImage() {
        guard let cgImage = image.cgImage else { return }

        isAnalyzing = true
        analysisFailed = false

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        var extractedText: String?
        var detectedBrand: String?

        // 1️⃣ Text Recognition Request (OCR)
        let textRequest = VNRecognizeTextRequest { request, error in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                extractedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

                DispatchQueue.main.async {
                    self.extractedText = extractedText?.isEmpty == false ? extractedText! : "No text detected"
                }
            }
        }
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true

        // 2️⃣ Barcode Detection Request
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation], let barcode = results.first?.payloadStringValue {
                DispatchQueue.main.async {
                    self.detectedBarcode = barcode
                    self.fetchProductBrand(from: barcode) { brand in
                        DispatchQueue.main.async {
                            detectedBrand = brand ?? "Unknown"
                            self.productBrand = detectedBrand ?? ""

                            // ✅ Call AI analysis only when OCR & Brand are both available
                            self.processAIAnalysis(text: extractedText, brand: detectedBrand)
                        }
                    }
}
            }
        }

        // 3️⃣ Perform Vision Requests Asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([textRequest, barcodeRequest])
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.analysisFailed = true
                }
                print("Vision request failed: \(error)")
            }
        }
    }
*/
    private func analyzeImage() {
        guard let cgImage = image.cgImage else { return }

        isAnalyzing = true
        analysisFailed = false

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        var extractedText: String? = nil
        var detectedBrand: String? = nil
        var barcodeValue: String? = nil

        let dispatchGroup = DispatchGroup() // ✅ Ensures both tasks complete

        // 1️⃣ Start OCR (Text Recognition)
        dispatchGroup.enter()
        let textRequest = VNRecognizeTextRequest { request, error in
            defer { dispatchGroup.leave() }
            if let observations = request.results as? [VNRecognizedTextObservation] {
                extractedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

                DispatchQueue.main.async {
                    self.extractedText = extractedText?.isEmpty == false ? extractedText! : "No text detected"
                }
            }
        }
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true

        // 2️⃣ Start Barcode Detection
        dispatchGroup.enter()
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            defer { dispatchGroup.leave() }
            if let results = request.results as? [VNBarcodeObservation], let barcode = results.first?.payloadStringValue {
                barcodeValue = barcode
                DispatchQueue.main.async {
                    self.detectedBarcode = barcode
                }
                /*
                // Fetch Brand from OpenFoodFacts API
                self.fetchProductBrand(from: barcode) { brand,<#arg#>  in
                    detectedBrand = brand
                    DispatchQueue.main.async {
                        self.productBrand = detectedBrand ?? ""
                    }
                }
                */
            }
        }

        // 3️⃣ Perform both requests asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([textRequest, barcodeRequest])
            } catch {
                print("Vision request failed: \(error)")
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.analysisFailed = true
                }
            }
        }

        // 4️⃣ Wait until both OCR and Barcode detection are done
        dispatchGroup.notify(queue: .main) {
            self.isAnalyzing = false

            // Ensure both extractedText and detectedBrand are available before AI analysis
            guard let finalText = extractedText, let finalBrand = detectedBrand, !finalText.isEmpty, !finalBrand.isEmpty else {
                print("❌ OCR or Brand extraction failed. Skipping AI Analysis.")
                return
            }

            print("✅ OCR & Brand extracted successfully. Running AI Analysis...")
            self.processAIAnalysis(text: finalText, brand: finalBrand)
        }
    }

    // ✅ Calls AI analysis only when OCR & Brand are both available
    private func processAIAnalysis(text: String?, brand: String?) {
        guard let text = text, let brand = brand, !text.isEmpty, !brand.isEmpty else { return }

        let combinedInput = "Brand: \(brand)\nExtracted Text: \(text)"
        self.analyzeWithGeminiAI(brand: brand, text: combinedInput)
    }
    /*
    // ✅ Step 2: Google Gemini AI - Analyze Product Origins
    private func analyzeWithGeminiAI(text: String) {
                 guard !text.isEmpty else { return }
                 let prompt = """
                 Analyze this product label:
                 
                 (QUESTION2) Is the brand: owned by a Canadian company?
                 (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
                 (QUESTION4) Who is the parent company, and is it based in Canada?
                 (QUESTION5) Are there any Canadian alternatives to this product?
                 (QUESTION6) Was this product made by a Canadian company?
                 
                 Text: \(text)
                 """

                 Task {
                     do {
                         let response = try await model.generateContent(prompt)
                         let responseText = response.text ?? "No response from AI."

                         DispatchQueue.main.async {
                             self.aiResponse = responseText
                             self.extractValues(from: responseText)
                         }
                     } catch {
                         DispatchQueue.main.async {
                             self.aiResponse = "Error: \(error.localizedDescription)"
                             self.analysisFailed = true
                         }
                     }
                 }
             }
*/
    private func analyzeWithGeminiAI(brand: String?, text: String, productOrigin: String?) {
        guard !text.isEmpty else {
            print("❌ No text extracted. Skipping AI analysis.")
            return
        }

        let finalBrand = brand ?? "Unknown"
        let finalOrigin = productOrigin ?? "Unknown"

        let prompt = """
        Check if the following brand is Canadian-owned or manufactures products in Canada.

        **Instructions:**
        - If the brand is Canadian-owned, state **"Yes"**.
        - If the brand is foreign but manufactures products in Canada, state **"Manufactured in Canada"**.
        - If the brand is foreign and does not manufacture in Canada, state **"No"**.
        - If information is missing, state **"Not enough information."**

        **Product Information:**
        - Brand: \(finalBrand)
        - Known Product Origin: \(finalOrigin)
        - Extracted Text: \(text)

        **Answer in a structured format:**
        (QUESTION1) Is this brand Canadian-owned? (Yes/No/Not enough info)
        (QUESTION2) Does this brand manufacture products in Canada? (Yes/No/Not enough info)
        """

        Task {
            do {
                let response = try await model.generateContent(prompt)
                let responseText = response.text ?? "No response from AI."

                DispatchQueue.main.async {
                    self.aiResponse = responseText
                    self.extractValues(from: responseText)
                }
            } catch {
                DispatchQueue.main.async {
                    self.aiResponse = "❌ AI Analysis Failed: \(error.localizedDescription)"
                    self.analysisFailed = true
                }
            }
        }
    }

    private func startAIAnalysis(brand: String, text: String, productOrigin: String) {
        let prompt = """
        
        Analyze this product information and provide structured responses   
        **Instructions:**
        - If the text includes **"Made in Canada"**, **"Product of Canada"**, or **"Manufactured in Canada"**, confirm it's Canadian.
        - If an **address in Canada** is detected (e.g., "Longueuil, QC"), verify if it is the **head office, distributor, or manufacturer**.
        - If a **company name is mentioned**, check if it is a **Canadian-owned company**.
        - If no information is available, state **"Not enough information."**
        
        Product Information:
        Brand: \(brand)
        Product Origin: \(productOrigin)
        Extracted Text: \(text)
        
        **Answer in a structured format:**
        (QUESTION1) Was this product made by a Canadian company?
        (QUESTION2) Is the brand owned by a Canadian company?
        (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
        (QUESTION4) Who is the parent company, and is it based in Canada?
        (QUESTION5) Are there any Canadian alternatives to this product?
        (QUESTION6) Based on the label, where was this product made or bottled?

        

        Please provide clear and concise answers after each question.
        """

        Task {
            do {
                let response = try await model.generateContent(prompt)
                let responseText = response.text ?? "No response from AI."

                DispatchQueue.main.async {
                    self.aiResponse = responseText
                    self.extractValues(from: responseText)
                }
            } catch {
                DispatchQueue.main.async {
                    self.aiResponse = "❌ AI Analysis Failed: \(error.localizedDescription)"
                    self.analysisFailed = true
                }
            }
        }
    }

    
    /*
    private func startAIAnalysis(brand: String, text: String) {
        let prompt = """
        Analyze this product label and provide structured responses:

        (QUESTION1) Was this product made by a Canadian company?
        (QUESTION2) Is the brand owned by a Canadian company?
        (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
        (QUESTION4) Who is the parent company, and is it based in Canada?
        (QUESTION5) Are there any Canadian alternatives to this product?

        Product Information:
        Brand: \(brand)
        Extracted Text: \(text)

        Please provide clear and concise answers after each question.
        """

        Task {
            do {
                let response = try await model.generateContent(prompt)
                let responseText = response.text ?? "No response from AI."

                DispatchQueue.main.async {
                    self.aiResponse = responseText
                    self.extractValues(from: responseText)
                }
            } catch {
                DispatchQueue.main.async {
                    self.aiResponse = "❌ AI Analysis Failed: \(error.localizedDescription)"
                    self.analysisFailed = true
                }
            }
        }
    }
 */
 private func detectProductOrigin(from text: String) -> String? {
        let lowercasedText = text.lowercased()
        
        let originKeywords = [
            "made in", "bottled in", "manufactured in",
            "produced in", "product of", "packed in","Assembled in","Designed in","Developed in","Origin:","Distributed by","Imported by","Exported by","Packed by","Bottled in","Blended in","Formulated in","Manufactured for","Imported","Domestic"
        ]
        
        for keyword in originKeywords {
            if let range = lowercasedText.range(of: keyword) {
                // Extract the portion of text after the keyword
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
             // ✅ Step 3: Extract Values from AI Response
    private func extractValues(from response: String) {
                madeByCanadian = response.extractValue(between: "(QUESTION5)", and: "(QUESTION6)") ?? "Unknown"
                brandOwnedByCanadian = response.extractValue(between: "(QUESTION2)", and: "(QUESTION3)") ?? "Unknown"
                fullyCanadianOwned = response.extractValue(between: "(QUESTION3)", and: "(QUESTION4)") ?? "Unknown"
                parentCompany = response.extractValue(between: "(QUESTION4)", and: "(QUESTION5)") ?? "Unknown"
                canadianAlternatives = response.extractValue(between: "(QUESTION5)", and: nil) ?? "Unknown"
            }
    // ✅ Fetch product brand from OpenFoodFacts API
    /*
    private func fetchProductBrand(from barcode: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            completion(nil) // Ensure completion is called even on failure
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("OpenFoodFacts request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let product = json["product"] as? [String: Any],
                   let brand = product["brands"] as? String {
                    
                    DispatchQueue.main.async {
                        completion(brand) // Pass the brand to the completion handler
                    }
                } else {
                    print("Brand not found in OpenFoodFacts response")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
*/
    private func fetchProductBrand(from barcode: String, completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            completion(nil, nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ OpenFoodFacts request failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let product = json["product"] as? [String: Any] {

                    let brand = product["brands"] as? String
                    let productOrigin = product["origins"] as? String ?? "Unknown" // Fetch origin info if available

                    DispatchQueue.main.async {
                        completion(brand, productOrigin)
                    }
                } else {
                    print("❌ Brand or Origin not found in OpenFoodFacts response")
                    completion(nil, nil)
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                completion(nil, nil)
            }
        }
        task.resume()
    }

 }
*/
struct TextScannerViewByVisionAPI: View {
    let image: UIImage
    @State private var extractedText: String = "Scanning..."
    @State private var aiResponse: String = "Please press Analyze button..."
    @State private var isScanning = true
    @State private var analysisFailed = false
    @State private var isAnalyzing = false
    
    @State private var detectedBarcode: String = "No barcode detected"
    @State private var productBrand: String = "No productBrand detected"
    @State private var productOrigin: String = "Unknown"
    @State private var brandOwnership: String = "Checking..."
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "YOUR_API_KEY") // Replace with your actual API key
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
                    AnalysisRow(imageName: "text.viewfinder", label: "Detected Text", value: extractedText)
                    AnalysisRow(imageName: "barcode", label: "Detected Barcode", value: detectedBarcode)
                    AnalysisRow(imageName: "building.2", label: "Product Brand", value: productBrand)
                    AnalysisRow(imageName: "globe", label: "Product Origin", value: productOrigin)
                    AnalysisRow(imageName: "factory", label: "Brand Ownership", value: brandOwnership)
                }
                .listStyle(.plain)
            }
            
            Spacer()

            Button(action: {
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
        .navigationBarTitle("Scanned Image", displayMode: .inline)
    }

    // ✅ Perform OCR & Barcode Scanning
    private func analyzeImage() {
        guard let cgImage = image.cgImage else { return }

        isAnalyzing = true
        analysisFailed = false

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        var extractedText: String? = nil
        var detectedBrand: String? = nil
        var barcodeValue: String? = nil

        let dispatchGroup = DispatchGroup()

        // 1️⃣ Start OCR (Text Recognition)
        dispatchGroup.enter()
        let textRequest = VNRecognizeTextRequest { request, error in
            defer { dispatchGroup.leave() }
            if let observations = request.results as? [VNRecognizedTextObservation] {
                extractedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

                DispatchQueue.main.async {
                    self.extractedText = extractedText ?? "No text detected"
                    self.productOrigin = self.detectProductOrigin(from: extractedText ?? "")
                }
            }
        }
        //textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true

        // 2️⃣ Start Barcode Detection
        dispatchGroup.enter()
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            defer { dispatchGroup.leave() }
            if let results = request.results as? [VNBarcodeObservation], let barcode = results.first?.payloadStringValue {
                barcodeValue = barcode
                DispatchQueue.main.async {
                    self.detectedBarcode = barcode
                }
            }
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([textRequest, barcodeRequest])
            } catch {
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.analysisFailed = true
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.isAnalyzing = false

            if let finalText = extractedText, let barcode = barcodeValue {
                self.fetchProductBrand(from: barcode) { brand, origin in
                    DispatchQueue.main.async {
                        self.productBrand = brand ?? "Unknown"
                        self.productOrigin = origin ?? "Unknown"
                    }
                    self.fetchBrandOwnershipOnline(brand: brand ?? "Unknown") { ownership in
                        DispatchQueue.main.async {
                            self.brandOwnership = ownership ?? "Not available"
                            self.startAIAnalysis(brand: brand ?? "Unknown", text: finalText, productOrigin: self.productOrigin)
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
    private func fetchProductBrand(from barcode: String, completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: "\(openFoodFactsApiUrl)\(barcode).json") else {
            completion(nil, nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let product = json["product"] as? [String: Any] {
                    let brand = product["brands"] as? String
                    let origin = product["origins"] as? String ?? "Unknown"
                    completion(brand, origin)
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, nil)
            }
        }
        task.resume()
    }
/*
    // ✅ Fetch Brand Ownership from Government Database
    private func fetchBrandOwnershipOnline(brand: String, completion: @escaping (String?) -> Void) {
        let searchQuery = "Canada company registry \(brand)"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let searchURL = "https://www.ic.gc.ca/app/scr/cc/CorporationsCanada/fdrlCrpSrch.html?q=\(encodedQuery)"

        completion(searchURL) // This will return a direct link for the user to check
    }
*/
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

    // ✅ Run AI Analysis
    private func startAIAnalysis(brand: String, text: String, productOrigin: String) {
        let prompt = """
        Analyze this product's brand and ownership.

        - Brand: \(brand)
        - Product Origin: \(productOrigin)
        - Extracted Text: \(text)

        Provide a structured response:
        (1) Is this brand Canadian-owned?
        (2) Does this brand manufacture in Canada?
        """

        Task {
            let response = try? await model.generateContent(prompt)
            DispatchQueue.main.async {
                self.aiResponse = response?.text ?? "No response from AI."
            }
        }
    }
}


