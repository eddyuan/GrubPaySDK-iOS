
//
//  ViewController.swift
//  GrubPaySDK
//
//  Created by 43017558 on 04/21/2023.
//  Copyright (c) 2023 43017558. All rights reserved.
//
import UIKit

public class GrubPayElement: UIView {
    // MARK: Style Options

    internal let controller: GPFormController = .init()

    private let onFormValidChange: (_ isValid: Bool) -> Void
    private let onFormEnabledChange: (_ isEnabled: Bool) -> Void
    private let onLoadingChange: (_ isLoading: Bool) -> Void

    open var isFormValid: Bool {
        return controller.isFormValid
    }

    open var isEnabled: Bool {
        return controller.isEnabled
    }

    open var isLoading: Bool {
        return controller.isLoading
    }

    open var inputStyle: GPInputStyle {
        get {
            return controller.style
        }
        set {
            controller.style = newValue
        }
    }

    open var amount: Int? {
        return controller.config?.amount
    }

    open var channel: GrubPayChannel? {
        return controller.config?.channel
    }

    // MARK: ServerProperties

    // MARK: Hierarchy

    private var cardForm: GPCardForm?

    private var achForm: GPACHForm?

    private var loadingViewHeightConstraint: NSLayoutConstraint?

    private var loadingView: UIView?

    private func buildLoadingView() -> UIView {
        let v = UIView()
        let l: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            l = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        } else {
            l = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        }
        v.translatesAutoresizingMaskIntoConstraints = false
        l.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            l.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])

        l.startAnimating()
        return v
    }

    // MARK: Initializers

    internal init(
        viewController: UIViewController? = nil,
        onValidChange: @escaping (_ isValid: Bool) -> Void = { _ in },
        onEnableChange: @escaping (_ isEnabled: Bool) -> Void = { _ in },
        onLoadingChange: @escaping (_ isLoading: Bool) -> Void = { _ in }
    ) {
        controller.rootViewController = viewController
        self.onFormValidChange = onValidChange
        self.onFormEnabledChange = onEnableChange
        self.onLoadingChange = onLoadingChange
        super.init(frame: .zero)
        initView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    override public init(frame: CGRect) {
//        super.init(frame: frame)
//        initView()
//    }
//
//    @available(*, unavailable)
//    required init(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    // MARK: Setup

    private func initView() {
        controller.addObs(self)
        updateViews()
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }

    private func updateViews() {
        let targetHeight: CGFloat = achForm?.frame.size.height ?? cardForm?.frame.size.height ?? 200

        print("targetHeight", targetHeight)

        for subview in subviews {
            subview.removeFromSuperview()
        }

        if controller.config?.channel == .ach {
            mountAchForm()
        } else if controller.config?.channel == .card {
            mountCardForm()
        } else {
            mountLoadingView(targetHeight)
        }
    }

    private func mountCardForm() {
        achForm = nil
        loadingView = nil
        cardForm = GPCardForm(controller: controller)
        cardForm!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardForm!)
        NSLayoutConstraint.activate([
            cardForm!.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardForm!.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardForm!.topAnchor.constraint(equalTo: topAnchor),
            cardForm!.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func mountAchForm() {
        cardForm = nil
        loadingView = nil
        achForm = GPACHForm(controller: controller)
        achForm!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(achForm!)
        NSLayoutConstraint.activate([
            achForm!.leadingAnchor.constraint(equalTo: leadingAnchor),
            achForm!.trailingAnchor.constraint(equalTo: trailingAnchor),
            achForm!.topAnchor.constraint(equalTo: topAnchor),
            achForm!.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func mountLoadingView(_ height: CGFloat) {
        cardForm = nil
        achForm = nil
        loadingView = buildLoadingView()
        addSubview(loadingView!)
        loadingView!.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView!.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingView!.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingView!.topAnchor.constraint(equalTo: topAnchor),
            loadingView!.bottomAnchor.constraint(equalTo: bottomAnchor),
            loadingView!.heightAnchor.constraint(equalToConstant: height)
        ])
    }

    // Function for user to call

    open func mount(
        _ secureId: String,
        completion: @escaping (Result<GrubPayChannel, GrubPayError>) -> Void
    ) {
        controller.mount(secureId, completion: completion)
    }

    open func submit(
        saveCard: Bool = false,
        completion: @escaping (Result<GrubPayResponse, GrubPayError>) -> Void
    ) {
        controller.submitForm(
            saveCard: saveCard,
            completion: completion
        )
    }

    deinit {
        controller.removeObs(self)
    }
}

extension GrubPayElement: GPFormObs {
    func configDidChange() {
        DispatchQueue.main.async {
            [weak self] in
            self?.updateViews()
        }
    }

    func validDidChange(_ isValid: Bool) {
        onFormValidChange(isValid)
    }

    func isEnabledDidChange(_ isEnabled: Bool) {
        onFormEnabledChange(isEnabled)
    }

    func isLoadingDidChange(_ isLoading: Bool) {
        onLoadingChange(isLoading)
    }
}
