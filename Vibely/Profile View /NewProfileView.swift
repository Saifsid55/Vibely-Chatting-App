//
//  ProfileView.swift
//  Vibely
//
//  Redesigned with scrollable overlay and fade effects
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import _PhotosUI_SwiftUI

struct NewProfileView: View {
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
    
    
    private let topLimit: CGFloat = UIScreen.main.bounds.height * 0.1
    private let bottomLimit: CGFloat = UIScreen.main.bounds.height * 0.55
    private let profileImageSize: CGFloat = 100
    
    
    init() {
        let vm = CarouselViewModel()
        _cvm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-screen background image with fade effect
            coverImage
            CustomBlurView(style: .systemUltraThinMaterialDark, intensity: blurIntensity)
                .ignoresSafeArea()
            CustomBlurView(style: .systemChromeMaterialDark, intensity: 1.0)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.0), location: 0.0),   // No blur at top
                            .init(color: .black.opacity(0.0), location: 0.40),
                            .init(color: .black.opacity(0.4), location: 0.50),
                            .init(color: .black.opacity(1.0), location: 0.75),  // Mid blur
                            .init(color: .black.opacity(1.0), location: 1.0),   // Full blur bottom
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
                .ignoresSafeArea()
            draggableSheetLayer
            
        }
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
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if tabRouter.selectedTab == .profile && tabRouter.allowCollapse {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        tabRouter.isTabBarCollapsed = true
                    }
                }
            }
        }
        .onDisappear {
            // restore allowCollapse so other flows behave normally
            tabRouter.allowCollapse = true
        }
    }
    
    var coverImage: some View {
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
            
            ProfileCoverEditButtons(
                onEditProfileDetails: { showEditProfileDetails = true },
                onEditCover: {
                    cropType = .cover
                    showEditDialog = true
                }
            )
        }
    }
    
    
    private var draggableSheetLayer: some View {
        VStack(alignment: .leading, spacing: 4) {
            topProfileView
                .padding(.top, 16)
            HobbiesRow(hobbies: ["Gym", "Travel", "Cooking", "Music"])
                .padding(.leading, 24)
            blurredListView
                .background(Color.clear)
            
        }
//        .background {
//            Rectangle()
//                .fill(.ultraThinMaterial)          // Actual blur layer
//                .blur(radius: 40)
//                .mask(
//                    LinearGradient(
//                        gradient: Gradient(stops: [
//                            .init(color: Color.black.opacity(0.0), location: 0.0),   // Top
//                            .init(color: Color.black.opacity(0.8), location: 0.15),   // Middle
//                            .init(color: Color.black.opacity(1.0), location: 1.0),   // Bottom
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
////                .opacity(pow(-blurIntensity, 1.4))
//                .ignoresSafeArea()
//        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
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
    
    private var topProfileView: some View {
        
        HStack( spacing: 8) {
            profileImageView
                .frame(width: profileImageSize, height: profileImageSize)
                .onTapGesture {
                    cropType = .profile
                    showEditDialog = true
                }
                .padding(.leading, 16)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                profileDetailRow(label: "Name", value: profileVM.profile?.displayName, showTitle: false, showIcon: false)
                    .font(.title)
                    .fontWeight(.bold)
                profileDetailRow(label: "Bio", value: profileVM.profile?.bio, showTitle: false, showIcon: false)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
        }
        
    }
    
    private var blurredListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                
                Text(profileVM.profile?.username_lowercase ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.leading, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    profileDetailRow(label: "Age", value: profileVM.profile?.age, showTitle: true, showIcon: false)
                    profileDetailRow(label: "Profession", value: profileVM.profile?.profession, showTitle: true, showIcon: false)
                    profileDetailRow(label: "Location", value: "Lucknow, Uttar Pradesh", showTitle: true, showIcon: false)
                }
                .padding(.leading, 24)
                
                CarouselView(vm: cvm)
                    .frame(height: 150)
                    .padding(.top, 16)
            }
        }
    }
    
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
            .overlay(content: {
                Text(vm.username.prefix(1).uppercased())
                    .font(.largeTitle)
                    .foregroundColor(.white)
            })
            .frame(width: profileImageSize, height: profileImageSize)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }
    
    @ViewBuilder
    private func profileDetailRow(label: String, value: String?, showTitle: Bool, showIcon: Bool) -> some View {
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
    
    struct ProfileAppearModifier: ViewModifier {
        @ObservedObject var profileVM: ProfileViewModel
        @Binding var currentOffset: CGFloat
        
        func body(content: Content) -> some View {
            content
                .onAppear {
                    Task {
                        await profileVM.loadCurrentUserProfile()
                    }
                    
                    // Move sheet from 100% (hidden) → 90% (show 10%)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentOffset = UIScreen.main.bounds.height * 0.55
                    }
                }
        }
    }
    
    private var blurIntensity: CGFloat {
        // map offset range (bottomLimit → topLimit) to 0 → 1
        let range = bottomLimit - topLimit
        let current = (bottomLimit - (currentOffset + dragTranslation)) / range
        return max(0, min(1, current))  // clamp
    }
}
