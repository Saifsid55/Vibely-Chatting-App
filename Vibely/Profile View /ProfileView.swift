//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 03/10/25.
//
import SwiftUI
import FirebaseAuth
import PhotosUI
import _PhotosUI_SwiftUI

struct ProfileView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var tabRouter: TabRouter
    
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State private var showEditOptions = false
    @State private var showFullCoverImage = false
    @State private var disableDragAnimation = false

    @GestureState private var dragTranslation: CGFloat = 0
    @State private var currentOffset: CGFloat = UIScreen.main.bounds.height
    
    private let topLimit: CGFloat = UIScreen.main.bounds.height * 0.1
    private let bottomLimit: CGFloat = UIScreen.main.bounds.height * 0.5
    private let profileImageSize: CGFloat = 100
    
    var body: some View {
//        GeometryReader { geo in
            ZStack(alignment: .top) {
                content
            }
//            .frame(width: geo.size.width, height: geo.size.height)
            .onChange(of: profileVM.profile?.coverPhotoURL) { _, _ in
                disableDragAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    disableDragAnimation = false
                }
            }
            .onAppear {
                Task { await profileVM.loadCurrentUserProfile() }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                    currentOffset = UIScreen.main.bounds.height * 0.25
                }
            }
            .actionSheet(isPresented: $showEditOptions) {
                ActionSheet(
                    title: Text("Cover Photo"),
                    buttons: [
                        .default(Text("Change Picture")) {
                            profileVM.showCoverPicker = true
                        },
                        .default(Text("View Picture")) {
                            showFullCoverImage = true
                        },
                        .cancel()
                    ]
                )
            }
            .fullScreenCover(isPresented: $showFullCoverImage) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    if let coverURL = profileVM.profile?.coverPhotoURL,
                       let url = URL(string: coverURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().tint(.white)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .id(url) // <— ensures new image forces refresh
                                    .onTapGesture { showFullCoverImage = false }
                            case .failure:
                                Text("Failed to load image")
                                    .foregroundStyle(.white)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Text("No Cover Photo")
                            .foregroundStyle(.white)
                    }
                    // ✅ Close Button
                    Button {
                        showFullCoverImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(20)
                    }
                    .padding(.top, 16)
                    .padding(.leading, 16)
                }
            }
            .photosPicker(isPresented: $profileVM.showCoverPicker,
                          selection: $profileVM.selectedCoverItem,
                          matching: .images)
//        }
    }
    
    private var content: some View {
        ZStack(alignment: .top) {
            coverImageLayer
            draggableSheetLayer
            if profileVM.isLoading { loadingOverlay }
        }
    }
    
    private var coverImageLayer: some View {
        ZStack(alignment: .topTrailing) {
            if let coverURL = profileVM.profile?.coverPhotoURL,
               let url = URL(string: coverURL) {
                
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Color.gray.opacity(0.3)
                    }
                }
                .id(url)  // ⬅️ MOST IMPORTANT LINE
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 0)
                .clipped()
                .ignoresSafeArea()
                
            } else {
                Asset.welcomeScreen.swiftUIImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            }
            
            Button {
                showEditOptions = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
                    .padding()
            }
        }
    }

    
    
    private var draggableSheetLayer: some View {
        // MARK: - Draggable Blur Sheet (Your Original Code)
        ZStack(alignment: .top) {
            profileImageView
                .frame(width: profileImageSize, height: profileImageSize)
                .offset(y: -profileImageSize / 2 - 2)
                .zIndex(1)
            
            blurredListView
                .padding(.top, profileImageSize - 4)
                .padding(.horizontal, 16)
                .background {
                    ZStack {
                        RoundedTopArcShape(profileRadius: profileImageSize / 2, padding: 8, cornerRadius: 30)
                            .fill(Color.clear)
                        CustomBlurView(style: .systemChromeMaterialDark, intensity: 0.95)
                            .clipShape(RoundedTopArcShape(profileRadius: profileImageSize / 2, padding: 8, cornerRadius: 30))
                    }
                }
                .cornerRadius(30)
        }
        .scaleEffect(dragTranslation == 0 ? 1.0 : 1 - (abs(dragTranslation) / 2000))
        .shadow(radius: 10 + abs(dragTranslation) / 20)
        .offset(y: max(topLimit, min(bottomLimit, currentOffset + dragTranslation)))
        .animation(
            disableDragAnimation ? nil :
            (dragTranslation == 0 ? .interactiveSpring(response: 0.4, dampingFraction: 0.85) : nil),
            value: currentOffset
        )

        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragTranslation) { value, state, _ in
                    let newOffset = currentOffset + value.translation.height
                    var adjusted = value.translation.height
                    if newOffset < topLimit || newOffset > bottomLimit {
                        adjusted *= 0.4
                    }
                    state = adjusted
                }
                .onEnded { value in
                    let newOffset = currentOffset + value.translation.height
                    let mid = (bottomLimit + topLimit) / 2
                    currentOffset = newOffset < mid ? topLimit : bottomLimit
                }
        )
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(2.0)
                .tint(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.7))
                )
        }
        .transition(.opacity)
    }
    
    
    // MARK: - Profile Image (unchanged)
    @ViewBuilder
    private var profileImageView: some View {
        if let profileImageURL = vm.profileImageURL, !profileImageURL.isEmpty {
            AsyncImage(url: URL(string: profileImageURL)) { phase in
                switch phase {
                case .empty: ProgressView()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure: fallbackInitialsView
                @unknown default: fallbackInitialsView
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
    
    // MARK: - Blurred List (unchanged)
    private var blurredListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text(vm.username)
                    .font(.title2)
                    .fontWeight(.semibold)
                
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
