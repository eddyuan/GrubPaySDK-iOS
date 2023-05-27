//
//  GPCardForm.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-11.
//

import Foundation

import UIKit

class GPCardForm: UIStackView {
    let controller: GPFormController!

    open var inputStyle: GPInputStyle {
        return controller.style
    }

    private lazy var nameField: GPInputName = {
        let textField = GPInputName(controller: controller)
        textField.titleText = NSLocalizedString(
            "Name on card",
            bundle: Bundle(for: type(of: self)),
            comment: ""
        )
        return textField
    }()

    private lazy var cardField: GPInputCard = .init(controller: controller)
    private lazy var expiryField: GPInputExpiry = .init(controller: controller)
    private lazy var cvvField: GPInputCVV = .init(controller: controller)
    private lazy var countryField: GPInputCountry = .init(controller: controller)
    private lazy var zipField: GPInputZip = .init(controller: controller)

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

    private lazy var zipRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = inputStyle.horizontalGap
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.addArrangedSubview(countryField)
        sv.addArrangedSubview(zipField)
        return sv
    }()

    // MARK: Setups

    private func setupHierarchy() {
        axis = .vertical
        alignment = .fill
        distribution = .fill
        spacing = inputStyle.verticalGap
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(nameField)
        addArrangedSubview(cardField)
        addArrangedSubview(cvvExpiryRow)
        addArrangedSubview(zipRow)
    }

    private func initView() {
        setupHierarchy()
    }

    // MARK: Overrides

    public init(controller: GPFormController) {
        self.controller = controller
        super.init(frame: .zero)
        initView()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
