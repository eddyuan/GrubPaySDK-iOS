//
//  GPInput+Routing.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-16.
//

import Foundation
import UIKit

class GPInputRouting: GPInput {
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

    private func initField() {
        super.delegate = self
        super.titleText = "Routing Number"
        super.placeholder = "123456789"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
        super.returnKeyType = .next
    }

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }

    private func onFinishField() {
        controller.onFinishField(GPInputType.routing)
    }

    override func didFinishField(_ val: Int) {
        if GPInputType(rawValue: val) == .name {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }
}

extension GPInputRouting: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.maskInput(
            mask: "#########",
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
extension GPInputRouting {
    override var valid: Bool {
        if controller.config?.channel == .ach {
            return (super.text ?? "").count == 9
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
            onSuccess(["routingNum": cleanText])
        } else {
            onError("Routing Number")
        }
    }
}
