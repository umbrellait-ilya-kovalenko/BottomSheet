//
//  RootViewController.swift
//  BottomSheetDemo
//
//  Created by Mikhail Maslo on 14.11.2021.
//  Copyright © 2021 Joom. All rights reserved.
//

import BottomSheet
import SnapKit
import UIKit

final class RootViewController: UIViewController {
    private let centeredButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.setTitle("Centered Navbar", for: .normal)
        return button
    }()

    private let leftButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.setTitle("Left Navbar", for: .normal)
        return button
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
    }

    private func setupSubviews() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        view.addSubview(centeredButton)
        centeredButton.addTarget(self, action: #selector(handleCenteredButton), for: .touchUpInside)
        centeredButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(44)
        }

        view.addSubview(leftButton)
        leftButton.addTarget(self, action: #selector(handleLeftButton), for: .touchUpInside)
        leftButton.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(50)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(44)
        }
    }

    @objc private func handleCenteredButton() {
        // let viewController = ResizeViewController(initialHeight: 300)
        // let viewController = ControllerWithRows(numberOfItems: 0)
        let viewController = ControllerWithRowsOnBase(headerState: .centeredSignleWithNavbar, numberOfItems: 0)
        presentBottomSheetInsideNavigationController(
            viewController: viewController,
            configuration: .init(
                cornerRadius: 12,
                pullBarConfiguration: .default,
                shadowConfiguration: .default
            ),
            canBeDismissed: {
                // return `true` or `false` based on your business logic
                true
            },
            dismissCompletion: {
                // handle dismiss completion if user closed bottom sheet by a gesture
            }
        )
    }

    @objc private func handleLeftButton() {
        // let viewController = ResizeViewController(initialHeight: 300)
        // let viewController = ControllerWithRows(numberOfItems: 0)
        let viewController = ControllerWithRowsOnBase(headerState: .leftMultyline, numberOfItems: 0)
        presentBottomSheetInsideNavigationController(
            viewController: viewController,
            configuration: .init(
                cornerRadius: 12,
                pullBarConfiguration: .default,
                shadowConfiguration: .default
            ),
            canBeDismissed: {
                // return `true` or `false` based on your business logic
                true
            },
            dismissCompletion: {
                // handle dismiss completion if user closed bottom sheet by a gesture
            }
        )
    }
}
