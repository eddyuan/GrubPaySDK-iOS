//
//  GPRadioButton.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-16.
//

import Foundation

import UIKit

private extension UIFont {
    func boldFont() -> UIFont? {
        guard let boldDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) else {
            return nil
        }

        return UIFont(descriptor: boldDescriptor, size: pointSize)
    }
}

class GPRadioButton: UIButton {
    let controller: GPFormController!

    override var isEnabled: Bool {
        didSet {
            gpRadioDot.isEnabled = isEnabled
        }
    }

    private var layedOut = false

    private lazy var gpRadioDot: GPRadioDot = {
        let dot = GPRadioDot(
            style: controller.style
        )
        dot.isEnabled = isEnabled
        return dot
    }()

    private func updateDotColor() {
        gpRadioDot.style = controller.style
    }

    private func updateTitleStyle() {
        setTitleColor(
            controller.style.accentColor,
            for: .selected
        )
        setTitleColor(
            controller.style.labelStyle.color,
            for: .normal
        )
        updateFont()
    }

    private func setDotFrame() {
        gpRadioDot.frame = CGRect(
            x: 0,
            y: 0,
            width: controller.style.dotSize,
            height: frame.height
        )
    }

    // Initialization
    init(controller: GPFormController) {
        self.controller = controller
        super.init(frame: .zero)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        addSubview(gpRadioDot)
        updateTitleStyle()
        // Set the minimum width constraint
        let minWidthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 120)

        // Add the constraint to the view
        addConstraint(minWidthConstraint)
    }

    override var isSelected: Bool {
        didSet {
            gpRadioDot.isSelected = isSelected
            updateFont()
        }
    }

    private func updateFont() {
        if isSelected {
            titleLabel?.font = controller.style.font.boldFont()
        } else {
            titleLabel?.font = controller.style.font
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        contentHorizontalAlignment = .left
        contentEdgeInsets = UIEdgeInsets(
            top: 8,
            left: controller.style.dotSize + 6,
            bottom: 8,
            right: 12
        )
        setDotFrame()
        if !layedOut {
            layedOut = true
        }
    }
}
