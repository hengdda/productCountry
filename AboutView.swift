//
//  AboutViewNew.swift
//  productCountry
//
//  Created by Mac22N on 2025-02-11.
//
import SwiftUI
import StoreKit
import MessageUI

struct AboutView: View {
    @Environment(\.requestReview) var requestReview
    @AppStorage("hasPromptedForReview") private var hasPromptedForReview = false
    @State private var isShowingMailView = false
    
    var body: some View {
        NavigationView { // Embed in NavigationView for consistent styling
            ScrollView { // Use ScrollView for content that might overflow
                VStack(spacing: 20) { // Consistent spacing
                    Image("app_icon") // Replace with your app icon asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(15) // Rounded corners for icon
                    
                    Text("About This App")
                        .font(.largeTitle)
                        .fontWeight(.bold) // More prominent title
                    
                    Text("This app helps users analyze product origins and provides deep insights.")
                        .font(.body) // Use standard body font
                        .multilineTextAlignment(.center)
                        .padding(.horizontal) // Consistent horizontal padding
                    
                    // Rating Button
                    
                        StyledButton(label: "Rate This App", systemImage: "star.fill", action: {
                            requestReview()
                        })
                   
                    
                    // Email Button
                    StyledButton(label: "Send Feedback", systemImage: "envelope.fill", action: {
                        isShowingMailView = true
                    })
                    .sheet(isPresented: $isShowingMailView) {
                        MailView()
                    }
                    
                    Spacer() // Push content to top
                }
                .padding() // Overall padding for the VStack
                .frame(maxWidth: .infinity) // Ensure full width
            }
            /*Aurora'S
             BannerAdView(adUnitID: "ca-app-pub-8031803597671655/4570916389")*/
            /*test id: ca-app-pub-3940256099942544/2435281174*/
            BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                 .frame(width: UIScreen.main.bounds.size.width, height: 50) // Set height for banner
            .navigationTitle("") // Set navigation title
        }
        .onAppear {
            triggerAppReview()
        }
    }
    
    // Reusable Button Style
    struct StyledButton: View {
        let label: String
        let systemImage: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Label(label, systemImage: systemImage)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.vertical, 12) // Consistent vertical padding
                    .padding(.horizontal, 20) // Consistent horizontal padding
                    .frame(maxWidth: .infinity) // Full width button
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
    }
    struct MailView: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> MFMailComposeViewController {
            let mailVC = MFMailComposeViewController()
            mailVC.setToRecipients(["auroratsao@hotmail.com"])
            mailVC.setSubject("Feedback for This App")
            mailVC.setMessageBody("Hi, I have some feedback about your app...", isHTML: false)
            return mailVC
        }
        
        func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    }
    // ✅ Trigger the rating prompt when the app opens for the first time
    private func triggerAppReview() {
        if !hasPromptedForReview {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Delayed to avoid immediate pop-up
                requestReview()
                hasPromptedForReview = true // Ensures it doesn't show again
            }
        }
    }
}
#Preview {
    AboutView()
}
