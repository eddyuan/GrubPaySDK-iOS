//
//  GPInput+HolderName.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation

class GPInputHolderName: GPInput {
    var onChanged: ((_ valid: Bool) -> Void)?

    var valid: Bool = false {
        didSet {
            if valid && super.errorMessage != nil {
                super.errorMessage = nil
            }

            onChanged?(valid)
        }
    }

    @objc func textFieldDidChange() {
        let trimmedStr = super.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isValid = trimmedStr.count > 2
        if valid != isValid {
            valid = isValid
        }
        super.errorMessage = nil
    }

    private func initField() {
        super.delegate = self
        super.titleText = NSLocalizedString(
            "Name on card",
            bundle: Bundle(for: type(of: self)),
            comment: ""
        )
        super.placeholder = NSLocalizedString(
            "Name",
            bundle: Bundle(for: type(of: self)),
            comment: ""
        )
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    // MARK: Overrides

    override init(frame: CGRect) {
        super.init(frame: frame)
        initField()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initField()
    }

    override var text: String? {
        didSet {
            textFieldDidChange()
        }
    }

    @discardableResult
    override open func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        super.errorMessage = valid ? nil : "Error"
        super.text = super.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }
}

extension GPInputHolderName: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
}
