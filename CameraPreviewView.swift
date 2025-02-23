import SwiftUI
import AVFoundation
import PhotosUI
import StoreKit
@available(iOS 16.0, *)
struct CameraPreviewView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var capturedPhoto: UIImage?
    @State private var showPhotoPicker: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showAIAlert: Bool = false
    @State private var isAnalyzing: Bool = false // New state for analysis progress
    @State private var analysisProgress: Double = 0 // For progress bar (optional)
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack{
                    if let image = selectedImage ?? capturedPhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        CameraPreview(cameraManager: cameraManager)
                            .frame(height: UIScreen.main.bounds.height * 0.8)
                            .cornerRadius(20)
                            .overlay(GridOverlay().stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .frame(height: UIScreen.main.bounds.height * 0.7) )
                    }
                    Text("Center product info,not the barcode.Align with guides.")
                                    .foregroundColor(.white)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    GridOverlay()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                            .frame(height: UIScreen.main.bounds.height * 0.8) // Match height exactly
                 
                   
                }
              
                ButtonRow(
                    showPhotoPicker: $showPhotoPicker,
                    selectedPhoto: $selectedPhoto,
                    cameraManager: cameraManager,
                    showAIAlert: $showAIAlert,
                    capturedPhoto: $capturedPhoto
                    // Pass the new binding
                )
                .onChange(of: selectedPhoto) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = uiImage
                                capturedPhoto = uiImage // Auto-navigate when selecting from library
                                cameraManager.capturedImage = nil
                            }
                        }
                    }
                }
                /*Aurora'S
                 BannerAdView(adUnitID: "ca-app-pub-8031803597671655/4570916389")*/
                /*test id: ca-app-pub-3940256099942544/2435281174*/
                BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                    .frame(width: UIScreen.main.bounds.size.width, height: 50) // Set height for banner
            }.background(
                NavigationLink(
                    destination: capturedPhoto.map { //TextScannerView(image: $0)},
                        TextScannerViewByVisionAPI(image: $0)},
                    isActive: Binding(
                        get: { capturedPhoto != nil },
                        //get: $navigateToTextScanner, // Use the new navigation state
                        set: { if !$0 { capturedPhoto = nil } }
                    )
                ) { EmptyView() }
                .hidden()
            ).onAppear {
                // ✅ Reset capturedPhoto when coming back from TextScannerView
                //capturedPhoto = nil
         
                cameraManager.setupCamera()
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = uiImage
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true) 
    }
}

struct GridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let horizontalSpacing = height / 3
        let verticalSpacing = width / 3

        for i in 1..<3 {
            let y = CGFloat(i) * horizontalSpacing
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))

            let x = CGFloat(i) * verticalSpacing
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
        }
        return path
    }
}

struct ButtonRow: View {
    @Binding var showPhotoPicker: Bool
    @Binding var selectedPhoto: PhotosPickerItem?
    @ObservedObject var cameraManager: CameraManager
    @Binding var showAIAlert: Bool
    @Binding var capturedPhoto: UIImage?
    @State private var isProcessing: Bool = false // Processing state
    @State private var showAboutPage = false
  
    var body: some View {
        HStack{
            Spacer()
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Circle()
                    .fill(Color.gray.opacity(0.85))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            .padding(.leading)

            Spacer()

            ZStack {
                // Camera Button
                Button(action: {
                    DispatchQueue.main.async {
                        isProcessing = true // Show progress
                    }

                    cameraManager.takePhoto { image in
                        DispatchQueue.main.async {
                            if let image = image {
                                capturedPhoto = image
                                // Simulate processing time (Replace this with actual logic)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isProcessing = false // Hide progress after 2 seconds
                                }
                            } else {
                                isProcessing = false // Stop processing if failed
                            }
                        }
                    }
                }) {
                    Circle()
                        .fill(Color.gray.opacity(0.85))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "camera")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                        )
                }
                .disabled(cameraManager.isTakingPhoto || isProcessing) // Disable during processing

                // Progress View Overlay
                if isProcessing {
                    Circle()
                        .fill(Color.black.opacity(0.3)) // Dimmed background
                        .frame(width: 60, height: 60)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
            Spacer()

            // ℹ️ About Button
          Button(action: {
                 
                            showAboutPage = true
                        }) {
                            Circle()
                                .fill(Color.gray.opacity(0.85))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 25))
                                        .foregroundColor(.white)
                                )
                        }
                        .sheet(isPresented: $showAboutPage) { // ✅ Shows AboutView as a modal
                            AboutView()
                        }
                        .padding(.trailing)

            Spacer()
        }
        //.background(Color.black.opacity(0.95))
    }
}


struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let previewLayer = cameraManager.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = cameraManager.previewLayer, previewLayer.superlayer == nil {
                previewLayer.frame = uiView.bounds
                uiView.layer.addSublayer(previewLayer)
            }
        }
    }
}
#Preview {
    CameraPreviewView()
}
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
        @Published var captureSession: AVCaptureSession?
        @Published var previewLayer: AVCaptureVideoPreviewLayer?
        @Published var capturedImage: UIImage?
        @Published var isTakingPhoto: Bool = false

        private var photoOutput = AVCapturePhotoOutput()
        private var photoCompletionHandler: ((UIImage?) -> Void)?

        func setupCamera() {
            let session = AVCaptureSession()
            self.captureSession = session

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("Could not create capture device.")
                return
            }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                } else {
                    print("Could not add input to capture session.")
                    return
                }

                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                } else {
                    print("Could not add output to capture session.")
                    return
                }

                previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer?.videoGravity = .resizeAspectFill

                DispatchQueue.global(qos: .background).async {
                    session.startRunning()
                }

            } catch {
                print("Error setting up capture session: \(error)")
            }
        }

        func takePhoto(completion: @escaping (UIImage?) -> Void) {
            isTakingPhoto = true
            photoCompletionHandler = completion

            let photoSettings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error)")
                isTakingPhoto = false
                photoCompletionHandler?(nil)
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("Error converting photo to UIImage.")
                isTakingPhoto = false
                photoCompletionHandler?(nil)
                return
            }

            DispatchQueue.main.async {
                self.isTakingPhoto = false
                self.photoCompletionHandler?(image)
            }
        }
    }

