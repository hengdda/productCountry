import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAlert = false
    @State private var cameraAccessDenied = false
    @State private var scannedCode = ""
     @State private var capturedImage: UIImage? = nil
     @State private var navigateToResult = false

    var body: some View {
        VStack {
            // Top blue line
            ZStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 50)
                    .padding(.top, 0)
                Text("hello, there")
            }
            
            // Main content
            ZStack {
                if selectedTab == 0 {
                    if cameraAccessDenied {
                        Text("Camera access is required to use this feature.")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        CameraScanView()
                        /*CameraScanView(
                                          scannedCode: $scannedCode,
                                          capturedImage: $capturedImage,
                                          navigateToResult: $navigateToResult
                                      )
                                      .edgesIgnoringSafeArea(.all)*/
                    }
                } else if selectedTab == 1 {
                    ProductListView()
                } else if selectedTab == 2 {
                    SettingsView()
                }
            }
            
            // Bottom Tab Bar
            HStack {
                Button(action: {
                    checkCameraPermission() // Check before switching
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.system(size: 25))
                        Text("Camera")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()

                Button(action: {
                    selectedTab = 1
                }) {
                    VStack {
                        Image(systemName: "list.dash")
                            .font(.system(size: 25))
                        Text("Products")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()

                Button(action: {
                    selectedTab = 2
                }) {
                    VStack {
                        Image(systemName: "gear")
                            .font(.system(size: 25))
                        Text("Settings")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .frame(height: 60)
        }
        .navigationBarBackButtonHidden(true)
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Camera Access Needed"),
                message: Text("Please enable camera access in Settings."),
                primaryButton: .default(Text("Open Settings"), action: {
                    openAppSettings()
                }),
                secondaryButton: .cancel()
            )
        }
    }

    // Function to check and request camera permission
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            selectedTab = 0
            cameraAccessDenied = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        selectedTab = 0
                        cameraAccessDenied = false
                    } else {
                        cameraAccessDenied = true
                        showAlert = true
                    }
                }
            }
        case .denied, .restricted:
            cameraAccessDenied = true
            showAlert = true
        @unknown default:
            cameraAccessDenied = true
        }
    }
    
    // Function to open app settings
    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

