
//
//  ViewController.swift
//  GrubPaySDK
//
//  Created by 43017558 on 04/21/2023.
//  Copyright (c) 2023 43017558. All rights reserved.
//
import UIKit

public class GrubPayElement: UIStackView {
    // MARK: Style Options

    let controller: GPFormController = .init()

    open var inputStyle: GPInputStyle {
        get {
            return controller.style
        }
        set {
            controller.style = newValue
        }
    }

    // MARK: ServerProperties

    private var initialized: Bool {
        return controller.config != nil
    }

    private var paid: Bool = false

    // MARK: Validates

    private var allValid: Bool = false

    // MARK: Hierarchy

    private var cardForm: GPCardForm?

    private var achForm: GPACHForm?

    private lazy var loadingIndicator: UIView = {
        let l: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            l = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        } else {
            l = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        }
        l.startAnimating()

        return l
    }()

    private lazy var loadingView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let minHeightConstraint = v.heightAnchor.constraint(equalToConstant: 200)
        minHeightConstraint.isActive = true
        v.addSubview(loadingIndicator)
        return v
    }()

    // MARK: Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    @available(*, unavailable)
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    // MARK: Setup

    private func initView() {
        controller.addObs(self)
        setupHierarchy()
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }

    private func setupHierarchy() {
        axis = .vertical
        alignment = .fill
        distribution = .fill
        spacing = inputStyle.verticalGap
        translatesAutoresizingMaskIntoConstraints = false
        mountViews()
    }

    private func mountViews() {
        subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        cardForm = nil
        achForm = nil
        if controller.config?.mode == .ach {
            achForm = GPACHForm(controller: controller)
            addArrangedSubview(achForm!)
        } else if controller.config?.mode == .card {
            cardForm = GPCardForm(controller: controller)
            addArrangedSubview(cardForm!)
        } else {
            addArrangedSubview(loadingView)
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if controller.config == nil {
            loadingIndicator.center = loadingView.center
        }
    }

    // Function for user to call

    open func initialize(
        _ secureId: String,
        onSuccess: @escaping () -> Void = {},
        onError: @escaping (String) -> Void = { _ in }
    ) {
        if controller.config != nil {
            let targetHeight = achForm?.frame.height ?? cardForm?.frame.height ?? 200
            let minHeightConstraint = loadingView.heightAnchor.constraint(equalToConstant: targetHeight)
            minHeightConstraint.isActive = true
            controller.config = nil
            mountViews()
        }
        controller.initialize(
            secureId,
            onSuccess: {
                _ in
                self.mountViews()
                onSuccess()
            },
            onError: onError
        )
    }

    open func submit(
    ) {
        controller.submitForm()
    }
}

extension GrubPayElement: GPFormObs {
    func fieldDidChange() {
        print("fieldChange")
    }
}
