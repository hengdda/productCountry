import SwiftUI
import AVFoundation

struct ContentView: View {
    // Tab selection index
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            // Top blue line
            ZStack{
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 50)
                    .padding(.top, 0)
                Text("hello, there")
            }
           
            
            // Main content
            ZStack {
                if selectedTab == 0 {
                    // Camera Tab
                    CameraScanView()
                } else if selectedTab == 1 {
                    // Product List Tab
                    ProductListView()
                } else if selectedTab == 2 {
                    // Settings Tab
                    SettingsView()
                }
            }
            
            // Bottom Tab Bar
            HStack {
                // Camera Tab
                Button(action: {
                    selectedTab = 0
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
                
                // Product List Tab
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
                
                // Settings Tab
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
        .edgesIgnoringSafeArea(.bottom) // To make sure the bottom tab bar is not cut off
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        //MainView()
        AnimatedScanPage()
    }
}
