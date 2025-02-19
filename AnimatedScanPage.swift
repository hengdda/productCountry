import SwiftUI
import Combine

struct AnimatedScanPage: View {
    @State private var showCountryImage = false // Controls switching between barcode & country image
    @State private var scanLineOffset = -130 // Adjust for correct positioning
    @State private var timerSubscription: Cancellable? // Timer subscription for aut                   o-switching
    @State private var showSubscriptionSheet = false // Controls floating sheet visibility
    @State private var navigateToContentView = false // Controls navigation to ContentView

    var body: some View {
        NavigationStack {
            VStack {
                // Close button (gray "X" at top-left)
                HStack {
                    Button(action: {
                        navigateToContentView = true // Set state to navigate
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                            .padding()
                    }
                    Spacer()
                }

                Spacer()

                // Large area for barcode / country image
                ZStack {
                    if showCountryImage {
                        VStack {
                            Text("The product is manufactured in Canada.")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.bottom, 10)

                            Image("can") // Replace with actual country flag image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .transition(.opacity)
                        }
                    } else {
                        // Barcode Image (for scanning)
                        Image("productinfo") // Replace with actual barcode image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)

                        // Red scanning line (only moving across the barcode)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 300, height: 2)
                            .offset(y: CGFloat(scanLineOffset))
                            .animation(
                                Animation.linear(duration: 2.0)
                                    .repeatForever(autoreverses: false), value: scanLineOffset
                            )
                    }
                }

                Spacer()

                // Start Scanning Button
                Button(action: {
                    //showSubscriptionSheet = true // Show the floating sheet
                    navigateToContentView = true
                }) {
                    Text("Start Scanning")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                // NavigationLink to CameraPreviewView
                            NavigationLink(
                                destination: CameraPreviewView(), // Your destination view
                                isActive: $navigateToContentView // Binding to control navigation
                            ) {
                                EmptyView() // This is necessary, but doesn't show anything
                            }
                            .hidden() // Hide the NavigationLink
            }
            .onAppear {
                // Start red scanning line animation
                scanLineOffset = 130

                // Auto-switch images every 3 seconds
                timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        withAnimation {
                            showCountryImage.toggle()
                        }
                    }
            }
            .onDisappear {
                // Stop the timer when leaving the page
                timerSubscription?.cancel()
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionSheet()
            }
        }
    }
}

// MARK: - Floating Sheet for Subscription
struct SubscriptionSheet: View {
    @Environment(\.dismiss) var dismiss // Allows closing the sheet

    var body: some View {
        VStack(spacing: 20) {
            Text("3-Day Free Trial, $11.99 per Month")
                .font(.title2)
                .fontWeight(.bold)
                .padding()

            Button(action: {
                print("Start Trial Selected") // Replace with actual logic
                dismiss() // Close the sheet
            }) {
                Text("Start Free Trial")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            Button(action: {
                dismiss() // Close the sheet
            }) {
                Text("Cancel")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .presentationDetents([.medium]) // Controls sheet height
    }
}

#Preview {
    AnimatedScanPage()
}

