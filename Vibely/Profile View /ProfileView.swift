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
    @EnvironmentObject var router: Router
    @StateObject private var cvm: CarouselViewModel
    
    
    // MARK: - UI State
    @State private var activeEditType: ImageEditType?
    @State private var cropType: ImageEditType?
    @State private var cropItem: CropImageItem?
    
    @State private var showFullCoverImage: Bool = false
    @State private var showFullProfileImage: Bool = false
    @State private var showEditProfileDetails = false
    
    @State private var disableDragAnimation = false
    @State private var currentOffset: CGFloat = UIScreen.main.bounds.height
    @GestureState private var dragTranslation: CGFloat = 0
    
    @State private var showEditDialog = false
    //    @State private var cropType: ImageEditType?
    
    private let topLimit: CGFloat = UIScreen.main.bounds.height * 0.1
    private let bottomLimit: CGFloat = UIScreen.main.bounds.height * 0.5
    private let profileImageSize: CGFloat = 100
    
    
    init() {
        let vm = CarouselViewModel()
        _cvm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            content
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .modifier(ProfileChangeHandlers(profileVM: profileVM, disableDragAnimation: $disableDragAnimation))
        .modifier(ProfileAppearModifier(profileVM: profileVM, currentOffset: $currentOffset))
        .modifier(EditDialogModifier(
            showEditDialog: $showEditDialog,
            cropType: $cropType,
            profileVM: profileVM,
            showFullCoverImage: $showFullCoverImage,
            showFullProfileImage: $showFullProfileImage
        ))
        .modifier(FullScreenImageViewers(
            showFullCoverImage: $showFullCoverImage,
            showFullProfileImage: $showFullProfileImage,
            profileVM: profileVM
        ))
        .modifier(PhotoPickersModifier(profileVM: profileVM))
        .modifier(CropHandlers(
            profileVM: profileVM,
            cropType: $cropType,
            cropItem: $cropItem
        ))
        
        .fullScreenCover(isPresented: $showEditProfileDetails) {
            EditProfileDetailsView(profileVM: profileVM)
                .environmentObject(profileVM)
        }
    }
    
    // MARK: - View Modifiers
    
    struct ProfileChangeHandlers: ViewModifier {
        @ObservedObject var profileVM: ProfileViewModel
        @Binding var disableDragAnimation: Bool
        
        func body(content: Content) -> some View {
            content
                .onChange(of: profileVM.profile?.coverPhotoURL) { _, _ in
                    disableDragAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        disableDragAnimation = false
                    }
                }
        }
    }
    
    struct ProfileAppearModifier: ViewModifier {
        @ObservedObject var profileVM: ProfileViewModel
        @Binding var currentOffset: CGFloat
        
        func body(content: Content) -> some View {
            content
                .onAppear {
                    Task { await profileVM.loadCurrentUserProfile() }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                        currentOffset = UIScreen.main.bounds.height * 0.25
                    }
                }
        }
    }
    
    struct EditDialogModifier: ViewModifier {
        @Binding var showEditDialog: Bool
        @Binding var cropType: ImageEditType?
        @ObservedObject var profileVM: ProfileViewModel
        @Binding var showFullCoverImage: Bool
        @Binding var showFullProfileImage: Bool
        
        func body(content: Content) -> some View {
            content
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
        }
    }
    
    struct FullScreenImageViewers: ViewModifier {
        @Binding var showFullCoverImage: Bool
        @Binding var showFullProfileImage: Bool
        @ObservedObject var profileVM: ProfileViewModel
        
        func body(content: Content) -> some View {
            content
                .fullScreenCover(isPresented: $showFullCoverImage) {
                    CoverImageViewer(
                        showFullCoverImage: $showFullCoverImage,
                        coverURL: profileVM.profile?.coverPhotoURL
                    )
                }
                .fullScreenCover(isPresented: $showFullProfileImage) {
                    ProfileImageViewer(
                        showFullProfileImage: $showFullProfileImage,
                        profileURL: profileVM.profile?.photoURL
                    )
                }
        }
    }
    
    struct PhotoPickersModifier: ViewModifier {
        @ObservedObject var profileVM: ProfileViewModel
        
        func body(content: Content) -> some View {
            content
                .photosPicker(isPresented: $profileVM.showCoverPicker,
                              selection: $profileVM.selectedCoverItem,
                              matching: .images)
                .photosPicker(isPresented: $profileVM.showProfilePicker,
                              selection: $profileVM.selectedProfileItem,
                              matching: .images)
        }
    }
    
    struct CropHandlers: ViewModifier {
        @ObservedObject var profileVM: ProfileViewModel
        @Binding var cropType: ImageEditType?
        @Binding var cropItem: CropImageItem?
        
        func body(content: Content) -> some View {
            content
                .onChange(of: profileVM.tempCoverImageData) { _, newValue in
                    guard let data = newValue,
                          let img = UIImage(data: data) else { return }
                    
                    cropType = .cover
                    cropItem = CropImageItem(image: img)
                }
                .onChange(of: profileVM.tempProfileImageData) { _, newValue in
                    guard let data = newValue,
                          let img = UIImage(data: data) else { return }
                    
                    cropType = .profile
                    cropItem = CropImageItem(image: img)
                }
                .fullScreenCover(item: $cropItem) { item in
                    GenericCropView(
                        originalImage: item.image,
                        aspect: cropType == .profile ? .square : .portraitScreen
                    ) { cropped in
                        if let data = cropped.jpegData(compressionQuality: 0.9) {
                            switch cropType {
                            case .cover:
                                Task { await profileVM.uploadImage(data, type: .cover) }
                            case .profile:
                                Task { await profileVM.uploadImage(data, type: .profile) }
                            case .none:
                                break
                            }
                        }
                        
                        cropItem = nil
                        cropType = nil
                        profileVM.tempCoverImageData = nil
                        profileVM.tempProfileImageData = nil
                    }
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
            ProfileCoverEditButtons(
                onEditProfileDetails: { showEditProfileDetails = true },
                onEditCover: {
                    cropType = .cover
                    showEditDialog = true
                }
            )
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
            VStack(spacing: 16) {
                
                // USERNAME (always shown)
                Text(profileVM.profile?.username_lowercase ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                profileDetailRow(label: "Bio", value: profileVM.profile?.bio, showTitle: false)
                
                CarouselView(vm: cvm)
                    .frame(height: 150)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 0)
                // EMAIL
                //                if let email = Auth.auth().currentUser?.email {
                //                    Text(email)
                //                        .font(.subheadline)
                //                        .foregroundColor(.gray)
                //                }
                
//                Divider().background(Color.white.opacity(0.3))
                
                // PROFILE DETAILS LIST
                VStack(alignment: .leading, spacing: 12) {
                    
                    profileDetailRow(label: "Name", value: profileVM.profile?.displayName, showTitle: false)
                    
                    profileDetailRow(label: "Age", value: profileVM.profile?.age, showTitle: true)
                    profileDetailRow(label: "Profession", value: profileVM.profile?.profession, showTitle: true)
                    profileDetailRow(label: "Location", value: profileVM.profile?.location, showTitle: false)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    CustomBlurView(style: .regular, intensity: 0.95)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                )
                
     
                .padding(.horizontal, 8)
                
                Divider().background(Color.white.opacity(0.3))
                
                // LOGOUT BUTTON
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
                
                // DELETE ACCOUNT
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
            .padding(.top)
        }
    }
    
    
    @ViewBuilder
    private func profileDetailRow(label: String, value: String?, showTitle: Bool) -> some View {
        if let value = value, !value.trimmingCharacters(in: .whitespaces).isEmpty {
            HStack {
                if showTitle {
                    Text("\(label):")
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.trailing, 8)
                }
                
                Text(value)
                    .foregroundStyle(.white)
            }
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
