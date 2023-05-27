//
//  GPInput+Card.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation

class GPInputCard: GPInput {
    // MARK: Validators

    var cleanText: String {
        return super.text?.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        ) ?? ""
    }

    override func onEditChange() {
        super.onEditChange()
        setCardBrand()
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

    // MARK: Datas

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

    private func setCardBrand() {
        let cardNumber = super.text
        guard cardNumber != nil else {
            cardType = .unknown
            return
        }

        let numberOnly = cardNumber!.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )

        for card in GPCardType.allCards {
            if matchesRegex(
                regex: card.regex,
                text: numberOnly
            ) {
                cardType = card
                return
            }
        }
        cardType = .unknown
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
        super.placeholder = "1234 5678 9012 3456"
        super.autocorrectionType = .no
        super.autocapitalizationType = .none
        super.keyboardType = .numberPad
//        super.addTarget(
//            self,
//            action: #selector(textFieldDidChange),
//            for: .editingChanged
//        )
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

    override init(controller: GPFormController) {
        super.init(controller: controller)
        initField()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        layoutCardImage()
    }
}

extension GPInputCard: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return GPInputUtil.maskInput(
            mask: "#### #### #### ####",
            textField: textField,
            shouldChangeCharactersIn: range,
            replacementString: string,
            allowMix: false
        )
    }
}

// This is for form controller
extension GPInputCard {
    override var valid: Bool {
        if controller.config?.mode == .ach {
            return true
        }

        let cardNumber = super.text
        guard cardNumber != nil else {
            return false
        }

        let numberOnly = cardNumber!.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )

        let validatorRegex = "^(?:(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(6(?:011|5[0-9]{2})[0-9]{12})|(3[47][0-9]{13})|(3(?:0[0-5]|[68][0-9])[0-9]{11})|((?:2131|1800|35[0-9]{3})[0-9]{11})|(62[0-9]{14}))$"
        let defaultValid = numberOnly.count > 13 && numberOnly.count < 17

        return matchesRegex(
            regex: validatorRegex,
            text: numberOnly,
            defaultVal: defaultValid
        )
    }

    override func doValidate(
        onSuccess: @escaping (_ param: [String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        if controller.config?.mode != .card {
            onSuccess([:])
            return
        }
        updateErrorState()
        if valid {
            onSuccess(["cardNum": cleanText])
        } else {
            onError("Card Number")
        }
    }
}
