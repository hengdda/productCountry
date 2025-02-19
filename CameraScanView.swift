import SwiftUI
import AVFoundation

struct CameraScanView: View {
    @State private var scannedCode: String? = nil
    @State private var isScanning: Bool = true
    
    var body: some View {
        ZStack {
            BarcodeScannerView(scannedCode: $scannedCode, isScanning: $isScanning)
                .edgesIgnoringSafeArea(.all) // Makes camera full screen
            VStack {
                Spacer()
                if let code = scannedCode {
                                 // Determine the country from the scanned code.
                                 let country = countryForScannedCode(code)
                                 Text("Scanned: \(code)\nCountry: \(country)")
                                     .font(.title2)
                                     .foregroundColor(.white)
                                     .padding()
                                     .background(Color.black.opacity(0.7))
                                     .cornerRadius(10)
                                     .padding(.bottom, 50)
                             }
            //end here
            }
        }
    }
    func countryForScannedCode(_ code: String) -> String {
        // Ensure the code has at least 3 characters and convert the first three to an integer.
        guard code.count >= 3, let prefixNumber = Int(code.prefix(3)) else {
            return "Unknown"
        }
        
        switch prefixNumber {
        case 0, 1:
                return "Most common for U.S.-registered products."
        case 6, 7:
                return "Often used for Canadian-registered products."
        case 2...5, 8...19:
                return "United States and Canada"
        case 20...29:
            return "Restricted distribution"
        case 30...39:
            return "United States drugs (National Drug Code)"
        case 40...49:
            return "Used to issue restricted circulation numbers within a geographic region"
        case 50...59:
            return "Reserved for future use"
        case 60...99:
            return "United States and Canada"
            
        case 100...139:
            return "United States"
        case 200...299:
            return "Restricted distribution"
        case 300...379:
            return "France and Monaco"
        case 380:
            return "Bulgaria"
        case 383:
            return "Slovenia"
        case 385:
            return "Croatia"
        case 387:
            return "Bosnia and Herzegovina"
        case 389:
            return "Montenegro"
            
        case 400...440:
            return "Germany"
        case 450...459:
            return "Japan"
        case 460...469:
            return "Russia"
        case 470:
            return "Kyrgyzstan"
        case 471:
            return "Taiwan"
        case 474:
            return "Estonia"
        case 475:
            return "Latvia"
        case 476:
            return "Azerbaijan"
        case 477:
            return "Lithuania"
        case 478:
            return "Uzbekistan"
        case 479:
            return "Sri Lanka"
        case 480:
            return "Philippines"
        case 481:
            return "Belarus"
        case 482:
            return "Ukraine"
        case 484:
            return "Moldova"
        case 485:
            return "Armenia"
        case 486:
            return "Georgia"
        case 487:
            return "Kazakhstan"
        case 488:
            return "Tajikistan"
        case 489:
            return "Hong Kong"
        case 490...499:
            return "Japan"
            
        case 500...509:
            return "United Kingdom"
        case 520...521:
            return "Greece"
        case 528:
            return "Lebanon"
        case 529:
            return "Cyprus"
        case 530:
            return "Albania"
        case 531:
            return "Macedonia"
        case 535:
            return "Malta"
        case 539:
            return "Ireland"
        case 540...549:
            return "Belgium and Luxembourg"
        case 560:
            return "Portugal"
        case 569:
            return "Iceland"
        case 570...579:
            return "Denmark, Faroe Islands and Greenland"
        case 590:
            return "Poland"
        case 594:
            return "Romania"
        case 599:
            return "Hungary"
            
        case 600...601:
            return "South Africa"
        case 603:
            return "Ghana"
        case 604:
            return "Senegal"
        case 608:
            return "Bahrain"
        case 609:
            return "Mauritius"
        case 611:
            return "Morocco"
        case 613:
            return "Algeria"
        case 615:
            return "Nigeria"
        case 616:
            return "Kenya"
        case 618:
            return "Côte d’Ivoire"
        case 619:
            return "Tunisia"
        case 621:
            return "Syria"
        case 622:
            return "Egypt"
        case 624:
            return "Libya"
        case 625:
            return "Jordan"
        case 626:
            return "Iran"
        case 627:
            return "Kuwait"
        case 628:
            return "Saudi Arabia"
        case 629:
            return "United Arab Emirates"
            
        case 640...649:
            return "Finland"
        case 690...695:
            return "China"
            
        case 700...709:
            return "Norway"
        case 729:
            return "Israel"
        case 730...739:
            return "Sweden"
        case 740:
            return "Guatemala"
        case 741:
            return "El Salvador"
        case 742:
            return "Honduras"
        case 743:
            return "Nicaragua"
        case 744:
            return "Costa Rica"
        case 745:
            return "Panama"
        case 746:
            return "Dominican Republic"
        case 750:
            return "Mexico"
        case 754...755:
            return "Canada"
        case 759:
            return "Venezuela"
            
        case 760...769:
            return "Switzerland and Liechtenstein"
        case 770...771:
            return "Colombia"
        case 773:
            return "Uruguay"
        case 775:
            return "Peru"
        case 777:
            return "Bolivia"
        case 779:
            return "Argentina"
        case 780:
            return "Chile"
        case 784:
            return "Paraguay"
        case 785:
            return "Peru"
        case 786:
            return "Ecuador"
        case 789...790:
            return "Brazil"
            
        case 800...839:
            return "Italy, San Marino and Vatican City"
        case 840...849:
            return "Spain and Andorra"
        case 850:
            return "Cuba"
        case 858:
            return "Slovakia"
        case 859:
            return "Czech Republic"
        case 860:
            return "Serbia"
        case 865:
            return "Mongolia"
        case 867:
            return "North Korea"
        case 868...869:
            return "Turkey"
        case 870...879:
            return "Netherlands"
        case 880:
            return "South Korea"
        case 884:
            return "Cambodia"
        case 885:
            return "Thailand"
        case 888:
            return "Singapore"
        case 890:
            return "India"
        case 893:
            return "Vietnam"
        case 896:
            return "Pakistan"
        case 899:
            return "Indonesia"
            
        case 900...919:
            return "Austria"
        case 930...939:
            return "Australia"
        case 940...949:
            return "New Zealand"
            
        case 950:
            return "GS1 Global Office: Special applications"
        case 951:
            return "EPCglobal: Special applications"
        case 955:
            return "Malaysia"
        case 958:
            return "Macau"
        case 960...969:
            return "GS1 Global Office: GTIN-8 allocations"
        case 977:
            return "Serial publications (ISSN)"
        case 978...979:
            return "Bookland (ISBN)"
        case 980:
            return "Refund receipts"
        case 981...984:
            return "GS1 coupon identification for common currency areas"
        case 990...999:
            return "Coupon identification"
        default:
            return "Unknown"
        }
    }


    
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if !isScanning {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let code = metadataObject.stringValue {
                DispatchQueue.main.async {
                    self.parent.scannedCode = code
                    self.parent.isScanning = false
                }
            }
        }
    }
}

class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .qr] // Supports barcode types
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func stopScanning() {
        captureSession.stopRunning()
    }
}

