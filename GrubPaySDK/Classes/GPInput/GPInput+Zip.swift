//
//  GPInput+Zip.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-12.
//

import Foundation

class GPInputZip: GPInput {
    // MARK: Validators

    var cleanText: String {
        return country == .others ? "" : (super.text ?? "")
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

    var country: GPCountry {
        return super.controller.country
    }

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }

    private func initField() {
        super.delegate = self
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        updateTexts()
    }

    func updateTexts() {
        if country == .others {
            super.isHidden = true
        } else {
            super.titleText = country.zipName
            super.placeholder = country.zipPh
            super.keyboardType = country.keyboardType
            super.isHidden = false
            let mask = super.controller.country.inputMask
            if mask != nil {
                let maskedText = GPInputUtil.mask(super.text ?? "", mask: mask!)
                if super.text != maskedText {
                    super.text = ""
                }
            }
        }
    }

    // MARK: for GPFormObs

    override func countryDidChange() {
        updateTexts()
    }
}

extension GPInputZip: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let mask = super.controller.country.inputMask
        if mask != nil {
            return GPInputUtil.maskInput(
                mask: mask!,
                textField: textField,
                shouldChangeCharactersIn: range,
                replacementString: string,
                capitalize: true,
                allowMix: false
            )
        }
        return true
    }
}

// Validator for controller
extension GPInputZip {
    override var valid: Bool {
        if controller.config?.requireZip == true && controller.config?.mode == .card {
            let validText = super.text ?? ""
            return country.validateText(validText)
        }
        return true
    }

    override func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        if controller.config?.mode != .card {
            onSuccess([:])
            return
        }
        updateErrorState()
        if valid {
            onSuccess(["zip": cleanText])
        } else {
            onError("Zip")
        }
    }
}
