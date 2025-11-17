//
//  CarousalView.swift
//  Vibely
//
//  Created by Mohd Saif on 16/11/25.
//

import SwiftUI

struct CarouselView: View {
    @ObservedObject var vm: CarouselViewModel
    
    // layout configs
    var itemSpacing: CGFloat = 16
    var maxVisibleScale: CGFloat = 0.14
    var defaultHeight: CGFloat = 250
    
    var body: some View {
        GeometryReader { geo in
            let fullWidth = geo.size.width
            let availableHeight = min(defaultHeight, geo.size.height)
            let itemSide = min(availableHeight, fullWidth * 0.72)
            let centerX = fullWidth / 2
            let perItemWidth = itemSide + itemSpacing
            
            let baseOffset = -CGFloat(vm.currentIndex) * perItemWidth
            let totalOffset = baseOffset + vm.containerOffset + vm.dragTranslation
            
            ZStack {
                ForEach(vm.items.indices, id: \.self) { idx in
                    let itemX = centerX + CGFloat(idx) * perItemWidth + totalOffset
                    
                    CarouselItemView(imageURL: vm.items[idx])
                        .frame(width: itemSide, height: itemSide)
                        .cornerRadius(14)
                        .shadow(radius: vm.shadowRadiusForItem(itemCenterX: itemX, centerX: centerX),
                                y: vm.shadowYForItem(itemCenterX: itemX, centerX: centerX))
                        .position(x: itemX, y: geo.size.height / 2)
                        .scaleEffect(vm.scaleForItem(itemCenterX: itemX, centerX: centerX, maxScale: maxVisibleScale))
                        .zIndex(vm.zIndexForItem(itemCenterX: itemX, centerX: centerX))
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85), value: vm.dragTranslation)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: vm.currentIndex)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        vm.updateDragTranslation(value.translation.width)
                        vm.handleDragChanged()
                    }
                    .onEnded { value in
                        vm.handleDragEnded(
                            predictedTranslation: value.predictedEndTranslation.width,
                            perItemWidth: perItemWidth
                        )
                        // Reset drag translation
                        vm.updateDragTranslation(0)
                    }
            )
            .frame(height: geo.size.height)
        }
        .frame(minHeight: 120, idealHeight: defaultHeight, maxHeight: .infinity)
    }
}


// MARK: - Individual Item View
struct CarouselItemView: View {
    let imageURL: URL?
    
    init(imageURL: URL? = nil) {
        self.imageURL = imageURL
    }
    
    var body: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.gray.opacity(0.25))
                        ProgressView()
                    }
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                        .clipped()
                case .failure(_):
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.gray.opacity(0.25))
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(.gray.opacity(0.25))
        }
    }
}

// MARK: - Page Control (dots)
struct PageControl: View {
    let pages: Int
    @Binding var currentIndex: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages, id: \.self) { i in
                Circle()
                    .foregroundStyle(.gray)
                    .frame(width: i == currentIndex ? 10 : 7, height: i == currentIndex ? 10 : 7)
                    .opacity(i == currentIndex ? 1 : 0.45)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }
}
