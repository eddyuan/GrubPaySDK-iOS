//
//  ViewController.swift
//  GrubPaySDK
//
//  Created by 43017558 on 04/21/2023.
//  Copyright (c) 2023 43017558. All rights reserved.
//

import GrubPaySDK
import UIKit

class ViewController: UIViewController {
    // MARK: - Properties

    let contentInsets = UIEdgeInsets(
        top: 48,
        left: 0,
        bottom: 48,
        right: 0
    )

//    private let grubpayInputField: GrubPayInputField = GrubPayInputField()

    private lazy var grubpayElement: GrubPayElement = {
        let el = GrubPayElement()
        el.translatesAutoresizingMaskIntoConstraints = false
        return el
    }()

    private lazy var grubpayElement2: GrubPayElement = {
        let el = GrubPayElement()
        el.inputStyle = GPInputStyle(
            accentColor: UIColor.red
        )
        el.translatesAutoresizingMaskIntoConstraints = false
        return el
    }()

    private lazy var grubpayElement3: GrubPayElement = {
        let el = GrubPayElement()
        el.inputStyle = GPInputStyle(
            accentColor: UIColor.red
        )
        el.translatesAutoresizingMaskIntoConstraints = false
        return el
    }()

    private lazy var grubpayElement4: GrubPayElement = {
        let el = GrubPayElement()
        el.inputStyle = GPInputStyle(
            accentColor: UIColor.red
        )
        el.translatesAutoresizingMaskIntoConstraints = false
        return el
    }()

    @objc func onSubmitButton() {
        grubpayElement.submit()
    }

    @objc func onLoadButton() {
        grubpayElement.initialize(arc4random_uniform(2) == 0 ? "demoAch" : "demoCard")
    }

    private lazy var submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.systemBlue
        b.setTitleColor(UIColor.white, for: .normal)
        b.setTitle("Test Submit", for: .normal)
        b.addTarget(self, action: #selector(onSubmitButton), for: .touchUpInside)
        return b
    }()

    private lazy var loadButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = UIColor.systemBlue
        b.setTitleColor(UIColor.white, for: .normal)
        b.setTitle("Test load", for: .normal)
        b.addTarget(self, action: #selector(onLoadButton), for: .touchUpInside)
        return b
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.addArrangedSubview(grubpayElement)
        sv.addArrangedSubview(loadButton)
        sv.addArrangedSubview(submitButton)
        sv.addArrangedSubview(grubpayElement2)
        sv.addArrangedSubview(grubpayElement3)
        sv.addArrangedSubview(grubpayElement4)
        return sv
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.addSubview(stackView)
        sv.backgroundColor = GPInputStyle.getAdaptiveColor(light: UIColor.white, dark: UIColor.black)
//        sv.contentInset = contentInsets
//        sv.scrollIndicatorInsets = contentInsets
        return sv
    }()

    // MARK: - Lifecycle Methods

    func onMountedSuccess() {}
    func onMountFail(message: String) {
        /// This indicates that GrubPay Element is not mounted successfully, need recall initialize with another secureId
        print("Message")
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardHeight = keyboardFrame.cgRectValue.height

        let targetInset = UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.left,
            bottom: contentInsets.bottom + keyboardHeight,
            right: contentInsets.right
        )
        scrollView.contentInset = targetInset
        scrollView.scrollIndicatorInsets = targetInset
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
//        grubpayElement.initialize("123123", onSuccess: onMountedSuccess, onError: onMountFail)
        grubpayElement2.initialize("123123", onSuccess: onMountedSuccess, onError: onMountFail)
        grubpayElement3.initialize("123123", onSuccess: onMountedSuccess, onError: onMountFail)
        grubpayElement4.initialize("123123", onSuccess: onMountedSuccess, onError: onMountFail)
        setupLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    // MARK: - Helper Methods

    private func setupLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }
}
