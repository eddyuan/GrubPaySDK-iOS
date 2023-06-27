//
//  GPUtil.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-21.
//

import Foundation

internal extension String {
    func toValidDateStringOrNil() -> String? {
        let trimmedStr = self.replacingOccurrences(of: " ", with: "")
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

    func atIndex(_ location: Int) -> Character? {
        if self.count <= location {
            return nil
        }
        let idx = self.index(self.startIndex, offsetBy: location)
        return self[idx]
    }

    func keepLN() -> String {
        var result = ""
        for char in self {
            if char.isNumber || char.isLetter {
                result += String(char)
            }
        }
        return result
    }

    func luhnCheck() -> Bool {
        // MARK: Luhn algorithm 3 from ai

        let cleanedNumber = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let reversedNumber = String(cleanedNumber.reversed())

        var sum = 0
        let digits = reversedNumber.map { Int(String($0)) ?? 0 }

        for (index, digit) in digits.enumerated() {
            if index % 2 == 1 {
                let doubledDigit = digit * 2
                sum += doubledDigit > 9 ? doubledDigit - 9 : doubledDigit
            } else {
                sum += digit
            }
        }

        return sum % 10 == 0
    }

    func mask(
        mask: String,
        capitalize: Bool = false,
        maskNumber: Character = "#",
        maskLetter: Character = "A",
        allowMix: Bool = false
    ) -> String {
        var unmasked = self
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

    func matchesRegex(
        regex: String,
        defaultVal: Bool = false
    ) -> Bool {
        do {
            let regex = try NSRegularExpression(
                pattern: regex,
                options: [.caseInsensitive]
            )
            let nsString = self as NSString
            let match = regex.firstMatch(
                in: self,
                options: [],
                range: NSMakeRange(0, nsString.length)
            )
            return (match != nil)
        } catch {
            return defaultVal
        }
    }
}

internal extension UITextField {
    func maskInput(
        mask: String = "#### #### #### ####",
        maskNumber: Character = "#",
        maskLetter: Character = "A",
//        textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String,
        capitalize: Bool = false,
        allowMix: Bool = false,
        allowMixFormatting: Bool = true
    ) -> Bool {
        if self.text == nil {
            return true
        }
        let currentText = self.text ?? ""
        // Check if it is backspace without selection
        var isBackspace = string.isEmpty && range.length == 1

        if isBackspace {
            if let selectedRange = self.selectedTextRange {
                let userSelectedRangeLength = self.offset(
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

        let uCurrentText = currentText.keepLN()

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

        let newMaskedText = newUnmaskedText.mask(
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

        self.text = newMaskedText

        let newEnd = targetEnd + targetEndShift

        if let newPosition = self.position(
            from: self.beginningOfDocument,
            offset: newEnd
        ) {
            // Give it a few moment to update the textfield if it's from pasting, otherwise cursor won't update correctly
            if string.count > 1 {
                DispatchQueue.main.async {
                    self.selectedTextRange = self.textRange(
                        from: newPosition,
                        to: newPosition
                    )
                }
            } else {
                // Regular input does not need delay
                self.selectedTextRange = self.textRange(
                    from: newPosition,
                    to: newPosition
                )
            }
        }

        return false
    }
}

internal let kCardRegex = "^(?:(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(6(?:011|5[0-9]{2})[0-9]{12})|(3[47][0-9]{13})|(3(?:0[0-5]|[68][0-9])[0-9]{11})|((?:2131|1800|35[0-9]{3})[0-9]{11})|(62[0-9]{14}))$"

internal func tBool(_ value: Any?) -> Bool {
    if value is Int {
        return value as! Int > 0
    }
    if value is Bool {
        return value as! Bool
    }
    if value is String {
        return !(value as! String).isEmpty
    }
    return false
}

internal func tStringOrNil(_ value: Any?) -> String? {
    let stringVal: String = value as? String ?? ""
    if stringVal.isEmpty {
        return nil
    }
    return stringVal
}

internal func tString(_ value: Any?) -> String {
    return value as? String ?? ""
}

internal func tFloatOrNil(_ value: Any?) -> Float? {
    return value as? Float
}

internal func tFloat(_ value: Any?) -> Float {
    return value as? Float ?? 0.0
}

internal func tIntOrNil(_ value: Any?) -> Int? {
    return value as? Int
}

internal func tInt(_ value: Any?) -> Int {
    return value as? Int ?? 0
}
