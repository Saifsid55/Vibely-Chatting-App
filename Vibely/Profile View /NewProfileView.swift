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
import HotSwiftUI


struct NewProfileView: View {
    @EnvironmentObject var vm: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @StateObject private var cvm: CarouselViewModel
    @EnvironmentObject var mediaBarVm: MediaBarViewModel
    
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var router: Router
    
    
    // MARK: - UI State
    @State private var activeEditType: ImageEditType?
    @State private var cropType: ImageEditType?
    @State private var cropItem: CropImageItem?
    
    @State private var showFullCoverImage: Bool = false
    @State private var showFullProfileImage: Bool = false
    @State private var showEditProfileDetails = false
    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false

    @State private var disableDragAnimation = false
    @State private var currentOffset: CGFloat = UIScreen.main.bounds.height
    @GestureState private var dragTranslation: CGFloat = 0
    
    @State private var showEditDialog = false
    @State private var scrollOffset: CGFloat = 0
    
    
    
    private let topLimit: CGFloat = UIScreen.main.bounds.height * 0.1
    private let bottomLimit: CGFloat = UIScreen.main.bounds.height * 0.55
    private let profileImageSize: CGFloat = 100
    
    
    init() {
        let vm = CarouselViewModel()
        _cvm = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
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
            
            if mediaBarVm.showMediaPopup {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        mediaBarVm.closePopup()
                    }
            }
            
            if mediaBarVm.showMediaPopup, let selected = mediaBarVm.selectedMedia {
                MediaEditPopup(
                    vm: mediaBarVm,
                    type: selected,
                    onClose: {
                        mediaBarVm.closePopup()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
            
        }
        .modifier(ProfileChangeHandlers(profileVM: profileVM, disableDragAnimation: $disableDragAnimation))
        .modifier(ProfileAppearModifier(profileVM: profileVM, currentOffset: $currentOffset))
        .modifier(EditDialogModifier(
            showEditDialog: $showEditDialog,
            cropType: $cropType,
            onChangePicture: {
                showEditDialog = false
            },
            showFullCoverImage: $showFullCoverImage,
            showFullProfileImage: $showFullProfileImage
        ))
        .modifier(FullScreenImageViewers(
            showFullCoverImage: $showFullCoverImage,
            showFullProfileImage: $showFullProfileImage,
            profileVM: profileVM
        ))
        .modifier(PhotoPickersModifier(
            isPresented: $showPhotoPicker, selectedItem: $selectedPickerItem
        ))
        .modifier(CropHandlers(
            cropType: $cropType,
            cropItem: $cropItem,
            onUpload: { data, type in
                Task {
                    let imageType: ProfileImageType =
                        (type == .cover) ? .cover : .profile

                    await profileVM.uploadImage(
                        data: data,
                        type: imageType
                    )
                }
            }
        ))
        
        .fullScreenCover(isPresented: $showEditProfileDetails) {
            EditProfileDetailsView(profileVM: profileVM)
                .environmentObject(profileVM)
        }
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                if tabRouter.selectedTab == .profile && tabRouter.allowCollapse {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        tabRouter.isTabBarCollapsed = true
                    }
                }
            }
        }
        .onDisappear {
            tabRouter.allowCollapse = true
        }
        .enableInjection()
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
        VStack(alignment: .leading, spacing: 16) {
            topProfileView
                .padding(.top, 16)
            HobbiesRow(hobbies: ["Gym", "Travel", "Cooking", "Music"])
                .padding(.leading, 24)
            blurredListView
                .background(Color.clear)
            
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .scaleEffect(dragTranslation == 0 ? 1.0 : 1 - (abs(dragTranslation) / 2000))
        .shadow(radius: 10 + abs(dragTranslation) / 20)
        .offset(y: max(topLimit, min(bottomLimit, currentOffset + dragTranslation)))
        .animation(
            disableDragAnimation ? nil :
                (dragTranslation == 0 ? .interactiveSpring(response: 0.4, dampingFraction: 0.85) : nil),
            value: currentOffset
        )
        /*
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
         */
        
        
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($dragTranslation) { value, state, _ in
                    let translation = value.translation.height
                    let isAtTop = scrollOffset >= -1 // Small threshold for floating point
                    let isDraggingUp = translation < 0
                    let isDraggingDown = translation > 0
                    
                    // CHANGED: Allow sheet drag in two cases:
                    // Case 1: User is at the top of scroll AND dragging upward (collapse sheet)
                    // Case 2: User is dragging downward (expand sheet) - works anywhere
                    let shouldDrag = (isAtTop && isDraggingUp) || isDraggingDown
                    
                    if shouldDrag {
                        let newOffset = currentOffset + translation
                        var adjusted = translation
                        
                        // Apply resistance at limits
                        if newOffset < topLimit || newOffset > bottomLimit {
                            adjusted *= 0.4
                        }
                        
                        state = adjusted
                    }
                }
                .onEnded { value in
                    let translation = value.translation.height
                    let isAtTop = scrollOffset >= -1
                    let isDraggingUp = translation < 0
                    let isDraggingDown = translation > 0
                    
                    // CHANGED: Snap sheet position for both directions
                    let shouldSnap = (isAtTop && isDraggingUp) || isDraggingDown
                    
                    if shouldSnap {
                        let newOffset = currentOffset + translation
                        let mid = (bottomLimit + topLimit) / 2
                        currentOffset = newOffset < mid ? topLimit : bottomLimit
                    }
                }
        )
        
    }
    
    private var topProfileView: some View {
        
        HStack(alignment: .top, spacing: 8) {
            profileImageView
                .frame(width: profileImageSize, height: profileImageSize)
                .onTapGesture {
                    cropType = .profile
                    showEditDialog = true
                }
                .padding(.leading, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                profileDetailRow(label: "Name", value: profileVM.profile?.displayName, showTitle: false, showIcon: false, valueFontSize: 20, valueFontWeight: .bold)
                
                
                profileDetailRow(label: "Bio", value: profileVM.profile?.bio, showTitle: false, showIcon: false, valueFontSize: 14, valueFontWeight: .semibold)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }
        
    }
    
    private var blurredListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                
                Text(profileVM.profile?.usernameLowercase ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.leading, 24)
                MediaBar()
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
            .overlay {
                TrackScrollOffset()
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .coordinateSpace(name: "SCROLL_AREA")
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            scrollOffset = value
        }
    }
    
    private var topScrollAnchor: some View {
        Color.clear
            .frame(height: 0.1)
            .id("TOP")
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
    
    struct TrackScrollOffset: View {
        var body: some View {
            GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("SCROLL_AREA")).minY)
            }
        }
    }
    
    @ViewBuilder
    private func profileDetailRow(
        label: String,
        value: String?,
        showTitle: Bool,
        showIcon: Bool,
        labelFontSize: CGFloat = 14,
        labelFontWeight: Font.Weight = .semibold,
        valueFontSize: CGFloat = 15,
        valueFontWeight: Font.Weight = .regular
    ) -> some View {
        
        if let trimmed = value?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty {
            HStack(spacing: 4) {
                
                if showTitle {
                    Text("\(label):")
                        .font(.system(size: labelFontSize, weight: labelFontWeight))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.trailing, 6)
                }
                
                Text(trimmed)
                    .font(.system(size: valueFontSize, weight: valueFontWeight))
                    .foregroundStyle(.white)
                //                    .lineLimit(0)
                    .minimumScaleFactor(0.8)
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
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        await profileVM.loadProfile(userId: uid)
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
