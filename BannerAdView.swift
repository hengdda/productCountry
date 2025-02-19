
import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    @State private var bannerView: BannerView = BannerView()

    func makeUIView(context: Context) -> BannerView {
        // 配置广告视图
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        bannerView.load(Request())
        bannerView.delegate = context.coordinator
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    // 处理广告加载状态（通过 Coordinator）
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdView

        init(_ parent: BannerAdView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("ads loaded successful")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("ads loaded failed: \(error.localizedDescription)")
        }
    }
}




/*
   
enum AdFormat {
    
    case standardBanner
    case largeBanner
    case mediumRectangle
    case fullBanner
    case leaderboard
    case skyscraper
    case fluid
    
    var adSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width)
   
    var adSize: AdSize {
        switch self {
        case .standardBanner: return AdSizeBanner
        case .largeBanner: return AdSizeLargeBanner
        case .mediumRectangle: return AdSizeMediumRectangle
        case .fullBanner: return AdSizeFullBanner
        case .leaderboard: return AdSizeLeaderboard
        case .skyscraper: return AdSizeSkyscraper
        case .fluid: return AdSizeFluid
        case .adaptiveBanner:
            return currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        }
    }
    
    var size: CGSize {
        adSize.size
    }
     
}
enum AdStatus {
    case loading
    case success
    case failure
}
struct BannerAdView: View {
    let adUnit: AdUnit
    let adFormat: AdFormat
    @Binding var adStatus: AdStatus
    let onShow: () -> Void

    var body: some View {
        HStack {
            if adStatus != .failure {
                /*
                BannerView(adUnitID: adUnit.unitID, adSize: adFormat.adSize, adStatus: $adStatus)
                    //.frame(width: adFormat.size.width, height: adFormat.size.height) // Correct frame modifier usage
                    .onChange(of: adStatus) { status in
                        if status == .success {
                            onShow()
                        }
                    }
                    //.frame(maxWidth: .infinity) // Use CGFloat.infinity
                 */
            } else {
                EmptyView()
            }
        }
    }
}

     */
