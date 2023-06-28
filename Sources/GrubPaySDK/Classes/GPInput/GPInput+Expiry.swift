//
//  GPInput+Expiry.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation
import UIKit

class GPInputExpiry: GPInput {
    // MARK: Validators

    private var dateString: String? {
        return text?.toValidDateStringOrNil()
    }

    private var cleanText: String {
        return dateString ?? ""
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
        let string = expiryPicker.dateString
        DispatchQueue.main.async {
            [weak self] in
            self?.text = string
        }
        super.resignFirstResponder()
        onFinishField()
    }

    @objc func cancelClick() {
        super.resignFirstResponder()
    }

    override func becomeFirstResponder() -> Bool {
        expiryPicker.dateString = text ?? ""
        return super.becomeFirstResponder()
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
        if controller.config?.channel == .card {
            return dateString != nil
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
            onSuccess(["expiryDate": cleanText])
        } else {
            onError("Expiry Date")
        }
    }

    override func didScan(_ cardNumber: String?, _ expiryDate: String?) {
        if let expiryDate = expiryDate {
            DispatchQueue.main.async {
                [weak self] in
                self?.text = expiryDate
                self?.expiryPicker.dateString = expiryDate
            }
        } else if cardNumber != nil {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }

    private func onFinishField() {
        controller.onFinishField(GPInputType.expiry)
    }

    override func didFinishField(_ val: Int) {
        if GPInputType(rawValue: val) == .card {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }
}
