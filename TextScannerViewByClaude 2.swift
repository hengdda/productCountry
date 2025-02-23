import SwiftUI
import GoogleCloudVision // For the Google Cloud Vision API
import Alamofire // For networking (if needed for other API calls)


struct TextScannerViewByGOOGLELEN: View {
        @State private var image: UIImage?
        @State private var googleLensResults: [String] = []
        @State private var isAnalyzing: Bool = false
        @State private var error: String?

        // Replace with your actual Google Cloud project ID and service account JSON file path
        let gcpProjectID = "324461723324"
        let serviceAccountJSONPath = Bundle.main.path(forResource: "your_service_account_key", ofType: "json")!


        var body: some View {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                }

                Button("Select Image") {
                    // Show image picker
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = ImagePickerDelegate(parent: self)
                    UIApplication.shared.windows.first?.rootViewController?.present(imagePicker, animated: true)
                }

                Button("Analyze with Google Lens") {
                    guard let image = image else { return }
                    analyzeWithGoogleLens(image: image)
                }
                .disabled(image == nil || isAnalyzing) // Disable if no image or analyzing

                if isAnalyzing {
                    ProgressView()
                }

                if !googleLensResults.isEmpty {
                    List(googleLensResults, id: \.self) { result in
                        Text(result)
                    }
                }

                if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }

        private func analyzeWithGoogleLens(image: UIImage) {
            isAnalyzing = true
            error = nil // Clear any previous errors

            // 1. Convert UIImage to base64 encoded string
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                self.error = "Error converting image to JPEG data."
                isAnalyzing = false
                return
            }

            let base64Image = imageData.base64EncodedString()

            // 2. Set up the Google Cloud Vision API request
            let vision = Vision.shared // Assuming you have initialized the Vision shared instance

            let request = AnnotateImageRequest()
            request.image = GoogleCloudVision.Image(content: base64Image)
            request.features = [.init(type: .productSearch)] // Google Lens product search

            // 3. Make the API call
            vision.annotateImage(request) { (response, err) in
                DispatchQueue.main.async { // Update UI on main thread
                    self.isAnalyzing = false

                    if let err = err {
                        self.error = err.localizedDescription
                        print("Google Lens API Error: \(err)")
                        return
                    }

                    guard let response = response else {
                        self.error = "Invalid response from Google Lens API."
                        return
                    }

                    if let productSearchResults = response.productSearchResults {
                        self.googleLensResults = productSearchResults.map { result in
                            // Extract relevant information from the result dictionary
                            // Customize this based on the API response structure
                            if let title = result.title {
                                return title
                            } else {
                                return "No Title Found"
                            }
                        }
                    } else {
                        self.error = "No product search results found."
                    }
                }
            }
        }
    }


    // Image Picker Delegate (handles image selection)
    class ImagePickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: GoogleLensProductSearchView

        init(parent: GoogleLensProductSearchView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
