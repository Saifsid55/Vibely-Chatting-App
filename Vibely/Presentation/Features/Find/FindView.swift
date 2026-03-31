//
//  FindUsersView.swift
//  Vibely
//
//  Created by Mohd Saif on 19/12/25.
//

import SwiftUI

// MARK: - Main Screen

struct FindUsersView: View {

    @StateObject private var vm = FindUsersViewModel()
    @State private var selectedIndex: Int = 2  // Start at index 2 to show items above

    var body: some View {
        if vm.users.indices.contains(selectedIndex) {
            GeometryReader { proxy in
                ZStack {

                    // BACKGROUND IMAGE (full screen)
                    AsyncImage(url: URL(string: vm.users[selectedIndex].imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width,
                                   height: proxy.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } placeholder: {
                        Color.black
                            .ignoresSafeArea()
                    }

                    // DARK GRADIENT (left side for text readability)
                    LinearGradient(
                        colors: [.black.opacity(0.7), .black.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ignoresSafeArea()

                    // CONTENT LAYOUT
                    HStack(spacing: 0) {

                        // LEFT SIDE: User Details
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            
                            UserDetailOverlayView(user: vm.users[selectedIndex])
                                .padding(.leading, 24)
                                .padding(.bottom, 80)
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // RIGHT SIDE: Arc Carousel
                        ArcUserCarouselView(
                            users: vm.users,
                            selectedIndex: $selectedIndex
                        )
                        .frame(width: 100)
                        .padding(.trailing, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Left Side User Details

struct UserDetailOverlayView: View {

    let user: AppUser

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(user.name)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            Text("\(user.age) • \(user.profession)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Right Side Arc Carousel

struct ArcUserCarouselView: View {
    
    let users: [AppUser]
    @Binding var selectedIndex: Int
    
    private let radius: CGFloat = 280
    private let itemSize: CGFloat = 72
    private let visibleRange: Int = 2
    private let angleStep: CGFloat = .pi / 7.5
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visibleIndices, id: \.self) { index in
                    ArcUserItemView(
                        user: users[index],
                        isSelected: index == selectedIndex
                    )
                    .frame(width: itemSize, height: itemSize)
                    .position(position(for: index, in: geo))
                    .zIndex(index == selectedIndex ? 10 : Double(visibleRange - abs(index - selectedIndex)))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(scrollGesture)
        }
    }
    
    // MARK: - Visible Window
    private var visibleIndices: [Int] {
        let lower = max(0, selectedIndex - visibleRange)
        let upper = min(users.count - 1, selectedIndex + visibleRange)
        return Array(lower...upper)
    }
    
    // MARK: - Arc Math (vertical arc on right side)
    private func position(for index: Int, in geo: GeometryProxy) -> CGPoint {
        
        let centerY = geo.size.height / 2
        
        let offset = index - selectedIndex
        let angle = angleStep * CGFloat(offset)
        
        // Calculate x position based on angle
        // Selected item (angle=0): 16pt from right edge
        // Items at ±2 positions: 4pt from right edge
        let angleOffset = (cos(angle) - 1) * radius
        let selectedItemX = geo.size.width - 16 - (itemSize / 2)
        
        let x = selectedItemX - angleOffset
        let y = centerY + sin(angle) * radius
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Scroll Gesture (like a list)
    private var scrollGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation.height
            }
            .onEnded { value in
                isDragging = false
                
                // Simple scroll: every 60pt of drag = 1 item
                let threshold: CGFloat = 60
                let dragDistance = value.translation.height
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if dragDistance < -threshold {
                        // Dragged up - move to next user (down in list)
                        selectedIndex = min(selectedIndex + 1, users.count - 1)
                    } else if dragDistance > threshold {
                        // Dragged down - move to previous user (up in list)
                        selectedIndex = max(selectedIndex - 1, 0)
                    }
                }
                
                dragOffset = 0
            }
    }
}

//MARK: - Arc Item

struct ArcUserItemView: View {
    
    let user: AppUser
    let isSelected: Bool
    
    var body: some View {
        AsyncImage(url: URL(string: user.imageURL)) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: isSelected ? 80 : 64, height: isSelected ? 80 : 64)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 4)
        )
        .shadow(color: .black.opacity(isSelected ? 0.4 : 0.2), radius: isSelected ? 8 : 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
