//
//  CurtainBaseVC.swift
//  SwiftBottomShitTestProj
//
//  Created by Ilya Kovalenko on 12.10.2023.
//

import BottomSheet
import UIKit

enum HeaderState {
    case leftMultyline
    case centeredSignleWithNavbar
}

class CurtainBaseVC: UIViewController {
    private let _scrollView = UIScrollView()

    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let bottomContentOffset: CGFloat = 8

    private var contentHeight: CGFloat {
        headerContainer.bounds.height
            + _scrollView.contentSize.height
            + getBottomContainer().bounds.height
            + bottomContentOffset
            + view.safeAreaInsets.bottom
    }

    var hasBackButton: Bool {
        navigationController?.viewControllers.count ?? 0 > 1
    }

    var headerState: HeaderState { .centeredSignleWithNavbar }

    override var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.sizeToFit()
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContainers()
        setupHeader()
        setupContentUI()
        updatePreferredContentSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
    }

    private func setupContainers() {
        view.backgroundColor = .white

        _scrollView.alwaysBounceVertical = true
        view.addSubview(headerContainer)
        view.addSubview(_scrollView)
        let bottomContainer = getBottomContainer()
        let scrollContentView = getScrollContentView()
        view.addSubview(bottomContainer)

        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        _scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomContainer.snp.top).offset(-8)
        }

        _scrollView.contentLayoutGuide.snp.makeConstraints { make in
            make.width.equalTo(_scrollView.frameLayoutGuide)
        }

        bottomContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        _scrollView.addSubview(scrollContentView)

        scrollContentView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(_scrollView.contentLayoutGuide)
            make.bottom.equalTo(_scrollView.contentLayoutGuide)
            make.top.equalTo(_scrollView.contentLayoutGuide)
        }
    }

    func getScrollContentView() -> UIView {
        return UIView()
    }

    func getBottomContainer() -> UIView {
        return UIView()
    }

    /// Метод предназначен для конфигурации UI основных элементов внутри экрана
    func setupContentUI() {}

    /// В методе происходит рассчет размера шторки
    func updatePreferredContentSize() {
        view.layoutIfNeeded()
        preferredContentSize = .init(
            width: _scrollView.contentSize.width,
            height: contentHeight
        )
    }

    private func setupHeader() {
        headerContainer.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        headerContainer.setContentHuggingPriority(.defaultHigh, for: .vertical)
        headerContainer.snp.makeConstraints { make in
            make.height.equalTo(0).priority(.low)
        }

        let rightButton = UIButton(type: .system)
        rightButton.backgroundColor = .lightGray.withAlphaComponent(0.1)
        rightButton.layer.cornerRadius = 15
        rightButton.setTitle("X", for: .normal)
        rightButton.addTarget(self, action: #selector(dismissButtonTap), for: .touchUpInside)

        switch headerState {
        case .centeredSignleWithNavbar:
            if #available(iOS 13.0, *) {
                let standardAppearance = UINavigationBarAppearance()
                standardAppearance.configureWithTransparentBackground()
                navigationController?.navigationBar.standardAppearance = standardAppearance
                navigationController?.navigationBar.scrollEdgeAppearance = standardAppearance
                navigationController?.navigationBar.compactAppearance = standardAppearance
            }
            titleLabel.textAlignment = .center
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            titleLabel.sizeToFit()
            navigationItem.titleView = titleLabel
            let rightBarItem = UIBarButtonItem(customView: rightButton)
            navigationItem.setRightBarButton(rightBarItem, animated: true)

        case .leftMultyline:
            navigationController?.setNavigationBarHidden(true, animated: false)
            titleLabel.numberOfLines = 0
            titleLabel.textAlignment = .left
            titleLabel.font = .systemFont(ofSize: 21, weight: .semibold)
            titleLabel.sizeToFit()
            headerContainer.addSubview(titleLabel)
            headerContainer.addSubview(rightButton)
            titleLabel.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(16)
                make.top.equalToSuperview().inset(6)
                make.right.lessThanOrEqualTo(rightButton.snp.left).offset(-8)
                make.bottom.equalToSuperview().inset(14)
            }
            rightButton.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(8)
                make.right.equalToSuperview().inset(16)
                make.bottom.lessThanOrEqualToSuperview().inset(14)
                make.width.height.equalTo(30)
            }
        }
    }

    @objc func dismissButtonTap() {
        dismiss(animated: true)
    }
}

// MARK: - ScrollableBottomSheetPresentedController

extension CurtainBaseVC: ScrollableBottomSheetPresentedController {
    var scrollView: UIScrollView? {
        _scrollView
    }
}
