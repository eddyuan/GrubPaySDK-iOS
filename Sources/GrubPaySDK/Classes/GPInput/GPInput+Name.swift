//
//  GPInput+HolderName.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation
import UIKit

class GPInputName: GPInput {
    // MARK: Validators

    private var cleanText: String {
        return super.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func updateErrorState() {
        let targetErr: String? = valid ? nil : "Error"
        if super.errorMessage != targetErr {
            super.errorMessage = targetErr
        }
    }

    @discardableResult
    override open func resignFirstResponder() -> Bool {
        super.text = super.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        updateErrorState()
        return super.resignFirstResponder()
    }

    // MARK: Initializers

    private func initField() {
        super.delegate = self
        super.titleText = NSLocalizedString(
            controller.config?.channel == .card ? "Name on card" : "Name",
            bundle: Bundle(for: type(of: self)),
            comment: ""
        )
        super.placeholder = "John Smith"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .default
        super.returnKeyType = .next
    }

    // MARK: Overrides

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }

    private func onFinishField() {
        controller.onFinishField(GPInputType.name)
    }
}

extension GPInputName: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Get the current text in the text field
        guard textField.text != nil else { return true }

        // Create a character set that allows letters, numbers, and spaces
        let allowedCharacterSet = CharacterSet.letters
            .union(CharacterSet.decimalDigits)
            .union(CharacterSet.whitespaces)
            .union(CharacterSet(charactersIn: ",."))

        // Iterate through each character in the replacement string
        for character in string {
            // Check if the character is allowed
            if !allowedCharacterSet.contains(character.unicodeScalars.first!) {
                // If the character is not allowed, return false to reject the change
                return false
            }
        }

        // If all characters are allowed, perform the change
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onFinishField()
        return true
    }
}

extension GPInputName {
    override var valid: Bool {
        if controller.config?.requireName == true {
            let trimmedStr = super.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmedStr.count > 2
        }
        return true
    }

    override func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        updateErrorState()
        if valid {
            if controller.config?.requireName == false {
                onSuccess([:])
            } else {
                onSuccess(["name": cleanText])
            }
        } else {
            onError("Name")
        }
    }
}
