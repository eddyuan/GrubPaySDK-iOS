//
//  GPInput+Card.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-08.
//

import Foundation
import UIKit

class GPInputCard: GPInput {
    // MARK: Validators

    private var cleanText: String {
        return super.text?.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        ) ?? ""
    }

    private var isCardNumberFromScan = false

    override func onEditChange() {
        super.onEditChange()
        setCardBrand()
        if text?.count == 19 {
            if !isCardNumberFromScan && valid {
                onFinishField()
            }
        } else {
            isCardNumberFromScan = false
        }
    }

    override func didScan(_ cardNumber: String?, _ expiryDate: String?) {
        if let cardNumber = cardNumber {
            DispatchQueue.main.async {
                [weak self] in
                self?.isCardNumberFromScan = true
                self?.text = cardNumber.mask(mask: "#### #### #### ####")
            }
        } else {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
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

    private var cardBrand: GrubPayCardBrand = .unknown {
        didSet {
            toggleCameraButton()
//            let img = UIImage(
//                named: cardBrand.imageName,
//                in: Bundle(for: type(of: self)),
//                compatibleWith: nil
//            )
            let img = UIImage(
                named: cardBrand.imageName,
                in: Bundle.module,
                compatibleWith: nil
            )
            UIView.transition(
                with: cardImage,
                duration: 0.2,
                options: .transitionCrossDissolve
            ) {
                self.cardImage.image = img
            }
            controller.cardBrand = cardBrand
        }
    }

    private func toggleCameraButton() {
        if #available(iOS 13.0, *), cardBrand == .unknown {
            scanButton.isHidden = false
            cardImage.isHidden = true
        } else {
            scanButton.isHidden = true
            cardImage.isHidden = false
        }
    }

    private func setCardBrand() {
        DispatchQueue.main.async {
            [weak self] in
            let cardNumber = self?.text
            guard cardNumber != nil else {
                self?.cardBrand = .unknown
                return
            }

            let numberOnly = cardNumber?.replacingOccurrences(
                of: "[^0-9]",
                with: "",
                options: .regularExpression
            ) ?? ""

            for card in GrubPayCardBrand.allCards {
                if numberOnly.matchesRegex(
                    regex: card.regex
                ) {
                    self?.cardBrand = card
                    return
                }
            }
            self?.cardBrand = .unknown
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
        super.returnKeyType = .next
        super.addSubview(cardImage)
        super.addSubview(scanButton)
        toggleCameraButton()
    }

    @objc func scanCard() {
        controller.scanCard()
    }

    private lazy var cameraImage: UIImage? = {
        if #available(iOS 13.0, *) {
            let img = UIImage(systemName: "camera")
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20)
            let resizedImage = img?.withRenderingMode(.alwaysOriginal).applyingSymbolConfiguration(symbolConfiguration)?.withTintColor(controller.style.accentColor)
            return resizedImage
        }
        return nil
    }()

    private lazy var scanButton: UIButton = {
        let b = UIButton()
        b.setImage(cameraImage, for: .normal)
        b.setTitleColor(UIColor.systemBlue, for: .normal)
        b.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.5), for: .highlighted)
        b.addTarget(self, action: #selector(scanCard), for: .touchUpInside)
        return b
    }()

    private lazy var cardImage: UIImageView = {
        let img = UIImage(
            named: cardBrand.imageName,
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
        scanButton.frame = CGRect(
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
        return textField.maskInput(
            mask: "#### #### #### ####",
            shouldChangeCharactersIn: range,
            replacementString: string,
            allowMix: false
        )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onFinishField()
        return true
    }
}

// This is for form controller
extension GPInputCard {
    override var valid: Bool {
        if controller.config?.channel == .ach {
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

        let defaultValid = numberOnly.count > 13 && numberOnly.count < 17
        return numberOnly.matchesRegex(
            regex: kCardRegex,
            defaultVal: defaultValid
        )
    }

    override func doValidate(
        onSuccess: @escaping (_ param: [String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        if controller.config?.channel != .card {
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

    private func onFinishField() {
        controller.onFinishField(GPInputType.card)
    }

    override func didFinishField(_ val: Int) {
        if GPInputType(rawValue: val) == .name {
            DispatchQueue.main.async {
                [weak self] in
                let _ = self?.becomeFirstResponder()
            }
        }
    }
}
