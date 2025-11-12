//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 03/10/25.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var tabRouter: TabRouter
    
    @State private var initialOffset: CGFloat = UIScreen.main.bounds.height
    @State private var currentOffset: CGFloat = UIScreen.main.bounds.height
    
    @GestureState private var dragOffset: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0
    
    private let topLimit: CGFloat = UIScreen.main.bounds.height * 0.1
    private let bottomLimit: CGFloat = UIScreen.main.bounds.height * 0.5
    private let profileImageSize: CGFloat = 100
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                // MARK: - Background Cover Image
                Image("welcome_screen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)
                
                // MARK: - Draggable Blur Sheet
                ZStack(alignment: .top) {
                    profileImageView
                        .frame(width: profileImageSize, height: profileImageSize)
                        .offset(y: -profileImageSize / 2 - 2)
                        .zIndex(1)
                    
                    blurredListView
                        .padding(.top, profileImageSize - 4)
                        .padding(.horizontal, 16)
                        .background {
                            // Use a ZStack to clip the blur properly
                            ZStack {
                                RoundedTopArcShape(profileRadius: profileImageSize / 2, padding: 8, cornerRadius: 30)
                                    .fill(Color.clear)
                                
                                CustomBlurView(style: .systemThinMaterialDark, intensity: 0.9)
                                    .clipShape(RoundedTopArcShape(profileRadius: profileImageSize / 2, padding: 8, cornerRadius: 30))
                            }
                        }
                        .cornerRadius(30)
                }
                // Smooth scale effect with animation only on gesture end
                .scaleEffect(dragTranslation == 0 ? 1.0 : 1 - (abs(dragTranslation) / 2000))
                .shadow(radius: 10 + abs(dragTranslation) / 20)
                .offset(y: max(topLimit, min(bottomLimit, currentOffset + dragTranslation)))
                // Only animate when gesture ends (dragTranslation returns to 0)
                .animation(dragTranslation == 0 ? .interactiveSpring(response: 0.4, dampingFraction: 0.85) : nil, value: currentOffset)
                
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragTranslation) { value, state, _ in
                            let newOffset = currentOffset + value.translation.height
                            var adjustedTranslation = value.translation.height
                            
                            // Soft resistance near edges
                            if newOffset < topLimit {
                                adjustedTranslation *= 0.4
                            } else if newOffset > bottomLimit {
                                adjustedTranslation *= 0.4
                            }
                            
                            state = adjustedTranslation
                        }
                        .onEnded { value in
                            let newOffset = currentOffset + value.translation.height
                            let midPoint = (bottomLimit + topLimit) / 2
                            
                            // Update offset, animation will be applied by the .animation modifier above
                            if newOffset < midPoint {
                                currentOffset = topLimit
                            } else {
                                currentOffset = bottomLimit
                            }
                        }
                )
            }
            .onAppear {
                // Always start hidden
                currentOffset = UIScreen.main.bounds.height
                // Then animate into position
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                    currentOffset = UIScreen.main.bounds.height * 0.25
                }
            }
            .onDisappear {
                // Instantly reset when leaving
                withTransaction(Transaction(animation: .none)) {
                    currentOffset = UIScreen.main.bounds.height
                }
            }
        }
    }
    
    // MARK: - Profile Image
    @ViewBuilder
    private var profileImageView: some View {
        if let profileImageURL = vm.profileImageURL, !profileImageURL.isEmpty {
            AsyncImage(url: URL(string: profileImageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(width: 100, height: 100)
                case .success(let image):
                    image.resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle())
                case .failure:
                    fallbackInitialsView
                @unknown default:
                    fallbackInitialsView
                }
            }
        } else {
            fallbackInitialsView
        }
    }
    
    private var fallbackInitialsView: some View {
        Circle()
            .fill(Color.blue)
            .overlay(
                Text(vm.username.prefix(1).uppercased())
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
            .frame(width: 100, height: 100)
    }
    
    private var blurredListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text(vm.username)
                    .font(.title2)
                    .fontWeight(.semibold)
//                    .padding(.top, 60)
                
                if let email = Auth.auth().currentUser?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Joined")
                        Spacer()
                        Text("January 2024")
                    }
                    .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Text("Account Type")
                        Spacer()
                        Text("Standard")
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                
                Divider().background(Color.white.opacity(0.3))
                
                Button(role: .destructive) {
                    vm.signOut()
                } label: {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button {
                    Task {
                        do { try await vm.deleteUserAccount() }
                        catch { print("❌", error.localizedDescription) }
                    }
                } label: {
                    Text("Delete Account")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                .padding(.bottom, 40)
            }
            .padding(.top, profileImageSize / 2)
        }
    }
}
