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

    private var nameField: GPInputName?
    private var cardField: GPInputCard?
    private var expiryField: GPInputExpiry?
    private var cvvField: GPInputCVV?
    private var countryField: GPInputCountry?
    private var zipField: GPInputZip?
    private var cvvExpiryRow: UIStackView?
    private var zipRow: UIStackView?

    // MARK: Setups

    private func createFields() {
        if controller.config?.requireName ?? false {
            nameField = .init(controller: controller)
        }
        cardField = .init(controller: controller)
        expiryField = .init(controller: controller)
        cvvField = .init(controller: controller)
        cvvExpiryRow = UIStackView()
        cvvExpiryRow!.axis = .horizontal
        cvvExpiryRow!.distribution = .fillEqually
        cvvExpiryRow!.spacing = inputStyle.horizontalGap
        cvvExpiryRow!.translatesAutoresizingMaskIntoConstraints = false
        cvvExpiryRow!.addArrangedSubview(expiryField!)
        cvvExpiryRow!.addArrangedSubview(cvvField!)

        if controller.config?.requireZip ?? false {
            countryField = .init(controller: controller)
            zipField = .init(controller: controller)
            zipRow = UIStackView()
            zipRow!.axis = .horizontal
            zipRow!.distribution = .fillEqually
            zipRow!.spacing = inputStyle.horizontalGap
            zipRow!.translatesAutoresizingMaskIntoConstraints = false
            zipRow!.addArrangedSubview(countryField!)
            zipRow!.addArrangedSubview(zipField!)
        }
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
        addArrangedSubview(cardField!)
        addArrangedSubview(cvvExpiryRow!)
        if controller.config?.requireZip ?? false && zipRow != nil {
            addArrangedSubview(zipRow!)
        }
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
}
