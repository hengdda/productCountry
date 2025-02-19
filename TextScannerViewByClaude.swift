import SwiftUI
import Vision
import VisionKit
import UIKit

struct TextScannerViewByClaude: View {
    let image: UIImage
      @State private var extractedText: String = "Scanning..."
      @State private var productLabels: [String] = []
      @State private var isAnalyzing = false
      @State private var showAIAlert = false
      @State private var analysisFailed = false
      @State private var aiResponse: String = "Press Analyze to start."

      @Environment(\.presentationMode) var presentationMode
      
      let apiKey = "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4-nqFQAnL5nQSnVxc-4" // 🔹 Replace with your actual API key
      
      var body: some View {
          VStack {
              // 📸 Product Image
              ZStack {
                  Image(uiImage: image)
                      .resizable()
                      .scaledToFill()
                      .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.22)
                      .clipped()
                      .mask(
                          // ✅ Rounded bottom corners only
                          GeometryReader { geometry in
                              Path { path in
                                  let width = geometry.size.width
                                  let height = geometry.size.height
                                  let cornerRadius: CGFloat = 30

                                  path.move(to: CGPoint(x: 0, y: 0))
                                  path.addLine(to: CGPoint(x: width, y: 0))
                                  path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
                                  path.addArc(center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                                              radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                                  path.addLine(to: CGPoint(x: cornerRadius, y: height))
                                  path.addArc(center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                                              radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
                                  path.closeSubpath()
                              }
                              .fill(Color.white)
                          }
                      )
              }
              .frame(width: UIScreen.main.bounds.width * 0.9)
              .background(Color.white)

              // 📋 Analysis Section
              VStack(alignment: .center) {
                  Text("Analysis Results")
                      .font(.title3)
                      .bold()
                      .frame(maxWidth: .infinity, alignment: .center)
                      .padding(.top)

                  if isAnalyzing {
                      ProgressView("Analyzing...")
                          .padding()
                  } else if analysisFailed {
                      Text("Analysis failed. Try again.")
                          .foregroundColor(.red)
                          .padding()
                  } else {
                      List {
                          AnalysisRow(imageName: "can", label: "Detected Text", value: extractedText)
                          AnalysisRow(imageName: "brand", label: "Product Labels", value: productLabels.joined(separator: ", "))
                      }

                      .listStyle(.plain)
                  }
              }
              
              Spacer()
              
              // 🎛️ Controls: Back & Analyze Button
              HStack {
                  // 🔙 Back Button
                  Button(action: { presentationMode.wrappedValue.dismiss() }) {
                      Image(systemName: "chevron.left")
                          .font(.title2)
                          .foregroundColor(.white)
                          .padding()
                          .background(Color.gray.opacity(0.8))
                          .clipShape(Circle()) // ✅ Circular button
                          .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                  }

                  Spacer()

                  // 🔍 Analyze Button
                  Button(action: {
                      analyzeImageWithGoogleVision(image: image)
                  }) {
                      Text("Analyze")
                          .font(.title3)
                          .foregroundColor(.white)
                          .padding()
                          .frame(maxWidth: .infinity)
                          .background(RoundedRectangle(cornerRadius: 10).fill(Color.red).shadow(radius: 3))
                  }
              }
              .frame(width: UIScreen.main.bounds.width * 0.9)
              .padding()
          }
          .navigationBarHidden(true)
          .onAppear {
              analyzeImageWithGoogleVision(image: image) // Auto-start analysis on appear
          }
      }
      
      // 🧠 AI Image Analysis Using Google Cloud Vision API
      private func analyzeImageWithGoogleVision(image: UIImage) {
          guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

          isAnalyzing = true
          analysisFailed = false

          let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")

          let base64Image = imageData.base64EncodedString()
          let requestBody: [String: Any] = [
              "requests": [
                  [
                      "image": ["content": base64Image],
                      "features": [["type": "TEXT_DETECTION"], ["type": "LABEL_DETECTION"]]
                  ]
              ]
          ]
          
          request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

          DispatchQueue.global(qos: .background).async {
              URLSession.shared.dataTask(with: request) { data, response, error in
                  DispatchQueue.main.async {
                      self.isAnalyzing = false
                      guard let data = data, error == nil else {
                          print("Error: \(error?.localizedDescription ?? "Unknown error")")
                          self.analysisFailed = true
                          return
                      }

                      if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                         let responses = jsonResponse["responses"] as? [[String: Any]] {
                          
                          if let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]] {
                              self.extractedText = textAnnotations.first?["description"] as? String ?? "No text detected"
                          }

                          if let labelAnnotations = responses.first?["labelAnnotations"] as? [[String: Any]] {
                              self.productLabels = labelAnnotations.compactMap { $0["description"] as? String }
                          }
                      } else {
                          self.analysisFailed = true
                      }
                  }
              }.resume()
          }
      }
  }

  // 📦 Helper View: AnalysisRow for Displaying Results
 
