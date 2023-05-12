//
//  GPInput+CVC.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation

class GPInputCVV: GPInput {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initField()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initField()
    }

    private func initField() {
        super.delegate = self
        super.titleText = "CVC"
        super.placeholder = "###"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
    }
}

extension GPInputCVV: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)),
              let text = textField.text
        else {
            return false
        }

        let newLength = text.count + string.count - range.length
        return newLength <= 4
    }
}
