//
//  GPInput+Routing.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-16.
//

import Foundation

class GPInputRouting: GPInput {
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
        super.titleText = "Routing Number"
        super.placeholder = "123456789"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
    }

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }
}

extension GPInputRouting: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return GPInputUtil.maskInput(
            mask: "#########",
            textField: textField,
            shouldChangeCharactersIn: range,
            replacementString: string,
            allowMix: false
        )
    }
}

// Validator for controller
extension GPInputRouting {
    override var valid: Bool {
        if controller.config?.mode == .ach {
            return (super.text ?? "").count == 9
        }
        return true
    }

    override func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        if controller.config?.mode != .ach {
            onSuccess([:])
            return
        }
        updateErrorState()
        if valid {
            onSuccess(["routingNum": cleanText])
        } else {
            onError("Routing Number")
        }
    }
}
