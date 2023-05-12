//
//  GRInput+Card.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-04.
//

import Foundation

final class GRInputCard: GRInput {
    init() {
        super.init(inputType: .cardNumber)
        super.titleLabel.text = NSLocalizedString("Card number", bundle: Bundle(for: type(of: self)), comment: "")
    }
}

private extension String {
    func formatAsCreditCardNumber(pattern: String = "#### #### #### ####", replacmentCharacter: Character = "#") -> String {
        var pureNumber = replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        for index in 0 ..< pattern.count {
            guard index < pureNumber.count else { return pureNumber }
            let stringIndex = String.Index(encodedOffset: index)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacmentCharacter else { continue }
            pureNumber.insert(patternCharacter, at: stringIndex)
        }
        return pureNumber
    }
}

extension GRInputCard: UITextFieldDelegate {
    func formatCardNumber(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var replacementNumbers = string.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        guard CharacterSet(charactersIn: "0123456789").isSuperset(of: CharacterSet(charactersIn: replacementNumbers)) else {
            return false
        }

        let maxNumberLength = 16

        var userSelectedRangeLength = 0

        if let selectedRange = textField.selectedTextRange {
            userSelectedRangeLength = textField.offset(from: selectedRange.start, to: selectedRange.end)
        }

        var trueStart = range.lowerBound - Int(floor(Double(range.lowerBound / 5)))
        let trueEnd = range.upperBound - Int(floor(Double(range.upperBound / 5)))

        // If power of 5 and is deleting 1 but not selected by user, unshift 1 space
        // This is when deleting on position 5, 10, 15 right after the space
        // 如果正好是第五的倍数且是删除1个操作且不是用户选择的，那么向前移动一个
        if range.length == 1 && (range.lowerBound + 1) % 5 == 0 && string == "" && userSelectedRangeLength != 1 {
            trueStart -= 1
        }

        // This is the true selected range unmasked
        let trueRange = NSRange(location: trueStart, length: trueEnd - trueStart)

        // This is the current textField text unmaksed
        let currentNumber = (textField.text ?? "").replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression) as NSString

        // Calculate the available length with unmasked
        let availableLength = maxNumberLength - currentNumber.length + trueRange.length

        // If there's no more space left for new characters
        guard availableLength > 0 else {
            return false
        }

        // Cut the length of the pasting string
        if replacementNumbers.count > availableLength {
            replacementNumbers = String(replacementNumbers.prefix(availableLength))
        }

        let updatedNumber = currentNumber.replacingCharacters(in: trueRange, with: replacementNumbers)
        let updatedFormatted = updatedNumber.formatAsCreditCardNumber()

        // Update the text as early as possible
        textField.text = updatedFormatted

        let targetEndPositionBeforeFormat = trueRange.lowerBound + replacementNumbers.count
        let targetEndPosition = min(targetEndPositionBeforeFormat + Int(floor(Double(targetEndPositionBeforeFormat / 4))), updatedFormatted.count)

        // Update the cursor position
        if let newPosition = textField.position(from: textField.beginningOfDocument, offset: targetEndPosition) {
            // Give it a few moment to update the textfield if it's from pasting, otherwise cursor won't update correctly
            if string == UIPasteboard.general.string {
                DispatchQueue.main.async {
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            } else {
                // Regular input does not need delay
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
        }
        return false
    }

//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if inputType == .cardNumber {
//            return formatCardNumber(textField: textField, shouldChangeCharactersInRange: range, replacementString: string)
//        }
//
//        if inputType == .expiry {
//            return false
//        }
//        return true
//    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Begining editing")
//        if inputType == .expiry {
//            print(textField.text ?? "nothing")
//        }
    }
}
