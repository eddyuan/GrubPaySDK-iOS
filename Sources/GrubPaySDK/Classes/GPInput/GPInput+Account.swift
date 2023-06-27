//
//  GPInput+Account.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-16.
//

import Foundation

class GPInputAccount: GPInput {
    // MARK: Validators

    var cleanText: String {
        return super.text ?? ""
    }

    func updateErrorState() {
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

    private func initField() {
        super.delegate = self
        super.titleText = "Account Number"
        super.placeholder = "000123456789"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
    }

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }
}

extension GPInputAccount: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.maskInput(
            mask: "############",
            shouldChangeCharactersIn: range,
            replacementString: string,
            allowMix: false
        )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

// Validator for controller
extension GPInputAccount {
    override var valid: Bool {
        if controller.config?.channel == .ach {
            return (super.text ?? "").count > 3
        }
        return true
    }

    override func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        if controller.config?.channel != .ach {
            onSuccess([:])
            return
        }
        updateErrorState()
        if valid {
            onSuccess(["accountNum": cleanText])
        } else {
            onError("Account Number")
        }
    }
}
