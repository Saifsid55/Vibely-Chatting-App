//
//  CarouselViewModel.swift
//  Vibely
//
//  Created by Mohd Saif on 16/11/25.
//

import SwiftUI
import Combine

final class CarouselViewModel: ObservableObject {
    @Published var items: [URL] = []
    @Published var currentIndex: Int = 0
    @Published var phoneNumber: String = ""
    @Published var containerOffset: CGFloat = 0
    @Published var dragTranslation: CGFloat = 0
    
    private var timer: AnyCancellable?
    private let autoScrollInterval: TimeInterval = 2.0
    
    init(urls: [URL]? = nil) {
        if let urls = urls {
            self.items = urls
        } else {
            self.items = [
                URL(string: "https://i.pinimg.com/736x/92/28/c3/9228c3d333560e1d7bf113339e9aa889.jpg")!,
                URL(string: "https://i.pinimg.com/736x/ee/70/f7/ee70f79657d1fc5a4264c50525eccf01.jpg")!,
                URL(string: "https://i.pinimg.com/736x/eb/c6/2c/ebc62c36138427967784e4cab8fdd755.jpg")!,
                URL(string: "https://i.pinimg.com/736x/60/fa/99/60fa999f748f9ce5feaf88a673c4c6e4.jpg")!,
                URL(string: "https://i.pinimg.com/736x/8e/73/e2/8e73e220144f95fc068e22300c94e86c.jpg")!,
                URL(string: "https://i.pinimg.com/736x/69/2b/7c/692b7c8451dd16168de25e77b336940d.jpg")!,
            ]
        }
        currentIndex = items.count / 2
        startAutoScroll()
    }
    
    deinit {
        stopAutoScroll()
    }
    
    // Logic for calculating item scale
    func scaleForItem(itemCenterX: CGFloat, centerX: CGFloat, maxScale: CGFloat) -> CGFloat {
        let distance = abs(itemCenterX - centerX)
        let fadeDistance = UIScreen.main.bounds.width * 0.7
        let closeness = max(0, 1 - (distance / fadeDistance))
        return 1.0 + (maxScale * CGFloat(closeness))
    }
    
    // Logic for calculating shadow radius
    func shadowRadiusForItem(itemCenterX: CGFloat, centerX: CGFloat) -> CGFloat {
        let distance = abs(itemCenterX - centerX)
        let maxDistance = UIScreen.main.bounds.width * 0.5
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 16 - (normalizedDistance * 12)
    }
    
    // Logic for calculating shadow Y offset
    func shadowYForItem(itemCenterX: CGFloat, centerX: CGFloat) -> CGFloat {
        let distance = abs(itemCenterX - centerX)
        let maxDistance = UIScreen.main.bounds.width * 0.5
        let normalizedDistance = min(distance / maxDistance, 1.0)
        return 8 - (normalizedDistance * 6)
    }
    
    // Logic for calculating z-index
    func zIndexForItem(itemCenterX: CGFloat, centerX: CGFloat) -> Double {
        let distance = abs(itemCenterX - centerX)
        return 1000.0 - Double(distance)
    }
    
    // Drag gesture logic
    func handleDragChanged() {
        stopAutoScroll()
    }
    
    //Drag end calculation logic
    func handleDragEnded(predictedTranslation: CGFloat, perItemWidth: CGFloat) {
        let baseOffset = -CGFloat(currentIndex) * perItemWidth
        let predictedOffset = baseOffset + containerOffset + predictedTranslation
        let rawIndex = -predictedOffset / perItemWidth
        let newIndex = Int(round(rawIndex))
        let clamped = max(0, min(items.count - 1, newIndex))
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentIndex = clamped
            containerOffset = 0
        }
        startAutoScroll()
    }
    
    // Drag translation update
    func updateDragTranslation(_ translation: CGFloat) {
        dragTranslation = translation
    }
    
    func setIndex(_ idx: Int) {
        guard !items.isEmpty else { return }
        currentIndex = max(0, min(items.count - 1, idx))
    }
    
    func startAutoScroll() {
        stopAutoScroll()
        timer = Timer.publish(every: autoScrollInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.scrollToNext()
            }
    }
    
    func scrollToNext() {
        guard !items.isEmpty else { return }
        if currentIndex < items.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
    
    func stopAutoScroll() {
        timer?.cancel()
    }
    
    //Keyboard dismissal logic
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
