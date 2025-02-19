    //
    //  CameraScanGemini.swift
    //  productCountry
    //
    //  Created by Mac22N on 2025-02-08.
    //
    import SwiftUI
    import AVFoundation
    import Vision
    import GoogleGenerativeAI
/*
    struct CameraScanGemini: View {
        @State private var scannedText: String = ""
        @State private var isSheetPresented: Bool = false
        @State private var shouldRestartScanning: Bool = false
        @State private var aiResponse: String = "Waiting for response..."
        @State private var isConfirmed: Bool = false
        let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4")

        var body: some View {
            ZStack {
                CameraPreview(scannedText: $scannedText, isSheetPresented: $isSheetPresented, shouldRestartScanning: $shouldRestartScanning, aiResponse: $aiResponse, model: model)
                    .edgesIgnoringSafeArea(.all)

                if isSheetPresented {
                    FloatingSheet(scannedText: scannedText, aiResponse: $aiResponse, isSheetPresented: $isSheetPresented, shouldRestartScanning: $shouldRestartScanning, isConfirmed: $isConfirmed, model: model)
                                  .transition(.move(edge: .bottom))
                                  .animation(.spring())
                          }
            }
        }
    }

    // MARK: - Floating Sheet View
    struct FloatingSheet: View {
        var scannedText: String
        @Binding var aiResponse: String
        @Binding var isSheetPresented: Bool
        @Binding var shouldRestartScanning: Bool
        @Binding var isConfirmed: Bool
            let model: GenerativeModel
        var body: some View {
            VStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                ScrollView {
                    Text(scannedText.isEmpty ? "No text detected" : scannedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.92))
                        .cornerRadius(10)
                    if isConfirmed {
                        Text(aiResponse)
                            .padding()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .frame(height: 250)
                .padding(.horizontal)
                if !isConfirmed {
                    Button(action: {
                        isConfirmed = true
                        fetchAIResponse(for: scannedText)
                    }) {
                        Text("Confirm Text & Ask AI")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                Button(action: {
                    isSheetPresented = false
                    shouldRestartScanning = true
                    isConfirmed = false
                }) {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            
        }
        
        private func fetchAIResponse(for text: String) {
               Task {
                   do {
                                   let response = try await model.generateContent( "Where is this product made in? The text on it says: \(text)")
                                   DispatchQueue.main.async {
                                       aiResponse = response.text ?? "No response from AI."  // ✅ Now modifying via @Binding
                                   }
                               } catch {
                                   DispatchQueue.main.async {
                                                      aiResponse = "Error: \(error.localizedDescription)"
                                                  }
                   }
               }
           }
       }

    // MARK: - Camera Preview
    struct CameraPreview: UIViewControllerRepresentable {
        @Binding var scannedText: String
        @Binding var isSheetPresented: Bool
        @Binding var shouldRestartScanning: Bool
        @Binding var aiResponse: String
        let model: GenerativeModel

        func makeCoordinator() -> Coordinator {
            return Coordinator(scannedText: $scannedText, isSheetPresented: $isSheetPresented, shouldRestartScanning: $shouldRestartScanning, aiResponse: $aiResponse, model: model)
        }

        func makeUIViewController(context: Context) -> CameraViewController {
            let cameraVC = CameraViewController()
            cameraVC.delegate = context.coordinator
            return cameraVC
        }

        func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
            if shouldRestartScanning {
                uiViewController.restartScanning()
                shouldRestartScanning = false
            }
        }
    }

    // MARK: - Camera Logic
    class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate: Coordinator?
        var hasScannedText = false

        override func viewDidLoad() {
            super.viewDidLoad()
            setupCamera()
        }

        func setupCamera() {
            captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.layer.bounds
            view.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        }

        func restartScanning() {
            hasScannedText = false
            captureSession.startRunning()
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard !hasScannedText, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            processImage(ciImage)
        }

        func processImage(_ ciImage: CIImage) {
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let results = request.results as? [VNRecognizedTextObservation] else { return }

                let extractedText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")

                DispatchQueue.main.async {
                    if !extractedText.isEmpty {
                        self?.delegate?.scannedText.wrappedValue = extractedText
                        self?.delegate?.isSheetPresented.wrappedValue = true
                        self?.hasScannedText = true
                        self?.captureSession.stopRunning()
                        
                        // Send text to Gemini AI
                        self?.delegate?.fetchAIResponse(for: extractedText)
                    }
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
            }
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        var scannedText: Binding<String>
        var isSheetPresented: Binding<Bool>
        var shouldRestartScanning: Binding<Bool>
        var aiResponse: Binding<String>
        let model: GenerativeModel

        init(scannedText: Binding<String>, isSheetPresented: Binding<Bool>, shouldRestartScanning: Binding<Bool>, aiResponse: Binding<String>, model: GenerativeModel) {
            self.scannedText = scannedText
            self.isSheetPresented = isSheetPresented
            self.shouldRestartScanning = shouldRestartScanning
            self.aiResponse = aiResponse
            self.model = model
        }

        func fetchAIResponse(for text: String) {
            Task {
                do {
                    let response = try await model.generateContent("Where is this product made in? The text on it says: \(text)")
                    DispatchQueue.main.async {
                        self.aiResponse.wrappedValue = response.text ?? "No response from AI."
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.aiResponse.wrappedValue = "Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

*/

struct CameraScanGemini: View {
    @State private var scannedText: String = ""
    @State private var isSheetPresented: Bool = false
    @State private var shouldRestartScanning: Bool = false
    @State private var aiResponse: String = "Waiting for response..."
    @State private var isConfirmed: Bool = false
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyAW_ZQrncB-iITVLJCgUTEFf7s1dBav4H4")

    var body: some View {
        ZStack {
            YCameraPreview(
                scannedText: $scannedText,
                isSheetPresented: $isSheetPresented,
                shouldRestartScanning: $shouldRestartScanning,
                aiResponse: $aiResponse,
                isConfirmed: $isConfirmed, // ✅ Pass confirmation state
                model: model
            )
            .edgesIgnoringSafeArea(.all)

            if isSheetPresented {
                FloatingSheet(
                    scannedText: scannedText,
                    aiResponse: $aiResponse,
                    isSheetPresented: $isSheetPresented,
                    shouldRestartScanning: $shouldRestartScanning,
                    isConfirmed: $isConfirmed, // ✅ Ensure state updates
                    model: model
                )
                .transition(.move(edge: .bottom))
                .animation(.spring())
            }
        }
    }
}

// MARK: - Floating Sheet View
struct FloatingSheet: View {
    var scannedText: String
    @Binding var aiResponse: String
    @Binding var isSheetPresented: Bool
    @Binding var shouldRestartScanning: Bool
    @Binding var isConfirmed: Bool
    let model: GenerativeModel

    var body: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .padding(.top, 20)

            ScrollView {
                Text(scannedText.isEmpty ? "No text detected" : scannedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.92))
                    .cornerRadius(10)

                if isConfirmed {
                    Text(aiResponse)
                        .padding()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            .frame(height: 250)
            .padding(.horizontal)

            if !isConfirmed {
                Button(action: {
                    isConfirmed = true // ✅ Stop scanning
                    fetchAIResponse(for: scannedText)
                }) {
                    Text("Confirm Text & Ask AI")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            if !isConfirmed { // ✅ Hide Close button when confirmed
                Button(action: {
                    isSheetPresented = false
                    shouldRestartScanning = true
                    isConfirmed = false
                }) {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 50)
    }

    /// Fetch AI response and update the binding
    private func fetchAIResponse(for text: String) {
        Task {
            do {
                let response = try await model.generateContent( "Where is this product made in? The text on it says: \(text)")
                DispatchQueue.main.async {
                    aiResponse = response.text ?? "No response from AI."
                }
            } catch {
                DispatchQueue.main.async {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Camera Preview
struct YCameraPreview: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var isSheetPresented: Bool
    @Binding var shouldRestartScanning: Bool
    @Binding var aiResponse: String
    @Binding var isConfirmed: Bool // ✅ Track confirmation state
    let model: GenerativeModel

    func makeCoordinator() -> Coordinator {
          return Coordinator(
              scannedText: $scannedText,
              isSheetPresented: $isSheetPresented,
              shouldRestartScanning: $shouldRestartScanning,
              aiResponse: $aiResponse,
              isConfirmed: $isConfirmed, // ✅ Ensure updates
              model: model
          )
      }

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController()
        cameraVC.delegate = context.coordinator
        return cameraVC
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if shouldRestartScanning {
            uiViewController.restartScanning()
            shouldRestartScanning = false
        }
    }
}

// MARK: - Camera Logic
class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: Coordinator?
    var hasScannedText = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func restartScanning() {
        hasScannedText = false
        captureSession.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !hasScannedText, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        processImage(ciImage)
    }

    func processImage(_ ciImage: CIImage) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }

            let extractedText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")

            DispatchQueue.main.async {
                if !extractedText.isEmpty {
                    self?.delegate?.scannedText.wrappedValue = extractedText
                    self?.delegate?.isSheetPresented.wrappedValue = true
                    self?.hasScannedText = true
                    self?.captureSession.stopRunning() // ✅ Stop scanning when text is found
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error)")
        }
    }
}
class Coordinator: NSObject {
    var scannedText: Binding<String>
    var isSheetPresented: Binding<Bool>
    var shouldRestartScanning: Binding<Bool>
    var aiResponse: Binding<String>
    var isConfirmed: Binding<Bool> // ✅ Added this missing parameter
    let model: GenerativeModel

    init(scannedText: Binding<String>,
         isSheetPresented: Binding<Bool>,
         shouldRestartScanning: Binding<Bool>,
         aiResponse: Binding<String>,
         isConfirmed: Binding<Bool>, // ✅ Added this
         model: GenerativeModel) {
        
        self.scannedText = scannedText
        self.isSheetPresented = isSheetPresented
        self.shouldRestartScanning = shouldRestartScanning
        self.aiResponse = aiResponse
        self.isConfirmed = isConfirmed  // ✅ Ensure this is stored
        self.model = model
    }
}
