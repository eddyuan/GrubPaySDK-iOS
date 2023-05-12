//
//  GPCardForm.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-11.
//

import Foundation

import UIKit

class GPCardForm: UIStackView {
    open var requireName: Bool = false {
        didSet {
            print(requireName)
        }
    }

    // MARK: Passthrough

    open var inputStyle: GPInputStyle {
        get {
            return allFields[0].gpInputStyle
        }
        set {
            for field in allFields {
                field.gpInputStyle = newValue
            }
        }
    }

    open var isEnabled: Bool {
        get {
            return allFields[0].isEnabled
        }
        set {
            for field in allFields {
                field.isEnabled = newValue
            }
        }
    }

    // MARK: Fields

    private var allFields: [GPInput] {
        return [
            cardNumberField,
            cardholderField,
            expiryField,
            cvvField
        ]
    }

    private lazy var cardNumberField: GPInput = {
        let textField = GPInputCard()
        return textField
    }()

    private lazy var cardholderField: GPInput = {
        let textField = GPInputHolderName()
        return textField
    }()

    private lazy var expiryField: GPInput = {
        let textField = GPInputExpiry()
        return textField
    }()

    private lazy var cvvField: GPInput = {
        let textField = GPInputCVV()
        return textField
    }()

    private lazy var cvvExpiryRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = inputStyle.horizontalGap
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.addArrangedSubview(expiryField)
        sv.addArrangedSubview(cvvField)
        return sv
    }()

    private lazy var countryField: GPInput = {
        let textField = GPInputCountry()
        return textField
    }()

    private lazy var zipRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = inputStyle.horizontalGap
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.addArrangedSubview(countryField)
        sv.addArrangedSubview(countryField)
        return sv
    }()

    // MARK: Setups

    private func setupHierarchy() {
        axis = .vertical
        alignment = .fill
        spacing = inputStyle.verticalGap
        translatesAutoresizingMaskIntoConstraints = false
        if requireName {
            addArrangedSubview(cardholderField)
        }
        addArrangedSubview(cardNumberField)
        addArrangedSubview(cvvExpiryRow)
        addArrangedSubview(zipRow)
    }

    private func setupLayout() {
        if let superview = superview ?? window {
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                topAnchor.constraint(equalTo: superview.topAnchor),
                bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ])
        }
    }

    // MARK: Overrides

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupLayout()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        setupLayout()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupLayout()
    }
}
