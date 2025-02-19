//
//  CameraView.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-09.
//
import SwiftUI
import AVFoundation
import Vision

struct CameraView: View {
    @StateObject private var cameraModel = CameraViewModel()

    var body: some View {
        VStack {
            ZStack {
                if let capturedImage = cameraModel.capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: UIScreen.main.bounds.height * 0.8)
                        .clipped()
                        .overlay(GuideLines(), alignment: .center)

                    if let recognizedText = cameraModel.recognizedText {
                        TextOverlay(text: recognizedText)
                    }
                } else {
                    oldCameraPreview(cameraModel: cameraModel)
                        .frame(height: UIScreen.main.bounds.height * 0.8)
                        .overlay(GuideLines(), alignment: .center)

                    Text("平行于参考线拍摄")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
            }

            Spacer()

            HStack {
                Button(action: {
                    cameraModel.showPhotoLibrary = true
                }) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()

                Button(action: {
                    if cameraModel.capturedImage != nil {
                        cameraModel.resetCamera()
                    } else {
                        cameraModel.capturePhoto()
                    }
                }) {
                    Circle()
                        .fill(cameraModel.capturedImage == nil ? Color.blue : Color.red)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }

                Spacer()

                Button(action: {
                    cameraModel.showAIFunctionAlert = true
                }) {
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $cameraModel.showPhotoLibrary) {
            ImagePicker(image: $cameraModel.capturedImage)
        }
        .alert(isPresented: $cameraModel.showAIFunctionAlert) {
            Alert(title: Text("AI Function"), message: Text("AI function triggered"), dismissButton: .default(Text("OK")))
        }
    }
}

// ViewModel to manage camera actions
class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var showPhotoLibrary = false
    @Published var showAIFunctionAlert = false
    @Published var capturedImage: UIImage?
    @Published var recognizedText: String?

    private var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        DispatchQueue.main.async {
            self.capturedImage = image
            self.recognizeText(from: image)
        }
    }

    private func recognizeText(from image: UIImage) {
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
                self.recognizedText = recognizedStrings
            }
        }

        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
            }
        }
    }

    func resetCamera() {
        capturedImage = nil
        recognizedText = nil
    }
}


// Overlay to show extracted text
struct TextOverlay: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
/*
class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var showPhotoLibrary = false
    @Published var showAIFunctionAlert = false
    @Published var capturedImage: UIImage?
    @Published var recognizedText: String?
    
    private var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        DispatchQueue.main.async {
            self.capturedImage = image
            self.recognizeText(from: image)
        }
    }

    private func recognizeText(from image: UIImage) {
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
                self.recognizedText = recognizedStrings
            }
        }

        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
            }
        }
    }
}
*/
struct oldCameraPreview: UIViewControllerRepresentable {
    @ObservedObject var cameraModel: CameraViewModel

    class CameraViewController: UIViewController {
        var captureSession = AVCaptureSession()
        var previewLayer: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            setupCamera()
        }

        func setupCamera() {
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                return
            }

            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            let photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            self.captureSession = captureSession
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.layer.bounds

            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }

            captureSession.startRunning()
        }
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

struct GuideLines: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                let horizontalSpacing = height / 3
                let verticalSpacing = width / 3

                for i in 1..<3 {
                    let y = CGFloat(i) * horizontalSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }

                for i in 1..<3 {
                    let x = CGFloat(i) * verticalSpacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 2)
        }
    }
}



struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
