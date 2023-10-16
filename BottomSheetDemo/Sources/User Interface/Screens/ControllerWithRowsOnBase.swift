//
//  ControllerWithRowsOnBase.swift
//  SwiftBottomShitTestProj
//
//  Created by Ilya Kovalenko on 12.10.2023.
//

import BottomSheet
import UIKit

private enum Constant {
    static let rowCountOffset = 3
}

class ControllerWithRowsOnBase: CurtainBaseVC {
    private let stackView = UIStackView()
    private let buttonsStack = UIStackView()
    private let button1 = UIButton(type: .system)
    private let button2 = UIButton(type: .system)

    private let scrollContentView = UIView()
    private let bottomContainer = UIView()

    private let numberOfItems: Int

    let _headerState: HeaderState

    override var headerState: HeaderState {
        return _headerState
    }

    init(headerState: HeaderState, numberOfItems: Int) {
        _headerState = headerState
        self.numberOfItems = numberOfItems
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Displaying \n\(numberOfItems) items"
        fillWithItems()
        updatePreferredContentSize()
    }

    override func setupContentUI() {
        setupContentView()
        setupBottomView()
    }

    override func getBottomContainer() -> UIView {
        return bottomContainer
    }

    override func getScrollContentView() -> UIView {
        return scrollContentView
    }

    private func setupBottomView() {
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 8
        button1.layer.cornerRadius = 8
        button1.backgroundColor = .blue
        button1.tintColor = .white
        button1.setTitle("Open screen with \(numberOfItems + Constant.rowCountOffset) rows", for: .normal)
        button1.addTarget(self, action: #selector(handleNextButtonTap), for: .touchUpInside)

        button2.layer.cornerRadius = 8
        button2.backgroundColor = .lightGray.withAlphaComponent(0.5)
        button2.tintColor = .blue
        button2.setTitle("Print number of items", for: .normal)
        button2.addTarget(self, action: #selector(handlePrintButtonTap), for: .touchUpInside)

        bottomContainer.addSubview(buttonsStack)
        buttonsStack.addArrangedSubview(button1)
        buttonsStack.addArrangedSubview(button2)

        buttonsStack.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }

        button1.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        button2.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }

    private func setupContentView() {
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        scrollContentView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.top.equalToSuperview()
        }
    }

    private func fillWithItems() {
        for i in 0 ..< numberOfItems {
            let view = UIView()
            view.layer.cornerRadius = 8
            view.backgroundColor = .red.withAlphaComponent(0.5)
            let label = UILabel()

            label.text = "\(i + 1) Lorem ipsum"
            label.font = .systemFont(ofSize: 16, weight: .regular)
            label.textColor = .white

            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(8)
                make.top.bottom.equalToSuperview().inset(8)
            }

            stackView.addArrangedSubview(view)
        }
    }

    @objc private func handleNextButtonTap() {
        let vc = ControllerWithRowsOnBase(headerState: _headerState, numberOfItems: numberOfItems + Constant.rowCountOffset)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handlePrintButtonTap() {
        print("Number of items: \(numberOfItems)")
    }
}
