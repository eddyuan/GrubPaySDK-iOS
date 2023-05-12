//
//  GPInput+Card.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation

class GPInputCard: GPInput {
    var onChanged: ((_ valid: Bool, _ cardType: GPCardType?) -> Void)?

    private var cardType: GPCardType = .unknown {
        didSet {
            let img = UIImage(
                named: cardType.imageName,
                in: Bundle(for: type(of: self)),
                compatibleWith: nil
            )
            UIView.transition(
                with: cardImage,
                duration: 0.2,
                options: .transitionCrossDissolve
            ) {
                self.cardImage.image = img
            }
        }
    }

    var valid: Bool = false {
        didSet {
            if valid && super.errorMessage != nil {
                super.errorMessage = nil
            }
            onChanged?(valid, cardType)
        }
    }

    @objc func textFieldDidChange() {
        validateCreditCardFormat()
        super.errorMessage = nil
    }

    private func validateCreditCardFormat() {
        let cardNumber = super.text
        guard cardNumber != nil else {
            cardType = .unknown
            valid = false
            return
        }

        let numberOnly = cardNumber!.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )

        var type: GPCardType = .unknown

        for card in GPCardType.allCards {
            if matchesRegex(
                regex: card.regex,
                text: numberOnly
            ) {
                type = card
                break
            }
        }

        let validatorRegex = "^(?:(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(6(?:011|5[0-9]{2})[0-9]{12})|(3[47][0-9]{13})|(3(?:0[0-5]|[68][0-9])[0-9]{11})|((?:2131|1800|35[0-9]{3})[0-9]{11})|(62[0-9]{14}))$"
        let defaultValid = numberOnly.count > 13 && numberOnly.count < 17

        cardType = type
        valid = matchesRegex(
            regex: validatorRegex,
            text: numberOnly,
            defaultVal: defaultValid
        )

        print(cardType)
        print(valid)
    }

    private func matchesRegex(
        regex: String,
        text: String,
        defaultVal: Bool = false
    ) -> Bool {
        do {
            let regex = try NSRegularExpression(
                pattern: regex,
                options: [.caseInsensitive]
            )
            let nsString = text as NSString
            let match = regex.firstMatch(
                in: text,
                options: [],
                range: NSMakeRange(0, nsString.length)
            )
            return (match != nil)
        } catch {
            return defaultVal
        }
    }

    private func initField() {
        super.delegate = self
        super.titleText = NSLocalizedString(
            "Card number",
            bundle: Bundle(for: type(of: self)),
            comment: ""
        )
        super.placeholder = "#### #### #### ####"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
        super.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )
        super.addSubview(cardImage)
    }

    private lazy var cardImage: UIImageView = {
        let img = UIImage(
            named: cardType.imageName,
            in: Bundle(for: type(of: self)),
            compatibleWith: nil
        )
        let imgView = UIImageView(image: img)
        return imgView
    }()

    private func layoutCardImage() {
        let (h, t, _, pr) = super.expectedIconSize
        let w = h * 1.4
        let x = bounds.width - w - pr
        super.trailingWidth = w + 6
        cardImage.frame = CGRect(
            x: x,
            y: t,
            width: w,
            height: h
        )
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

    override open func layoutSubviews() {
        super.layoutSubviews()
        layoutCardImage()
    }

    @discardableResult
    override open func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        super.errorMessage = valid ? nil : "Error"
        super.text = super.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
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

extension GPInputCard: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var replacementNumbers = string.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )

        guard CharacterSet(charactersIn: "0123456789").isSuperset(
            of: CharacterSet(charactersIn: replacementNumbers)
        ) else {
            return false
        }

        let maxNumberLength = 16

        var userSelectedRangeLength = 0

        if let selectedRange = textField.selectedTextRange {
            userSelectedRangeLength = textField.offset(
                from: selectedRange.start,
                to: selectedRange.end
            )
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
            if string.count > 1 {
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
}
