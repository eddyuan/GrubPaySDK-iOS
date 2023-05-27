//
//  GPInput+Expiry.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation

class GPInputExpiry: GPInput {
    // MARK: Validators

    var dateString: String? {
        let trimmedStr = super.text ?? ""
        if trimmedStr.count != 5 {
            return nil
        }
        let components = trimmedStr.split(separator: "/")
        guard components.count == 2 else {
            return nil
        }
        let monthString = String(components[0])
        let yearShortString = String(components[1])
        let yearString = "20" + yearShortString

        guard let month = Int(monthString), let year = Int(yearString) else {
            return nil
        }

        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth: Int = calendar.component(.month, from: currentDate)
        let currentYear: Int = calendar.component(.year, from: currentDate)

        if year < currentYear {
            return nil
        }

        if year == currentYear {
            if month < currentMonth {
                return nil
            }
        }

        if month < 1 || month > 12 {
            return nil
        }

        return monthString + yearShortString
    }

    var cleanText: String {
        return dateString ?? ""
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

    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }

    private let expiryPicker = GPPickerExpiry()

    private func initField() {
        super.delegate = self
        super.titleText = NSLocalizedString("Expiration", bundle: Bundle(for: type(of: self)), comment: "")
        super.placeholder = "MM/YY"
        super.keyboardType = .decimalPad
        super.inputView = expiryPicker
        super.autocorrectionType = .no
        super.autocapitalizationType = .none

        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(
            title: NSLocalizedString("Done", bundle: Bundle(for: type(of: self)), comment: ""),
            style: .plain,
            target: self,
            action: #selector(doneClick)
        )
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(
            title: NSLocalizedString("Cancel", bundle: Bundle(for: type(of: self)), comment: ""),
            style: .plain,
            target: self,
            action: #selector(cancelClick)
        )
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        super.inputAccessoryView = toolBar
    }

    @objc func doneClick() {
        let month = expiryPicker.month
        let year = expiryPicker.year
        let string = String(format: "%02d/%02d", month, year % 100)
        print(string)
        super.text = string
        super.resignFirstResponder()
    }

    @objc func cancelClick() {
        print(NSLocale.current)
        super.resignFirstResponder()
    }
}

extension GPInputExpiry: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}

// Validator for controller
extension GPInputExpiry {
    override var valid: Bool {
        if controller.config?.mode == .card {
            return dateString != nil
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
            onSuccess(["expiryDate": cleanText])
        } else {
            onError("Expiry Date")
        }
    }
}
