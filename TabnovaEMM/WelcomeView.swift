//
//  WelcomeView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 60)
                
                // Logo
                ZStack {
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "1A9B8E"), Color(hex: "0D7A70")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    HexagonShape()
                        .fill(Color(hex: "5DDECD"))
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 1) {
                        Text("TABNOVA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "1A9B8E"))
                        Text("Enterprise")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Color(hex: "1A9B8E"))
                    }
                }
                
                // Title
                Text("Welcome to\nTabnova Enterprise")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // Description
                VStack(alignment: .leading, spacing: 15) {
                    Text("This is a MDM ( Mobile Device Management ) Application. Your company's administrator will have access to the following data.")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.system(size: 16))
                            Text("Location: If location tracking is enabled then location policies can be enforced by your IT administrator")
                                .font(.system(size: 16))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.system(size: 16))
                            Text("Camera: Allows the app to scan QR code")
                                .font(.system(size: 16))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .foregroundColor(.black)
                    
                    Text("Disclaimer: Tabnova Enterprise does not access your personal data. User data will not be shared with third parties as per Apple guidelines")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 5)
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: onContinue) {
                        Text("Agree and Proceed")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "1A9B8E"))
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 50)
                    
                    Button(action: {
                        if let url = URL(string: "https://www.tabnova.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Privacy Policy")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "1A9B8E"))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(onContinue: {})
    }
}
