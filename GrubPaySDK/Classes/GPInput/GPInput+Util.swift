//
//  GPInput+MaskUtil.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-12.
//

import Foundation

private extension String {
    func atIndex(_ location: Int) -> Character? {
        if self.count <= location {
            return nil
        }
        let idx = self.index(self.startIndex, offsetBy: location)
        return self[idx]
    }
}

enum GPInputUtil {
    static func keepLN(_ original: String) -> String {
        var result = ""
        for char in original {
            if char.isNumber || char.isLetter {
                result += String(char)
            }
        }
        return result
    }

    static func mask(
        _ original: String,
        mask: String,
        capitalize: Bool = false,
        maskNumber: Character = "#",
        maskLetter: Character = "A",
        allowMix: Bool = false
    ) -> String {
        var unmasked = original
        var masked = ""
        for char in mask {
            if char == maskNumber || char == maskLetter {
                var found = false

                while !found && !unmasked.isEmpty {
                    let first = unmasked.first!
                    if first.isLetter || first.isNumber {
                        if allowMix || (first.isNumber && char == maskNumber) || (first.isLetter && char == maskLetter) {
                            masked += String(first)
                            found = true
                        }
                    }
                    unmasked = String(unmasked.dropFirst())
                }

            } else {
                masked += String(char)
            }

            if unmasked.isEmpty {
                break
            }
        }

        if capitalize {
            masked = masked.uppercased()
        }

        return masked
    }

    static func maskInput(
        mask: String = "#### #### #### ####",
        maskNumber: Character = "#",
        maskLetter: Character = "A",
        textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String,
        capitalize: Bool = false,
        allowMix: Bool = false,
        allowMixFormatting: Bool = true
    ) -> Bool {
        if textField.text == nil {
            return true
        }
        let currentText = textField.text ?? ""
        // Check if it is backspace without selection
        var isBackspace = string.isEmpty && range.length == 1

        if isBackspace {
            if let selectedRange = textField.selectedTextRange {
                let userSelectedRangeLength = textField.offset(
                    from: selectedRange.start,
                    to: selectedRange.end
                )
                if userSelectedRangeLength == 1 {
                    isBackspace = false
                }
            }
        }

        var rangeStart = range.lowerBound
        var rangeEnd = range.upperBound

        if isBackspace {
            var shift = 0
            for i in stride(from: range.upperBound, through: 0, by: -1) {
                let character = mask.atIndex(i - 1)
                if character == maskNumber || character == maskLetter {
                    break
                } else {
                    shift += 1
                }
            }
            rangeStart -= shift
        }

        var uMask = ""

        var shiftStart = 0
        var shiftEnd = 0

        for (index, char) in mask.enumerated() {
            if char == maskNumber || char == maskLetter {
                uMask += String(char)
            } else {
                if rangeStart > index {
                    shiftStart += 1
                }
                if rangeEnd > index {
                    shiftEnd += 1
                }
            }
        }
        rangeStart -= shiftStart
        rangeEnd -= shiftEnd

        let maxUnmaskedLength = uMask.count

        let uCurrentText = self.keepLN(currentText)

        let trueReplacementRange = NSRange(
            location: rangeStart,
            length: rangeEnd - rangeStart
        )

        let currentUnmaskedLength = uCurrentText.count

        let availableLength = maxUnmaskedLength - currentUnmaskedLength + trueReplacementRange.length

        if availableLength <= 0 {
            return false
        }

        var uReplacementString = ""
        for (index, char) in string.enumerated() {
            if availableLength > uReplacementString.count {
                if (
                    allowMix && (char.isLetter || char.isNumber))
                    || (char.isLetter && uMask.atIndex(rangeStart + index) == maskLetter)
                    || (char.isNumber && uMask.atIndex(rangeStart + index) == maskNumber)
                {
                    uReplacementString += String(char)
                }
            } else {
                break
            }
        }

        let newUnmaskedText = (uCurrentText as NSString).replacingCharacters(
            in: trueReplacementRange,
            with: uReplacementString
        )

        let newMaskedText = self.mask(
            newUnmaskedText,
            mask: mask,
            capitalize: capitalize,
            maskNumber: maskNumber,
            maskLetter: maskLetter,
            allowMix: allowMixFormatting
        )

        let targetEnd = rangeStart + uReplacementString.count
        var targetEndShift = 0
        var validCount = 0

        if targetEnd > 1 {
            for char in mask {
                if char == "#" || char == "A" {
                    validCount += 1
                } else {
                    targetEndShift += 1
                }
                if validCount >= (targetEnd + 1) {
                    break
                }
            }
        }

        textField.text = newMaskedText

        let newEnd = targetEnd + targetEndShift

        if let newPosition = textField.position(
            from: textField.beginningOfDocument,
            offset: newEnd
        ) {
            // Give it a few moment to update the textfield if it's from pasting, otherwise cursor won't update correctly
            if string.count > 1 {
                DispatchQueue.main.async {
                    textField.selectedTextRange = textField.textRange(
                        from: newPosition,
                        to: newPosition
                    )
                }
            } else {
                // Regular input does not need delay
                textField.selectedTextRange = textField.textRange(
                    from: newPosition,
                    to: newPosition
                )
            }
        }

        return false
    }
}
