//
//  BottomSheetPresentationController.swift
//  BottomSheet
//
//  Created by Mikhail Maslo on 14.11.2021.
//  Copyright © 2021 Joom. All rights reserved.
//

import UIKit
import Combine

public protocol ScrollableBottomSheetPresentedController: AnyObject {
    var scrollView: UIScrollView? { get }
}

public final class BottomSheetPresentationController: UIPresentationController {
    // MARK: - Nested

    private enum State {
        case dismissed
        case presenting
        case presented
        case dismissing
    }

    private struct Style {
        static let cornerRadius: CGFloat = 10
        static let pullBarHeight = Style.cornerRadius * 2
    }

    // MARK: - Public properties

    static var pullBarHeight: CGFloat {
        Style.pullBarHeight
    }

    var interactiveTransition: UIViewControllerInteractiveTransitioning? {
        interactionController
    }

    // MARK: - Private properties

    private var state: State = .dismissed

    private var isInteractiveTransitionCanBeHandled: Bool {
        isDragging && !isNavigationTransitionInProgress
    }

    private var isDragging = false {
        didSet {
            if isDragging {
                assert(interactionController == nil)
            }
        }
    }

    private var isNavigationTransitionInProgress = false {
        didSet {
            assert(interactionController == nil)
        }
    }

    private var overlayTranslation: CGFloat = 0
    private var scrollViewTranslation: CGFloat = 0
    private var lastContentOffsetWhileScrolling: CGPoint = .zero
    private var lastContentOffsetBeforeDragging: CGPoint = .zero
    private var didStartDragging = false
    private var dismissalWasAborted = false

    private var interactionController: UIPercentDrivenInteractiveTransition?

    public var shadingView: UIView?
    public var pullBar: PullBar?

    private weak var trackedScrollView: UIScrollView?

    private var cachedInsets: UIEdgeInsets = .zero

    private let dismissalHandler: BottomSheetModalDismissalHandler

    // MARK: - Init

    public init(
        presentedViewController: UIViewController,
        presentingViewController: UIViewController?,
        dismissalHandler: BottomSheetModalDismissalHandler
    ) {
        self.dismissalHandler = dismissalHandler
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    // MARK: - Setup

    private func setupGesturesForPresentedView() {
        setupPanGesture(for: presentedView)
        setupPanGesture(for: pullBar)
    }

    private func setupPanGesture(for view: UIView?) {
        guard let view = view else {
            return
        }

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panRecognizer)
        panRecognizer.delegate = self
    }

    private func setupScrollTrackingIfNeeded() {
        if let navigationController = presentedViewController as? UINavigationController {
            navigationController.delegate = self

            if let topViewController = navigationController.topViewController {
                trackScrollView(inside: topViewController)
            }
        } else {
            trackScrollView(inside: presentedViewController)
        }
    }

    private func removeScrollTrackingIfNeeded() {
        trackedScrollView?.delegate = nil
        trackedScrollView = nil
    }

    // MARK: - UIPresentationController

    public override func presentationTransitionWillBegin() {
        state = .presenting

        addSubviews()
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            setupGesturesForPresentedView()
            setupScrollTrackingIfNeeded()

            state = .presented
        } else {
            state = .dismissed
        }
    }

    public override func dismissalTransitionWillBegin() {
        state = .dismissing
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            removeSubviews()
            removeScrollTrackingIfNeeded()

            state = .dismissed
        } else {
            state = .presented
        }
    }

    public override var shouldPresentInFullscreen: Bool {
        false
    }

    public override var frameOfPresentedViewInContainerView: CGRect {
        targetFrameForPresentedView()
    }

    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        updatePresentedViewSize()
    }

    public override func containerViewDidLayoutSubviews() {
        cachedInsets = presentedView?.window?.safeAreaInsets ?? .zero

        updatePresentedViewSize()
    }

    // MARK: - Interactive Dismissal

    @objc
    private func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began:
            processPanGestureBegan(panGesture)
        case .changed:
            processPanGestureChanged(panGesture)
        case .ended:
            processPanGestureEnded(panGesture)
        case .cancelled:
            processPanGestureCancelled(panGesture)
        default:
            break
        }
    }

    private func processPanGestureBegan(_ panGesture: UIPanGestureRecognizer) {
        startInteractiveTransition()
    }

    private func startInteractiveTransition() {
        interactionController = UIPercentDrivenInteractiveTransition()

        presentingViewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            if self.presentingViewController.presentedViewController !== self.presentedViewController {
                self.dismissalHandler.performDismissal(animated: true)
            }
        }
    }

    private func processPanGestureChanged(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: nil)
        updateInteractionControllerProgress(verticalTranslation: translation.y)
    }

    private func updateInteractionControllerProgress(verticalTranslation: CGFloat) {
        guard let presentedView = presentedView else {
            return
        }

        let progress = verticalTranslation / presentedView.bounds.height
        interactionController?.update(progress)
    }

    private func processPanGestureEnded(_ panGesture: UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: presentedView)
        let translation = panGesture.translation(in: presentedView)
        endInteractiveTransition(verticalVelocity: velocity.y, verticalTranslation: translation.y)
    }

    private func endInteractiveTransition(verticalVelocity: CGFloat, verticalTranslation: CGFloat) {
        guard let presentedView = presentedView else {
            return
        }

        let deceleration = 800.0 * (verticalVelocity > 0 ? -1.0 : 1.0)
        let finalProgress = (verticalTranslation - 0.5 * verticalVelocity * verticalVelocity / CGFloat(deceleration))
            / presentedView.bounds.height
        let isThresholdPassed = finalProgress < 0.5

        endInteractiveTransition(isCancelled: isThresholdPassed)
    }

    private func processPanGestureCancelled(_ panGesture: UIPanGestureRecognizer) {
        endInteractiveTransition(isCancelled: true)
    }

    private func endInteractiveTransition(isCancelled: Bool) {
        if isCancelled {
            interactionController?.cancel()
        } else if !dismissalHandler.canBeDismissed {
            interactionController?.cancel()
            dismissalWasAborted = true
        } else {
            interactionController?.finish()
        }
        interactionController = nil
    }

    // MARK: - Private

    private func applyStyle() {
        guard presentedViewController.isViewLoaded else {
            assertionFailure()
            return
        }

        presentedViewController.view.clipsToBounds = true

        pullBar?.layer.mask = nil
        presentedViewController.view.layer.cornerRadius = Style.cornerRadius
    }

    private func addSubviews() {
        guard let containerView = containerView else {
            assertionFailure()
            return
        }

        let shadingView = UIView()
        shadingView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        containerView.addSubview(shadingView)
        shadingView.frame = containerView.bounds

        let pullBar = PullBar()
        pullBar.frame.size = CGSize(width: containerView.frame.width, height: Style.pullBarHeight)
        containerView.addSubview(pullBar)

        let tapGesture = UITapGestureRecognizer()
        shadingView.addGestureRecognizer(tapGesture)

        tapGesture.addTarget(self, action: #selector(handleShadingViewTapGesture))

        self.shadingView = shadingView
        self.pullBar = pullBar
    }
    
    @objc
    private func handleShadingViewTapGesture() {
        dismissIfPossible()
    }

    private func removeSubviews() {
        shadingView?.removeFromSuperview()
        shadingView = nil
        pullBar?.removeFromSuperview()
        pullBar = nil
    }

    private func targetFrameForPresentedView() -> CGRect {
        guard let containerView = containerView else {
            return .zero
        }

        let windowInsets = presentedView?.window?.safeAreaInsets ?? cachedInsets

        let preferredHeight = presentedViewController.preferredContentSize.height + windowInsets.bottom
        let maxHeight = containerView.bounds.height - windowInsets.top - Style.pullBarHeight
        let height = min(preferredHeight, maxHeight)

        return .init(
            x: 0,
            y: (containerView.bounds.height - height).pixelCeiled,
            width: containerView.bounds.width,
            height: height.pixelCeiled
        )
    }

    private func updatePresentedViewSize() {
        guard let presentedView = presentedView else {
            return
        }

        let oldFrame = presentedView.frame
        let targetFrame = targetFrameForPresentedView()
        if !oldFrame.isAlmostEqual(to: targetFrame) {
            presentedView.frame = targetFrame
            pullBar?.frame.origin.y = presentedView.frame.minY - Style.pullBarHeight + pixelSize
        }
    }

    @discardableResult
    private func dismissIfPossible() -> Bool {
        let canBeDismissed = state == .presented && dismissalHandler.canBeDismissed

        if canBeDismissed {
            dismissalHandler.performDismissal(animated: true)
        }

        return canBeDismissed
    }
}

extension BottomSheetPresentationController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // We don't want bounces inside bottom sheet
        if
            !scrollView.isContentOriginInBounds,
            scrollView.frame.height - scrollView.adjustedContentInset.top - scrollView.adjustedContentInset.bottom >= scrollView.contentSize.height
        {
            scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
            return
        }

        let previousTranslation = scrollViewTranslation
        scrollViewTranslation = scrollView.panGestureRecognizer.translation(in: scrollView).y

        if lastContentOffsetWhileScrolling.y.isAlmostEqual(to: 0) {
            lastContentOffsetWhileScrolling = scrollView.contentOffset
        }

        didStartDragging = shouldDragOverlay(following: scrollView)
        if didStartDragging {
            startInteractiveTransitionIfNeeded()
            let offset = adjustedContentOffset(dragging: scrollView)
            overlayTranslation += scrollViewTranslation - previousTranslation

            // Update scrollView contentInset without invoking scrollViewDidScroll(_:)
            var bounds = scrollView.bounds
            bounds.origin = offset
            scrollView.bounds = bounds

            updateInteractionControllerProgress(verticalTranslation: overlayTranslation)
            lastContentOffsetWhileScrolling = offset
        } else {
            lastContentOffsetBeforeDragging = scrollView.panGestureRecognizer.translation(in: scrollView)
            lastContentOffsetWhileScrolling = scrollView.contentOffset
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragging = true
    }

    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if didStartDragging {
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
            let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
            endInteractiveTransition(
                verticalVelocity: velocity.y,
                verticalTranslation: translation.y - lastContentOffsetBeforeDragging.y
            )
        } else {
            endInteractiveTransition(isCancelled: true)
        }

        overlayTranslation = 0
        scrollViewTranslation = 0
        lastContentOffsetWhileScrolling = .zero
        lastContentOffsetBeforeDragging = .zero
        didStartDragging = false
        isDragging = false
    }
    
    private func startInteractiveTransitionIfNeeded() {
        guard interactionController == nil else {
            return
        }

        startInteractiveTransition()
    }

    private func shouldDragOverlay(following scrollView: UIScrollView) -> Bool {
        guard scrollView.isTracking, isInteractiveTransitionCanBeHandled else {
            return false
        }

        let velocity = scrollView.panGestureRecognizer.velocity(in: nil).y
        let movesUp = velocity < 0
        if let percentComplete = interactionController?.percentComplete {
            // Swipe down
            if percentComplete.isAlmostEqual(to: 0) {
                return scrollView.isContentOriginInBounds && !movesUp
            }

            return scrollView.isContentOriginInBounds || scrollView.scrollsUp
        } else {
            return scrollView.isContentOriginInBounds && !movesUp
        }
    }

    private func adjustedContentOffset(dragging scrollView: UIScrollView) -> CGPoint {
        var contentOffset = lastContentOffsetWhileScrolling
        let topInset = -scrollView.adjustedContentInset.top

        if contentOffset.y < topInset {
            contentOffset.y = topInset
        }

        return contentOffset
    }
}

extension BottomSheetPresentationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }

        let translation = panGesture.translation(in: presentedView)
        return state == .presented && translation.y > 0
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer === trackedScrollView?.panGestureRecognizer {
            return true
        }

        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !isNavigationTransitionInProgress
    }
}

extension BottomSheetPresentationController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        trackScrollView(inside: viewController)

        isNavigationTransitionInProgress = false
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        isNavigationTransitionInProgress = true
    }

    private func trackScrollView(inside viewController: UIViewController) {
        guard
            let scrollableViewController = viewController as? ScrollableBottomSheetPresentedController,
            let scrollView = scrollableViewController.scrollView
        else {
            return
        }
        
        trackedScrollView?.delegate = nil
        scrollView.delegate = self
        self.trackedScrollView = scrollView
    }
}

extension BottomSheetPresentationController: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let sourceViewController = transitionContext.viewController(forKey: .from),
            let destinationViewController = transitionContext.viewController(forKey: .to),
            let sourceView = sourceViewController.view,
            let destinationView = destinationViewController.view
        else {
            return
        }

        let isPresenting = destinationViewController.isBeingPresented
        let presentedView = isPresenting ? destinationView : sourceView
        let containerView = transitionContext.containerView
        if isPresenting {
            containerView.addSubview(destinationView)

            destinationView.frame = containerView.bounds
        }

        sourceView.layoutIfNeeded()
        destinationView.layoutIfNeeded()

        let frameInContainer = frameOfPresentedViewInContainerView
        let offscreenFrame = CGRect(
            origin: CGPoint(
                x: 0,
                y: containerView.bounds.height
            ),
            size: sourceView.frame.size
        )

        presentedView.frame = isPresenting ? offscreenFrame : frameInContainer
        pullBar?.frame.origin.y = presentedView.frame.minY - Style.pullBarHeight + pixelSize
        shadingView?.alpha = isPresenting ? 0 : 1

        applyStyle()

        let animations = {
            presentedView.frame = isPresenting ? frameInContainer : offscreenFrame
            self.pullBar?.frame.origin.y = presentedView.frame.minY - Style.pullBarHeight + pixelSize
            self.shadingView?.alpha = isPresenting ? 1 : 0
        }

        let completion = { (completed: Bool) in
            transitionContext.completeTransition(completed && !transitionContext.transitionWasCancelled)
        }

        let options: UIView.AnimationOptions = transitionContext.isInteractive ? .curveLinear : .curveEaseInOut
        let transitionDurationValue = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: transitionDurationValue, delay: 0, options: options, animations: animations, completion: completion)
    }

    public func animationEnded(_ transitionCompleted: Bool) {
    }
}

private extension UIScrollView {
    var scrollsUp: Bool {
        panGestureRecognizer.velocity(in: nil).y < 0
    }

    var isContentOriginInBounds: Bool {
        contentOffset.y <= -adjustedContentInset.top
    }
}
