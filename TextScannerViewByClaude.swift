import SwiftUI
import Vision
import VisionKit
import GoogleGenerativeAI
import UIKit

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
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4") // Replace with your actual API key
    @Environment(\.presentationMode) var presentationMode
    @State private var madeByCanadian: String? // Make them optional
    @State private var brandOwnedByCanadian: String?
    @State private var fullyCanadianOwned: String?
    @State private var parentCompany: String?
    @State private var canadianAlternatives: String?
    // State for the prompt
    @State private var showPrompt: Bool = false // State to show the prompt field
   
    let visionApiKey = "AIzaSyAvxXhFhAtgM_rAZ-nqFQAnL5nQSnVxc-4"  // Replace with your actual key
        let openFoodFactsApiUrl = "https://world.openfoodfacts.org/api/v0/product/"
   
    var body: some View {
        VStack {/*
           VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.22)
                    .clipped()
                Text("Extracted Text: \(extractedText)")
                Spacer()
                Text("Detected Barcode: \(detectedBarcode)")
               // Text("productBrandOrigin Barcode: \(productBrandOrigin)")
               Spacer()
               Button(action: { analyzeImage() }) {
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
            
        }*/
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
    private func analyzeImage() {
        guard let cgImage = image.cgImage else { return }

        isAnalyzing = true
        analysisFailed = false

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // 1️⃣ Text Recognition Request (OCR)
         let textRequest = VNRecognizeTextRequest { request, error in
             if let observations = request.results as? [VNRecognizedTextObservation] {
                 let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                 
                 DispatchQueue.main.async {
                     self.extractedText = recognizedText.isEmpty ? "No text detected" : recognizedText
                     
                     // ✅ If text is detected, call Gemini AI analysis
                     if !recognizedText.isEmpty {
                         self.analyzeWithGeminiAI(text: recognizedText)
                     }
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
       // ✅ Step 2: Google Gemini AI - Analyze Product Origins
         private func analyzeWithGeminiAI(text: String) {
                 guard !text.isEmpty else { return }

                 let prompt = """
                 Analyze this product label:
                 (QUESTION1) Was this product made by a Canadian company?
                 (QUESTION2) Is the brand owned by a Canadian company?
                 (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
                 (QUESTION4) Who is the parent company, and is it based in Canada?
                 (QUESTION5) Are there any Canadian alternatives to this product?

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

             // ✅ Step 3: Extract Values from AI Response
             private func extractValues(from response: String) {
                 madeByCanadian = response.extractValue(between: "(QUESTION1)", and: "(QUESTION2)") ?? "Unknown"
                 brandOwnedByCanadian = response.extractValue(between: "(QUESTION2)", and: "(QUESTION3)") ?? "Unknown"
                 fullyCanadianOwned = response.extractValue(between: "(QUESTION3)", and: "(QUESTION4)") ?? "Unknown"
                 parentCompany = response.extractValue(between: "(QUESTION4)", and: "(QUESTION5)") ?? "Unknown"
                 canadianAlternatives = response.extractValue(between: "(QUESTION5)", and: nil) ?? "Unknown"
             }
/*
    // 🔹 Step 1: Extract text & barcode using Google Vision API
        private func analyzeImage() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            isAnalyzing = true
            analysisFailed = false

            let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(visionApiKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let base64Image = imageData.base64EncodedString()
            let requestBody: [String: Any] = [
                "requests": [
                    [
                        "image": ["content": base64Image],
                        "features": [["type": "TEXT_DETECTION"], ["type": "LABEL_DETECTION"], ["type": "BARCODE_DETECTION"]]
                    ]
                ]
            ]

            request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    guard let data = data, error == nil else {
                        print("❌ Google Vision API Error:", error?.localizedDescription ?? "Unknown error")
                        self.analysisFailed = true
                        return
                    }

                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responses = jsonResponse["responses"] as? [[String: Any]] {

                        if let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]] {
                            self.extractedText = textAnnotations.first?["description"] as? String ?? "No text detected"
                            print("🔠 Extracted Text:", self.extractedText)
                        }

                        if let barcodeAnnotations = responses.first?["barcodes"] as? [[String: Any]] {
                            self.detectedBarcode = barcodeAnnotations.first?["description"] as? String ?? "No barcode detected"
                            print("📦 Detected Barcode:", self.detectedBarcode)
                        }

                        // 🔹 Step 2: Fetch product details if barcode is found
                        if self.detectedBarcode != "No barcode detected" {
                            print("detect barcode??")
                           // self.fetchProductDetails(barcode: self.detectedBarcode)
                        }
                    } else {
                        print("⚠️ Failed to parse JSON response")
                        self.analysisFailed = true
                    }
                }
            }.resume()
        }
 */
 }


