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
            if let mask = super.controller.country.inputMask, let superText = super.text {
                let maskedText = superText.mask(mask: mask)
                if super.text != maskedText {
                    super.text = ""
                }
            }
        }
    }
}

extension GPInputZip: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if let mask = super.controller.country.inputMask {
            return textField.maskInput(
                mask: mask,
                shouldChangeCharactersIn: range,
                replacementString: string,
                capitalize: true,
                allowMix: false
            )
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

// MARK: for GPFormObs

extension GPInputZip {
    override var valid: Bool {
        if controller.config?.requireZip == true && controller.config?.channel == .card {
            let validText = super.text ?? ""
            return country.validateText(validText)
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
            onSuccess(["zip": cleanText])
        } else {
            onError("Zip")
        }
    }

    override func countryDidChange() {
        updateTexts()
    }

    private func onFinishField() {
        controller.onFinishField(GPInputType.zip)
    }

    override func didFinishField(_ val: Int) {
        if GPInputType(rawValue: val) == .country {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }
}
