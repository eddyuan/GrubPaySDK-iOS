//
//  GPACHForm.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-16.
//

import Foundation

import UIKit

class GPACHForm: UIStackView {
    let controller: GPFormController!

//    var allValid: Bool {
//        return routingField.valid && nameField.valid && accountField.valid && accountTypeField.valid
//    }

    var onChange: (() -> Void)?

    private func _fieldChange() {
        onChange?()
    }

    open var inputStyle: GPInputStyle {
        return controller.style
    }

    // MARK: Fields

    private var routingField: GPInputRouting?
    private var nameField: GPInputName?
    private var accountField: GPInputAccount?
    private var accountTypeField: GPRadioAccountType?
    private var agreementField: GPSwitchACHAgreement?

    // MARK: Setups

    private func createFields() {
        routingField = .init(controller: controller)
        if controller.config?.requireName ?? false {
            nameField = .init(controller: controller)
        }
        accountField = .init(controller: controller)
        accountTypeField = .init(controller: controller)
        agreementField = .init(controller: controller)
    }

    private func setupHierarchy() {
        axis = .vertical
        alignment = .fill
        distribution = .fill
        spacing = inputStyle.verticalGap
        translatesAutoresizingMaskIntoConstraints = false
        if controller.config?.requireName ?? false && nameField != nil {
            addArrangedSubview(nameField!)
        }

        addArrangedSubview(routingField!)
        addArrangedSubview(accountField!)
        addArrangedSubview(accountTypeField!)
        addArrangedSubview(agreementField!)
    }

    private func initView() {
        createFields()
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

    deinit {
        print("deinit of ach form")
    }
}
