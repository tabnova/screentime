//
//  SplashView.swift
//  TabnovaEMM
//
//  Created on 2024
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Hexagon Logo
                ZStack {
                    // Outer hexagon
                    HexagonShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "1A9B8E"), Color(hex: "0D7A70")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // Inner hexagon
                    HexagonShape()
                        .fill(Color(hex: "5DDECD"))
                        .frame(width: 140, height: 140)
                    
                    // Logo text
                    VStack(spacing: 2) {
                        Text("TABNOVA")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "1A9B8E"))
                        Text("Enterprise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "1A9B8E"))
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text("Tabnova Enterprise")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

// Hexagon Shape
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        let points = [
            CGPoint(x: width * 0.5, y: 0),
            CGPoint(x: width, y: height * 0.25),
            CGPoint(x: width, y: height * 0.75),
            CGPoint(x: width * 0.5, y: height),
            CGPoint(x: 0, y: height * 0.75),
            CGPoint(x: 0, y: height * 0.25)
        ]
        
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        
        return path
    }
}

// Color Extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
