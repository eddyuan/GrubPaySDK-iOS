//
//  GPInput+CVC.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation
import UIKit

class GPInputCVV: GPInput {
    // MARK: Validators

    private var cleanText: String {
        return super.text ?? ""
    }

    private func updateErrorState() {
        let targetErr: String? = valid ? nil : "Error"
        if super.errorMessage != targetErr {
            super.errorMessage = targetErr
        }
    }

    @discardableResult
    override open func resignFirstResponder() -> Bool {
        updateErrorState()
        return super.resignFirstResponder()
    }

    // MARK: Initializers

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }

    private func initField() {
        super.delegate = self
        super.titleText = "CVC"
        super.placeholder = "123"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
        super.returnKeyType = .next
    }

    override func didScan(_ cardNumber: String?, _ expiryDate: String?) {
        if cardNumber != nil && expiryDate != nil {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }

    private func onFinishField() {
        controller.onFinishField(GPInputType.cvc)
    }

    override func didFinishField(_ val: Int) {
        if GPInputType(rawValue: val) == .expiry {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }
}

extension GPInputCVV: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.maskInput(
            mask: "####",
            shouldChangeCharactersIn: range,
            replacementString: string,
            allowMix: false
        )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onFinishField()
        return true
    }
}

// Validator for controller
extension GPInputCVV {
    override var valid: Bool {
        if controller.config?.channel == .card {
            let trimmedStr = super.text ?? ""
            return trimmedStr.count > 2
        }
        return true
    }

    override func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        if controller.config?.channel != .card {
            onSuccess([:])
            return
        }
        updateErrorState()
        if valid {
            onSuccess(["cvv": cleanText])
        } else {
            onError("CVV")
        }
    }
}
