import SwiftUI
import UIKit

public struct ScrollViewWrapper<Content: View>: UIViewRepresentable {
    @Binding var contentOffset: CGPoint
    @Binding var scrollViewHeight: CGFloat
    @Binding var visibleHeight: CGFloat
    
    let content: () -> Content
    
    public init(
        contentOffset: Binding<CGPoint>,
        scrollViewHeight: Binding<CGFloat>,
        visibleHeight: Binding<CGFloat>,
        @ViewBuilder _ content: @escaping () -> Content
    ) {
        self._contentOffset = contentOffset
        self._scrollViewHeight = scrollViewHeight
        self._visibleHeight = visibleHeight
        self.content = content
    }
    
    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        
        // Hosting controller for SwiftUI content
        let host = UIHostingController(rootView: content())
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        
        scrollView.addSubview(host.view)
        
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Store controller reference in coordinator
        context.coordinator.hostingController = host
        
        return scrollView
    }
    
    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update SwiftUI content inside the hosting controller
        context.coordinator.hostingController?.rootView = content()
        
        // Ensure proper layout calculation
        DispatchQueue.main.async {
            uiView.layoutIfNeeded()
            self.scrollViewHeight = uiView.contentSize.height
            self.visibleHeight = uiView.frame.size.height
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(contentOffset: $contentOffset)
    }
    
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>? = nil
        let contentOffset: Binding<CGPoint>
        
        init(contentOffset: Binding<CGPoint>) {
            self.contentOffset = contentOffset
        }
        
        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.contentOffset.wrappedValue = scrollView.contentOffset
            }
        }
    }
}
