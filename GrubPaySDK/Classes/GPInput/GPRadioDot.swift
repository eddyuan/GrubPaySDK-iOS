//
//  GPRadioDot.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-17.
//

import Foundation
import UIKit

class GPCheckmarkView: UIView {
    var isEnabled: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    var style: GPInputStyle! {
        didSet {
            setNeedsDisplay()
        }
    }

    var currentColor: UIColor {
        return isEnabled ? style.accentColor : style.placeholderColor
    }

    init(
        style: GPInputStyle = .init()
    ) {
        self.style = style
        super.init(frame: .zero)
        backgroundColor = UIColor.clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Define the checkmark path
        let checkmarkPath = UIBezierPath()
        checkmarkPath.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.5))
        checkmarkPath.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.68))
        checkmarkPath.addLine(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.28))
        checkmarkPath.lineWidth = 2.0

        // Set the stroke color
        currentColor.setStroke()

        // Draw the checkmark path
        checkmarkPath.stroke()
    }
}

class GPRadioDot: UIView {
    var style: GPInputStyle! {
        didSet {
            innerCheck.style = style
        }
    }

    var dotSize: CGFloat {
        return style.dotSize
    }

    private var currentColor: UIColor {
        return isEnabled && isSelected ? style.accentColor : style.placeholderColor
    }

    private var currentInnerColor: UIColor {
        return isSelected ? currentColor : UIColor.clear
    }

    var isEnabled: Bool = true {
        didSet {
            innerCheck.isEnabled = isEnabled
            paintDots(true)
        }
    }

    var isSelected = false {
        didSet {
            paintDots(true)
        }
    }

    var useCheck: Bool = false {
        didSet {
            paintInnerDot()
        }
    }

    private var layedOut = false
    private let circleLineWidth: CGFloat = 2.0
    private var outterSize: CGFloat {
        return dotSize
    }

    private var innerSize: CGFloat {
        return (dotSize - 10)
    }

    private lazy var innerDot: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    private lazy var innerCheck: GPCheckmarkView = {
        let v = GPCheckmarkView(style: style)
        v.isEnabled = isEnabled
        return v
    }()

    private lazy var outterDot: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.addSubview(innerDot)
        v.addSubview(innerCheck)
        return v
    }()

    private func paintOutterDot() {
        let targetColor = currentColor
        let targetFrame = CGRect(
            x: 0,
            y: (frame.height - outterSize) / 2,
            width: outterSize,
            height: outterSize
        )
        if outterDot.frame != targetFrame {
            outterDot.frame = targetFrame
        }
        outterDot.layer.borderWidth = circleLineWidth
        outterDot.layer.borderColor = targetColor.cgColor
        outterDot.layer.cornerRadius = outterSize / 2
    }

    private func paintInnerDot() {
        if useCheck {
            innerDot.isHidden = true
            innerCheck.isHidden = !isSelected
            innerCheck.frame = CGRect(
                x: 0, y: 0, width: outterSize, height: outterSize
            )
        } else {
            innerCheck.isHidden = true
            innerDot.isHidden = false
            let targetColor = isSelected ? currentColor : UIColor.clear
            let targetSize = isSelected ? innerSize : 0
            innerDot.frame = CGRect(
                x: (outterSize - targetSize) / 2,
                y: (outterSize - targetSize) / 2,
                width: targetSize,
                height: targetSize
            )
            innerDot.backgroundColor = targetColor
            innerDot.layer.cornerRadius = targetSize / 2
        }
    }

    private func paintDots(_ animate: Bool = false) {
        let targetDuration = animate ? 0.05 : 0
        UIView.animate(
            withDuration: targetDuration,
            delay: 0,
            options: .curveEaseInOut
        ) {
            self.paintOutterDot()
            self.paintInnerDot()
        }
    }

    private func initView() {
        addSubview(outterDot)
        isUserInteractionEnabled = false
    }

    required init(
        style: GPInputStyle = .init()
    ) {
        self.style = style
        super.init(frame: .zero)
        initView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        paintDots(layedOut)
        if !layedOut {
            layedOut = true
        }
    }
}
