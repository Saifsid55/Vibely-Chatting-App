//
//  ProfileView.swift
//  Vibely
//
//  Created by Mohd Saif on 03/10/25.
//  Updated: 2025-11-15 (full integration)
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import _PhotosUI_SwiftUI

struct ProfileView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var profileVM: ProfileViewModel
    
    // MARK: - UI State
    @State private var activeEditType: ImageEditType?
    @State private var cropType: ImageEditType?
    @State private var cropItem: CropImageItem?
    
    @State private var showFullCoverImage: Bool = false
    @State private var showFullProfileImage: Bool = false
    
    @State private var disableDragAnimation = false
    @State private var currentOffset: CGFloat = UIScreen.main.bounds.height
    @GestureState private var dragTranslation: CGFloat = 0
    
    @State private var showEditDialog = false
    //    @State private var cropType: ImageEditType?
    
    private let topLimit: CGFloat = UIScreen.main.bounds.height * 0.1
    private let bottomLimit: CGFloat = UIScreen.main.bounds.height * 0.5
    private let profileImageSize: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .top) {
            content
        }
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
        
        // Generic confirmation dialog for cover/profile actions
        .confirmationDialog(
            "Options",
            isPresented: $showEditDialog,
            titleVisibility: .visible
        ) {
            if cropType == .cover {
                Button("Change Picture") { profileVM.showCoverPicker = true }
                Button("View Picture") { showFullCoverImage = true }
            }
            
            if cropType == .profile {
                Button("Change Picture") { profileVM.showProfilePicker = true }
                Button("View Picture") { showFullProfileImage = true }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        
        // Fullscreen cover image viewer
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
                                .id(url) // ensure refresh when url changes
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
                
                // Close button (top-left)
                VStack {
                    HStack {
                        Button {
                            showFullCoverImage = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(20)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        
        // Fullscreen profile image viewer (1:1 square with black bars top/bottom and dismiss button)
        .fullScreenCover(isPresented: $showFullProfileImage) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let profileURL = profileVM.profile?.photoURL,
                   let url = URL(string: profileURL) {
                    GeometryReader { geo in
                        let side = min(geo.size.width, geo.size.height)
                        VStack {
                            Spacer()
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().tint(.white)
                                        .frame(width: side, height: side)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: side, height: side) // 1:1 square visual
                                        .background(Color.black)
                                        .onTapGesture { showFullProfileImage = false }
                                case .failure:
                                    Text("Failed to load image")
                                        .foregroundStyle(.white)
                                        .frame(width: side, height: side)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    Text("No Profile Photo")
                        .foregroundStyle(.white)
                }
                
                // Close button
                VStack {
                    HStack {
                        Button {
                            showFullProfileImage = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(20)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        
        // Attach both PhotosPickers at root so they can appear from anywhere
        .photosPicker(isPresented: $profileVM.showCoverPicker,
                      selection: $profileVM.selectedCoverItem,
                      matching: .images)
        .photosPicker(isPresented: $profileVM.showProfilePicker,
                      selection: $profileVM.selectedProfileItem,
                      matching: .images)
        
        // Handle cover selection -> set cropType + cropItem
        .onChange(of: profileVM.tempCoverImageData) { _, newValue in
            guard let data = newValue,
                  let img = UIImage(data: data) else { return }
            
            cropType = .cover
            cropItem = CropImageItem(image: img)
        }
        
        // Handle profile selection -> set cropType + cropItem
        .onChange(of: profileVM.tempProfileImageData) { _, newValue in
            guard let data = newValue,
                  let img = UIImage(data: data) else { return }
            
            cropType = .profile
            cropItem = CropImageItem(image: img)
        }
        
        // Cropper fullScreenCover
        .fullScreenCover(item: $cropItem) { item in
            GenericCropView(
                originalImage: item.image,
                aspect: cropType == .profile ? .square : .portraitScreen
            ) { cropped in
                // single crop completion: upload based on cropType
                if let data = cropped.jpegData(compressionQuality: 0.9) {
                    switch cropType {
                    case .cover:
                        Task { await profileVM.uploadCoverPhoto(imageData: data) }
                    case .profile:
                        Task { await profileVM.uploadProfilePhoto(imageData: data) }
                    case .none:
                        break
                    }
                }
                
                // reset states
                cropItem = nil
                cropType = nil
                profileVM.tempCoverImageData = nil
                profileVM.tempProfileImageData = nil
            }
        }
    }
    
    // MARK: - Main content
    private var content: some View {
        ZStack(alignment: .top) {
            coverImageLayer
            draggableSheetLayer
            if profileVM.isLoading { loadingOverlay }
        }
    }
    
    // MARK: - Cover image area
    private var coverImageLayer: some View {
        ZStack(alignment: .topTrailing) {
            if let coverURL = profileVM.profile?.coverPhotoURL,
               let url = URL(string: coverURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    case .empty:
                        Color.gray.opacity(0.3)
                    case .failure:
                        Color.gray.opacity(0.3)
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .id(url)
                .ignoresSafeArea()
            } else {
                Asset.welcomeScreen.swiftUIImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            }
            
            // Edit button for cover
            Button {
                cropType = .cover
                showEditDialog = true
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
    
    // MARK: - Draggable sheet with profile image
    private var draggableSheetLayer: some View {
        ZStack(alignment: .top) {
            profileImageView
                .frame(width: profileImageSize, height: profileImageSize)
                .offset(y: -profileImageSize / 2 - 2)
                .zIndex(1)
                .onTapGesture {
                    cropType = .profile
                    showEditDialog = true
                }
            
            // The sheet content
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
    
    // MARK: - Loading overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            
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
    
    // MARK: - Profile image view
    @ViewBuilder
    private var profileImageView: some View {
        if let profileImageURL = profileVM.profile?.photoURL, !profileImageURL.isEmpty {
            AsyncImage(url: URL(string: profileImageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: profileImageSize, height: profileImageSize)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: profileImageSize, height: profileImageSize)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
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
            .frame(width: profileImageSize, height: profileImageSize)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }
    
    // MARK: - Blurred List Content
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

// MARK: - CropImageItem & ImageEditType
struct CropImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

enum ImageEditType: Identifiable {
    case cover
    case profile
    
    var id: String {
        switch self {
        case .cover: return "cover"
        case .profile: return "profile"
        }
    }
}

//// MARK: - Preview
//#if DEBUG
//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//            .environmentObject(AuthViewModel.sample)
//            .environmentObject(TabRouter())
//            .environmentObject(ProfileViewModel.sample)
//            .previewDevice("iPhone 14")
//    }
//}
//#endif
