//
//  GPInput+Country.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-11.
//

import Foundation

class GPInputCountry: GPInput {
    var country: GPCountry {
        get {
            return super.controller.country
        }
        set {
            super.controller.country = newValue
        }
    }

    private func updateTexts() {
        DispatchQueue.main.async {
            [weak self] in
            self?.text = self?.country.rawValue
        }
    }

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

    private var pickerView = GPPickerCountry()

    private func initField() {
        super.delegate = self
        super.titleText = NSLocalizedString(
            "Country",
            bundle: Bundle(for: type(of: self)),
            comment: ""
        )
        super.keyboardType = .numberPad
        super.inputView = pickerView
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
            title: NSLocalizedString(
                "Cancel",
                bundle: Bundle(for: type(of: self)),
                comment: ""
            ),
            style: .plain,
            target: self,
            action: #selector(cancelClick)
        )
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        super.inputAccessoryView = toolBar
        updateTexts()
    }

    @objc func doneClick() {
        country = pickerView.country
        super.resignFirstResponder()
        onFinishField()
    }

    @objc func cancelClick() {
        super.resignFirstResponder()
    }

    override func becomeFirstResponder() -> Bool {
        pickerView.country = country
        return super.becomeFirstResponder()
    }
}

extension GPInputCountry: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}

// MARK: For GPFormObs

extension GPInputCountry {
    override var valid: Bool {
        return true
    }

    override func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        onSuccess([:])
    }

    override func didFinishField(_ val: Int) {
        if GPInputType(rawValue: val) == .cvc {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }

    override func countryDidChange() {
        updateTexts()
    }

    func onFinishField() {
        controller.onFinishField(GPInputType.country)
    }
}
