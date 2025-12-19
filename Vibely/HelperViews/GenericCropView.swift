//
//  GenericCropView.swift
//  Vibely
//
//  Created by Mohd Saif on 15/11/25.
//  Updated: 2025-11-15
//

import SwiftUI
import UIKit

enum CropAspect {
    case portraitScreen      // uses available height/width ratio
    case square
    case free
    case custom(CGFloat)     // e.g., 16/9 as 16.0/9.0
}

struct GenericCropView: View {
    let originalImage: UIImage
    let aspect: CropAspect
    let onCrop: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    // accumulated user state
    @State private var scale: CGFloat = 1.0
    @GestureState private var gestureScale: CGFloat = 1.0

    @State private var offset: CGSize = .zero
    @GestureState private var gestureOffset: CGSize = .zero

    @State private var isInteracting: Bool = false

    // zoom limits (relative multipliers applied to base-fit scale)
    private let minZoomMultiplier: CGFloat = 1.0
    private let maxZoomMultiplier: CGFloat = 6.0

    // MARK: - Aspect Ratio Calculator
    private func cropRatio(for size: CGSize) -> CGFloat? {
        switch aspect {
        case .portraitScreen:
            guard size.width > 0 else { return nil }
            return size.height / size.width
        case .square:
            return 1.0
        case .custom(let r):
            return r
        case .free:
            return nil
        }
    }

    var body: some View {
        GeometryReader { geo in
            let containerSize = geo.size
            let width = containerSize.width
            let height = containerSize.height

            Group {
                if width <= 0 || height <= 0 {
                    // defensive fallback while layout stabilizes
                    Color.black.ignoresSafeArea()
                } else {
                    // compute crop aspect
                    let rawRatio = cropRatio(for: containerSize)
                    let ratio: CGFloat = {
                        if let r = rawRatio, r.isFinite, r > 0 { return r }
                        return height / width
                    }()

                    let cropWidth = width
                    let cropHeight = cropWidth * ratio

                    ZStack {
                        // fullscreen black background
                        Color.black.ignoresSafeArea()

                        // center crop area vertically
                        VStack(spacing: 0) {
                            Spacer(minLength: max((containerSize.height - cropHeight) / 2, 0))

                            // Crop zone
                            ZStack {
                                // inside-crop black (ensures exported image has black letterbox)
                                Color.black

                                // Image + gestures placed inside a GeometryReader sized to crop rect
                                GeometryReader { cropGeo in
                                    let cropRectSize = cropGeo.size

                                    // base scale so image fits inside crop rect (preserve aspect)
                                    let baseScaleToFit = min(
                                        cropRectSize.width / originalImage.size.width,
                                        cropRectSize.height / originalImage.size.height
                                    )

                                    // effective scale = base * user multiplier (clamped)
                                    let effectiveScale = baseScaleToFit * clampScale(scale * gestureScale)

                                    // displayed image size
                                    let displayedImageSize = CGSize(
                                        width: originalImage.size.width * effectiveScale,
                                        height: originalImage.size.height * effectiveScale
                                    )

                                    // center of crop rect
                                    let center = CGPoint(x: cropRectSize.width / 2, y: cropRectSize.height / 2)

                                    // total offset (accumulated + current gesture)
                                    let totalOffset = CGSize(
                                        width: offset.width + gestureOffset.width,
                                        height: offset.height + gestureOffset.height
                                    )

                                    // compute origin where image should be drawn when centered + offset
                                    let imageOrigin = CGPoint(
                                        x: center.x - (displayedImageSize.width / 2) + totalOffset.width,
                                        y: center.y - (displayedImageSize.height / 2) + totalOffset.height
                                    )

                                    // SwiftUI image (resizable) positioned precisely
                                    Image(uiImage: originalImage)
                                        .resizable()
                                        .frame(width: displayedImageSize.width, height: displayedImageSize.height)
                                        .position(x: imageOrigin.x + displayedImageSize.width / 2,
                                                  y: imageOrigin.y + displayedImageSize.height / 2)
                                        .gesture(interactionGesture())
                                        .onChange(of: gestureScale) { _,_ in interactionStarted() }
                                        .onChange(of: gestureOffset) { _, _ in interactionStarted() }
                                        .clipped()
                                } // GeometryReader for crop rect

                                // visible crop border
                                Rectangle()
                                    .stroke(Color.white.opacity(0.95), lineWidth: 2)

                                // grid overlay shown only while interacting
                                if isInteracting {
                                    CropGridView()
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.12), value: isInteracting)
                                }
                            }
                            .frame(width: cropWidth, height: cropHeight)
                            .clipped()

                            Spacer(minLength: max((containerSize.height - cropHeight) / 2, 0))
                        }
                        .ignoresSafeArea(edges: .vertical)

                        // Top & bottom controls
                        VStack {
                            HStack {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                Spacer()
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                            Spacer()

                            HStack {
                                Button("Cancel") { dismiss() }
                                    .foregroundStyle(.white)
                                    .background(Color.black.opacity(0.6))
                                    .font(.system(size: 17, weight: .regular))

                                Spacer()

                                Button("Done") {
                                    let final = cropFinalImage(
                                        cropSize: CGSize(width: cropWidth, height: cropHeight)
                                    )
                                    onCrop(final)
                                }
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.6))
                                .font(.system(size: 17, weight: .semibold))
                            }
                            .padding(.horizontal, 22)
                            .padding(.bottom, 32)
                        }
                        .zIndex(10)
                    } // ZStack
                } // else
            } // Group
        } // GeometryReader
    }

    // MARK: - Combined gesture
    private func interactionGesture() -> some Gesture {
        let magnify = MagnificationGesture()
            .updating($gestureScale) { value, state, _ in state = value }
            .onChanged { _ in interactionStarted() }
            .onEnded { value in
                let new = scale * value
                scale = clampScale(new)
                // small delay keep grid visible for smoother UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    interactionEnded()
                }
            }

        let drag = DragGesture()
            .updating($gestureOffset) { value, state, _ in state = value.translation }
            .onChanged { _ in interactionStarted() }
            .onEnded { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
                // clamp offset lightly (final clamp done during render)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    interactionEnded()
                }
            }

        return SimultaneousGesture(magnify, drag)
    }

    private func interactionStarted() {
        if !isInteracting { isInteracting = true }
    }
    private func interactionEnded() {
        withAnimation(.easeOut(duration: 0.12)) {
            isInteracting = false
        }
    }

    private func clampScale(_ value: CGFloat) -> CGFloat {
        return min(max(value, minZoomMultiplier), maxZoomMultiplier)
    }

    // MARK: - Final renderer (exports cropSize with black bars included)
    private func cropFinalImage(cropSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: cropSize, format: format)

        return renderer.image { ctx in
            // draw black background (letterbox)
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: cropSize))

            // compute base scale to fit original image inside crop
            let baseScaleToFit = min(
                cropSize.width / originalImage.size.width,
                cropSize.height / originalImage.size.height
            )

            let effectiveScale = baseScaleToFit * clampScale(scale)

            let displayedSize = CGSize(
                width: originalImage.size.width * effectiveScale,
                height: originalImage.size.height * effectiveScale
            )

            let center = CGPoint(x: cropSize.width / 2, y: cropSize.height / 2)
            let totalOffset = CGSize(width: offset.width, height: offset.height)

            var origin = CGPoint(
                x: center.x - displayedSize.width / 2 + totalOffset.width,
                y: center.y - displayedSize.height / 2 + totalOffset.height
            )

            // clamp so user cannot pan image completely away from crop
            if displayedSize.width <= cropSize.width {
                origin.x = (cropSize.width - displayedSize.width) / 2
            } else {
                let minX = cropSize.width - displayedSize.width
                let maxX: CGFloat = 0
                origin.x = min(max(origin.x, minX), maxX)
            }

            if displayedSize.height <= cropSize.height {
                origin.y = (cropSize.height - displayedSize.height) / 2
            } else {
                let minY = cropSize.height - displayedSize.height
                let maxY: CGFloat = 0
                origin.y = min(max(origin.y, minY), maxY)
            }

            let drawRect = CGRect(origin: origin, size: displayedSize)
            originalImage.draw(in: drawRect)
        }
    }
}

// MARK: - 3x3 Grid overlay + corner accents
fileprivate struct CropGridView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // grid lines
                Path { p in
                    // vertical
                    p.move(to: CGPoint(x: w / 3, y: 0)); p.addLine(to: CGPoint(x: w / 3, y: h))
                    p.move(to: CGPoint(x: (w / 3) * 2, y: 0)); p.addLine(to: CGPoint(x: (w / 3) * 2, y: h))
                    // horizontal
                    p.move(to: CGPoint(x: 0, y: h / 3)); p.addLine(to: CGPoint(x: w, y: h / 3))
                    p.move(to: CGPoint(x: 0, y: (h / 3) * 2)); p.addLine(to: CGPoint(x: w, y: (h / 3) * 2))
                }
                .stroke(Color.white.opacity(0.75), lineWidth: 1)

                // four corner accents (individual shapes stroked)
                CornerShape(position: .topLeft).stroke(Color.white.opacity(0.95), lineWidth: 2)
                CornerShape(position: .topRight).stroke(Color.white.opacity(0.95), lineWidth: 2)
                CornerShape(position: .bottomLeft).stroke(Color.white.opacity(0.95), lineWidth: 2)
                CornerShape(position: .bottomRight).stroke(Color.white.opacity(0.95), lineWidth: 2)
            }
            .compositingGroup()
        }
    }

    // corner positions
    fileprivate enum CornerPosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    // corner shape draws small L-shaped accent at chosen corner
    fileprivate struct CornerShape: Shape {
        let position: CornerPosition

        func path(in rect: CGRect) -> Path {
            var p = Path()
            let len = min(rect.width, rect.height) * 0.06

            switch position {
            case .topLeft:
                p.move(to: CGPoint(x: rect.minX + len, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + len))
            case .topRight:
                p.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))
            case .bottomLeft:
                p.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))
            case .bottomRight:
                p.move(to: CGPoint(x: rect.maxX - len, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
            }
            return p
        }
    }
}

//#if DEBUG
//struct GenericCropView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            GenericCropView(
//                originalImage: UIImage(systemName: "person.fill")!,
//                aspect: .portraitScreen
//            ) { _ in }
//
//            GenericCropView(
//                originalImage: UIImage(systemName: "photo")!,
//                aspect: .square
//            ) { _ in }
//        }
//        .previewDevice("iPhone 14")
//    }
//}
//#endif

