//
//  GPInput+Expiry.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation

class GPInputExpiry: GPInput {
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initField()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initField()
    }

    private let expiryPicker = GPExpiryPicker()

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
