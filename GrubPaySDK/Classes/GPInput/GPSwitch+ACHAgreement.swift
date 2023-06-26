//
//  GPSwitch+ACHAgreement.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-16.
//

import Foundation

private extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        // let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
        // (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        // let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
        // locationOfTouchInLabel.y - textContainerOffset.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

class GPSwitchACHAgreement: UIView {
    let controller: GPFormController!

    private var isEnabled: Bool {
        return controller.isEnabled
    }

    private var agreeToAch: Bool {
        return controller.agreeToAch
    }

    private lazy var gpRadioDot: GPRadioDot = {
        let d = GPRadioDot(style: controller.style)
        d.useCheck = true
        d.isSelected = agreeToAch
        d.isEnabled = isEnabled
        return d
    }()

    private var layedOut = false

    private var viewHeight: CGFloat {
        return controller.style.font.lineHeight + 16
    }

    private let tas = "ACH Agreement"

    private lazy var text: String = "Agree to \(tas)"

    private lazy var tasRange = (text as NSString).range(
        of: tas
    )

    @objc func tapLabel(gesture: UITapGestureRecognizer) {
        if gesture.didTapAttributedTextInLabel(
            label: titleLabel,
            inRange: tasRange
        ) {
            controller.showAchAgreement()
        } else {
            toggleSelect()
        }
    }

    private func toggleSelect() {
        if !isEnabled {
            return
        }
        controller.agreeToAch = !controller.agreeToAch
    }

    private lazy var titleLabel = {
        let label = UILabel()
        label.text = text
        label.font = controller.style.font
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(tapLabel(gesture:))
        )
        tapGesture.cancelsTouchesInView = true
        label.addGestureRecognizer(tapGesture)
        return label
    }()

    private func updateLabelTextColor() {
        titleLabel.textColor = isEnabled ? controller.style.color : controller.style.placeholderColor
        let underlineAttriString = NSMutableAttributedString(string: text)
        underlineAttriString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: isEnabled ? controller.style.accentColor : controller.style.placeholderColor,
            range: tasRange
        )
        titleLabel.attributedText = underlineAttriString
    }

    private func setDotFrame() {
        super.frame = CGRect(
            x: frame.origin.x,
            y: frame.origin.y,
            width: frame.size.width,
            height: viewHeight
        )
        let fittedWidth = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: titleLabel.frame.height)
        ).width
        gpRadioDot.frame = CGRect(
            x: 0,
            y: 0,
            width: controller.style.dotSize,
            height: viewHeight
        )
        titleLabel.frame = CGRect(
            x: controller.style.dotSize + 6,
            y: 0,
            width: fittedWidth,
            height: viewHeight
        )
    }

    private func commonInit() {
        controller.addField(self)
        updateLabelTextColor()
        addSubview(gpRadioDot)
        addSubview(titleLabel)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: viewHeight)
        addConstraint(heightConstraint)
        isUserInteractionEnabled = true
    }

    required init(controller: GPFormController) {
        self.controller = controller

        super.init(frame: .zero)
        commonInit()
    }

    deinit {
        controller.removeObs(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func animateOpacity(_ value: CGFloat) {
        alpha = value
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        setDotFrame()
        if !layedOut {
            layedOut = true
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        toggleSelect()
    }
}

extension GPSwitchACHAgreement: GPFormObs {
    var valid: Bool {
        return true
    }

    func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        onSuccess([:])
    }

    func isEnabledDidChange(_ isEnabled: Bool) {
        DispatchQueue.main.async {
            self.updateLabelTextColor()
            self.gpRadioDot.isEnabled = self.isEnabled
        }
    }

    func styleDidChange() {
        DispatchQueue.main.async {
            self.updateLabelTextColor()
            self.gpRadioDot.style = self.controller.style
        }
    }

    func didChangeAchAgree(_ val: Bool) {
        gpRadioDot.isSelected = val
    }
}
