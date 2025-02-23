import SwiftUI
import Vision
import VisionKit
import GoogleGenerativeAI
import UIKit

struct TextScannerView: View {
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
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4") // Replace with your actual API key
    @Environment(\.presentationMode) var presentationMode
    @State private var madeByCanadian: String? // Make them optional
    @State private var brandOwnedByCanadian: String?
    @State private var fullyCanadianOwned: String?
    @State private var parentCompany: String?
    @State private var canadianAlternatives: String?
    // State for the prompt
    @State private var showPrompt: Bool = false // State to show the prompt field
    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.22)
                    .clipped()
                    .mask { // Use a mask for rounded bottom corners
                        GeometryReader { geometry in
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height
                                let cornerRadius: CGFloat = 30 // Your corner radius

                                path.move(to: CGPoint(x: 0, y: 0)) // Top-left
                                path.addLine(to: CGPoint(x: width, y: 0)) // Top-right
                                path.addLine(to: CGPoint(x: width, y: height - cornerRadius)) // Move down before rounding
                                path.addArc(
                                    center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                                    radius: cornerRadius,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(90),
                                    clockwise: false
                                ) // Bottom-right corner
                                path.addLine(to: CGPoint(x: cornerRadius, y: height)) // Move to bottom left
                                path.addArc(
                                    center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                                    radius: cornerRadius,
                                    startAngle: .degrees(90),
                                    endAngle: .degrees(180),
                                    clockwise: false
                                ) // Bottom-left corner
                                path.closeSubpath()
                            }
                            .fill(Color.white) // Mask must be a filled shape
                        }
                    }
            }
            .frame(width: UIScreen.main.bounds.width * 0.9)
            .background(Color.white)// ✅ Set background to avoid transparency

            //===================Scanned text===================
            /*
             TextEditor(text: $aiResponse)
             .frame(height: 200) // Set height
             .padding(10) // Inner padding for text
             .background(
             RoundedRectangle(cornerRadius: 15)
             .fill(Color.gray.opacity(0.2)) // Light gray background
             .shadow(radius: 3) // Soft shadow effect
             )
             .overlay(
             RoundedRectangle(cornerRadius: 15)
             .stroke(Color.gray.opacity(0.5), lineWidth: 1) // Border for styling
             )
             .padding(.horizontal) // Outer padding
           */
            //================Analysis results=============
            VStack(alignment: .leading) {
                
                Text("Analysis")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center) // ✅ Centers the text horizontally
                    .padding(.horizontal)

                Spacer() // Push title to the left
                
                
                List {
                    AnalysisRow(imageName: "can", label: "Made By Canada", value: madeByCanadian ?? "Unknown")

                    //AnalysisRow(imageName: "can", label: "Made By Canada", value: $madeByCanadian)
                    AnalysisRow(imageName: "brand", label: "Brand Owned By Canadian", value: brandOwnedByCanadian ?? "Unknown")
                    AnalysisRow(imageName: "canadian", label: "Details Break down", value: fullyCanadianOwned ?? "Unknown")
                    AnalysisRow(imageName: "parent", label: "parent Company", value: parentCompany ?? "Unknown")
                    AnalysisRow(imageName: "alter", label: "Canadian Alternatives", value: canadianAlternatives ?? "Unknown")
                }
                .listStyle(.plain)
            }
            Spacer()
            
            //===================Analysis button===================

       
                HStack{
                    // Back Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.8)) // ✅ Background color
                            .clipShape(Circle()) // ✅ Makes the button fully circular
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3) // ✅ Soft shadow
                    
                    }
                    Spacer() // Push Analyze button toward center
                    Button(action: {
                        extractValues()
                      // Call the helper function
                        showPrompt = true // Show the prompt field
                        //$promptText = extractedText
                        fetchAIAnalysis(for: extractedText)
                    }) {
                        Text("Analyze")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.red).shadow(radius: 3))
                    }
                }.frame(width: UIScreen.main.bounds.width * 0.9)
              .padding()
                       }
        .navigationBarHidden(true) // Hides the "< Back" button
        .onChange(of: aiResponse) { newResponse in
            if !newResponse.isEmpty {
                extractValues() // ✅ Extract values as soon as AI response updates
            }
        }
        .onAppear { extractText(from: image) }
                   .alert("Analysis Summary", isPresented: $showAIAlert) {
                       Button("OK", role: .cancel) {}
                   } message: {
                       Text(aiResponse)
                   }
               }
 
    private func extractValues() {
        guard !aiResponse.isEmpty else { return } // ✅ Ensure AI response exists

        madeByCanadian = aiResponse.extractValue(between: "(QUESTION1)", and: "(QUESTION2)") ?? "Processing.."
        brandOwnedByCanadian = aiResponse.extractValue(between: "(QUESTION2)", and: "(QUESTION3)") ?? "Processing.."
        fullyCanadianOwned = aiResponse.extractValue(between: "(QUESTION3)", and: "(QUESTION4)") ?? "Processing.."
        parentCompany = aiResponse.extractValue(between: "(QUESTION4)", and: "(QUESTION5)") ?? "Processing.."
        canadianAlternatives = aiResponse.extractValue(between: "(QUESTION5)", and: nil) ?? "Processing.." // Last question has no end marker
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
                self.isScanning = false
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
    private func parseAIResponse(_ response: String) {
               madeByCanadian =  response.extractValue(between: #"(QUESTION1)"#, and: #"(QUESTION2)"#)
                brandOwnedByCanadian = response.extractValue(between: #"(QUESTION2)"#, and: #"(QUESTION3)"#)
                fullyCanadianOwned = response.extractValue(between: #"(QUESTION3)"#, and: #"(QUESTION4)"#)
                parentCompany = response.extractValue(between: #"(QUESTION4)"#, and: #"(QUESTION5)"#)
                canadianAlternatives = response.extractValue(between: #"(QUESTION5)"#, and: nil)
    }

    private func fetchAIAnalysis(for text: String) {
        Task {
            do {
                analysisInProgress = true // ✅ Indicate analysis started
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // ✅ 5 seconds
                    return "Timeout"
                }

                let analysisTask = Task {
                    do {
                        let prompt = """
                        Analyze this product label, STRICTLY adhering to the following format for your response:

                        Respond to each question with a concise answer.  Use ONLY the format below, with each answer on a new line:

                        (QUESTION1) [Your Answer Here]
                        (QUESTION2) [Your Answer Here]
                        (QUESTION3) [Your Answer Here]
                        (QUESTION4) [Your Answer Here]
                        (QUESTION5) [Your Answer Here]
                        Below are questions: 
                        (QUESTION1) What is the product name and was this product made by a Canadian company?
                        (QUESTION2) What is the brand name and is the brand owned by a Canadian company?
                        (QUESTION3) "What are the ingredients, manufacturing process, and parent company, are they all Canadian-owned?"
                        (QUESTION4) Who is the parent company, and is it based in Canada?
                        (QUESTION5) What is the brand's category? Within this category, what are the most popular products made in canada?
                        Text: \(text)
                        """
                        
                        let response = try await model.generateContent(prompt)
                        return response.text ?? "No response from AI."
                    } catch {
                        return "Error: \(error.localizedDescription)"
                    }
                }

                let responseText = await withTaskGroup(of: String.self) { taskGroup -> String in
                    taskGroup.addTask { await analysisTask.value }
                    taskGroup.addTask { await timeoutTask.value }
                    
                    return await taskGroup.next() ?? "Unknown Error"
                }

                if responseText == "Timeout" {
                    print("🔄 Timeout! Retrying analysis...")
                    await retryAnalysis(for: text) // ✅ Retry if it took too long
                } else {
                    DispatchQueue.main.async {
                        aiResponse = responseText
                        extractValues() // ✅ Extract values immediately
                        analysisInProgress = false
                        showAIAlert = true
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    aiResponse = "Error: \(error.localizedDescription)"
                    analysisInProgress = false
                    showAIAlert = true
                }
            }
        }
    }

    private func retryAnalysis(for text: String) async {
        print("🔄 Retrying AI analysis...")
        
        let prompt = """
        Analyze this product label:
        (QUESTION1) Was this product made by a Canadian company?
        (QUESTION2) Is the brand owned by a Canadian company?
        (QUESTION3) Are the ingredients, manufacturing process, parent company, and brand all Canadian-owned?
        (QUESTION4) Who is the parent company, and is it based in Canada?
        (QUESTION5) Are there any Canadian alternatives to this product?

        Text: \(text)
        """

        do {
            let response = try await model.generateContent(prompt)
            let responseText = response.text ?? "No response from AI."

            DispatchQueue.main.async {
                aiResponse = responseText
                extractValues() // ✅ Extract values again after retry
                analysisInProgress = false
                showAIAlert = true
            }
        } catch {
            DispatchQueue.main.async {
                aiResponse = "Retry failed: \(error.localizedDescription)"
                analysisInProgress = false
                showAIAlert = true
            }
        }
    }

    
}
extension String {
    func extractValue(between start: String, and end: String?) -> String? {
        guard let startRange = self.range(of: start) else { return nil }

        let rangeAfterStart = self[startRange.upperBound...] // Get text after start marker

        if let end = end, let endRange = rangeAfterStart.range(of: end) {
            let resultRange = startRange.upperBound..<endRange.lowerBound
            return String(self[resultRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // If no end marker, take everything after start marker
            return String(rangeAfterStart).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

struct AIAnalysisResponse: Codable {
    let text: String?
}

struct AnalysisRow: View {
    let imageName: String
    let label: String
    //let value: Binding<String?>
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center) { // Align items vertically in the HStack
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.leading, 5)

                Image(systemName: imageName)
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24) // Set a fixed frame for the SF Symbol
                    .padding(.leading, 5) // Add consistent padding

                Text(label + ":")
                    .foregroundColor(.red)
                    .font(.system(size: 18, weight: .bold))

                Spacer()
            }

            Text(value ?? "Press Analyze button and see results here...")
                .font(.body)
                .foregroundColor(.white)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.8))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.4))
                .shadow(color: .white.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

