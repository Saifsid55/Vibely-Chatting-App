//
//  SplashView.swift
//  Vibely
//
//  Created by Mohd Saif on 23/10/25.
//


import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            
            Image("welcome_screen") // Replace with your image asset name
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Spacer()
            
            // App Logo/Title
            Text("FIND")
//                    .font(.system(size: 72, weight: .bold, design: .rounded))
                .font(.custom("PermanentMarker-Regular", size: 72))
                .foregroundStyle(.white)
                .shadow(radius: 10)
                .animation(.easeOut(duration: 1).repeatForever(autoreverses: true), value: animate)
            
            Spacer()

//            VStack {
//                Image(systemName: "bubble.left.and.bubble.right.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 80, height: 80)
//                    .foregroundStyle(.white)
//                    .scaleEffect(animate ? 1 : 0.7)
//                    .opacity(animate ? 1 : 0.5)
//                    .animation(.easeOut(duration: 1).repeatForever(autoreverses: true), value: animate)
//
//                Text("Vibely")
//                    .font(.largeTitle.bold())
//                    .foregroundStyle(.white)
//                    .padding(.top, 12)
//            }
        }
        .onAppear {
            animate = true
        }
        .onDisappear {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}
