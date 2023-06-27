//
//  GPInput.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-04.
//

import Foundation
import UIKit

class GPInput: UITextField {
    // MARK: Properties

    let controller: GPFormController!

    func onEditChange() {
        if errorMessage != nil {
            errorMessage = nil
        }
        controller.onEditChange()
    }

    @objc func onTextChange() {
        onEditChange()
    }

    override var text: String? {
        didSet {
            onEditChange()
        }
    }

    open var errorMessage: String? {
        didSet {
            updateAllStyles()
        }
    }

    var gpInputStyle: GPInputStyle {
        return controller.style
    }

    open var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }

    open var trailingWidth: CGFloat = 0 {
        didSet {
            updateAllStyles()
        }
    }

    open var leadingWidth: CGFloat = 0 {
        didSet {
            updateAllStyles()
        }
    }

    private var tempPlaceholder: String?

    override var placeholder: String? {
        get {
            return (hasLabel || isEditing) ? tempPlaceholder : titleText
        }
        set {
            tempPlaceholder = newValue
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateAllStyles()
        }
    }

    // MARK: Getters

    var expectedIconSize: (
        h: CGFloat,
        t: CGFloat,
        pl: CGFloat,
        pr: CGFloat
    ) {
        var maxH = bounds.height
        if !gpLabelStyle.floating {
            maxH -= labelHeight
        }
        let h = min(24, maxH - 12)
        var t = (maxH - h) / 2
        if !gpLabelStyle.floating {
            t += labelHeight
        }
        var pr = 0.0
        var pl = 0.0
        if hasOutline {
            pl += inputPadding.left
            pr += inputPadding.right
        }
        return (h, t, pl, pr)
    }

    private var gpBorderStyle: GPBorderStyle {
        return gpInputStyle.borderStyle
    }

    var gpLabelStyle: GPLabelStyle {
        return gpInputStyle.labelStyle
    }

    var hasOutline: Bool {
        return !hasUnderline && (gpBorderStyle.width > 0 || gpBorderStyle.activeWidth > 0)
    }

    private var hasUnderline: Bool {
        return gpBorderStyle.underline
    }

    private var hasLabel: Bool {
        return !gpLabelStyle.noLabel
    }

    private var hasError: Bool {
        return (errorMessage?.count ?? 0) > 0 && isEnabled
    }

    private var _labelFont: UIFont {
        if floated {
            return gpLabelStyle.font
        }
        return gpInputStyle.font
    }

    private var _labelColor: UIColor {
        if hasError {
            if floated {
                if isEditing {
                    return gpInputStyle.errorColor.withAlphaComponent(0.7)
                }
                return gpInputStyle.errorColor.withAlphaComponent(0.5)
            }
            return gpInputStyle.errorColor
        }
        if floated {
            if isEditing {
                return gpLabelStyle.activeColor
            }
            return gpLabelStyle.color
        }
        return gpInputStyle.color.withAlphaComponent(0.7)
    }

    private var _placeholderColor: UIColor {
        if !floated {
            return UIColor.clear
        }
        return gpInputStyle.placeholderColor
    }

    private var _borderWidth: CGFloat {
        if hasOutline {
            if isEditing {
                return gpBorderStyle.activeWidth
            }
            return gpBorderStyle.width
        }
        return 0
    }

    private var _borderColor: UIColor {
        if hasError {
            return gpInputStyle.errorColor
        }
        if isEditing {
            return gpBorderStyle.activeColor
        }
        return gpBorderStyle.color
    }

    // MARK: States

    private let _animationDuration = 0.2
    private var _layedOut: Bool = false

    // MARK: StyleSetter

    private func updateAllStyles(_ animate: Bool = false) {
        updateInputStyle()
        updateLabelStyle(animate)
        updatePlaceholder()
        updateBorderStyle(animate)
        updateLineStyle(animate)
        alpha = isEnabled ? 1 : 0.5
    }

    private func updateInputStyle() {
        font = gpInputStyle.font
        textColor = hasError ? gpInputStyle.errorColor : gpInputStyle.color
    }

    private func updateLabelStyle(_ animate: Bool = false) {
        if hasLabel {
            titleLabel.isHidden = false
            titleLabel.isUserInteractionEnabled = !gpLabelStyle.floating
            let targetDuration = animate ?_animationDuration : 0
            let targetFrame = buildLabelRect()
            if titleLabel.font != _labelFont {
                titleLabel.font = _labelFont
            }

            if titleLabel.textColor != _labelColor {
                UIView.transition(
                    with: titleLabel,
                    duration: targetDuration,
                    options: .curveEaseInOut
                ) {
                    self.titleLabel.textColor = self._labelColor
                }
            }
            if titleLabel.frame != targetFrame {
                UIView.animate(withDuration: targetDuration, delay: 0, options: .curveEaseInOut) {
                    self.titleLabel.frame = targetFrame
                }
            }

        } else {
            titleLabel.isHidden = true
            titleLabel.isUserInteractionEnabled = false
        }
    }

    fileprivate func updatePlaceholder() {
        #if swift(>=4.2)
            attributedPlaceholder = NSAttributedString(
                string: placeholder ?? "",
                attributes: [
                    NSAttributedString.Key.foregroundColor: _placeholderColor
                ]
            )
        #elseif swift(>=4.0)
            attributedPlaceholder = NSAttributedString(
                string: placeholder ?? "",
                attributes: [
                    NSAttributedStringKey.foregroundColor: _placeholderColor
                ]
            )
        #else
            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSForegroundColorAttributeName: _placeholderColor]
            )
        #endif
    }

    fileprivate func updateBorderStyle(_ animate: Bool = false) {
        let targetDuration = animate ? _animationDuration : 0
        let targetWidth = _borderWidth
        let targetColor = hasOutline ? _borderColor.cgColor : UIColor.clear.cgColor
        let targetBgColor = gpInputStyle.backgroundColor.cgColor
        let targetRadius = gpBorderStyle.radius
        let targetFrame = buildBorderRect()

        UIView.animate(withDuration: targetDuration, delay: 0, options: .curveEaseInOut) {
            if self.borderView.layer.borderColor != targetColor {
                self.borderView.layer.borderColor = targetColor
            }
            if self.borderView.layer.borderWidth != targetWidth {
                self.borderView.layer.borderWidth = targetWidth
            }
            if self.borderView.layer.backgroundColor != targetBgColor {
                self.borderView.layer.backgroundColor = targetBgColor
            }
            if self.borderView.layer.cornerRadius != targetRadius {
                self.borderView.layer.cornerRadius = targetRadius
            }
            if self.borderView.frame != targetFrame {
                self.borderView.frame = targetFrame
            }
        }
    }

    fileprivate func updateLineStyle(_ animate: Bool = false) {
        if hasUnderline {
            lineView.isHidden = false
            let targetDuration = animate ? _animationDuration : 0
            let targetColor = _borderColor.cgColor
            UIView.animate(withDuration: targetDuration, delay: 0, options: .curveEaseInOut) {
                self.lineView.layer.frame = self.buildLineRect()
                self.lineView.layer.backgroundColor = targetColor
            }
        } else {
            lineView.isHidden = true
        }
    }

    // MARK: Views

    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return titleLabel
    }()

    fileprivate lazy var borderView: UIView = {
        let borderView = UIView()
        borderView.isUserInteractionEnabled = false
        return borderView
    }()

    fileprivate lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.isUserInteractionEnabled = false
        return lineView
    }()

    fileprivate func commonInit() {
        controller.addField(self)
        isEnabled = controller.isEnabled
        insertSubview(borderView, at: 0)
        borderView.addSubview(lineView)
        addSubview(titleLabel)
    }

    // MARK: Overrides

    public init(controller: GPFormController) {
        self.controller = controller
        super.init(frame: .zero)
        addTarget(self, action: #selector(onTextChange), for: .editingChanged)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        controller.removeObs(self)
    }

    // MARK: Getters

    private var titleHeight: CGFloat {
        return hasLabel ? gpLabelStyle.font.lineHeight : 0
    }

    var labelHeight: CGFloat {
        return hasLabel ? (titleHeight + labelPadding.top + labelPadding.bottom) : 0
    }

    private var textHeight: CGFloat {
        return gpInputStyle.font.lineHeight + (gpLabelStyle.floating ? 8.0 : 18.0)
    }

    private var inputHeight: CGFloat {
        return textHeight + inputPadding.top + inputPadding.bottom
    }

    private var viewHeight: CGFloat {
        return labelHeight + inputHeight
    }

    private var floated: Bool {
        return !gpLabelStyle.floating || isEditing || (text != "" && text != nil)
    }

    private var labelPadding: UIEdgeInsets {
        if gpLabelStyle.floating {
            return UIEdgeInsets(
                top: gpInputStyle.padding.top,
                left: gpInputStyle.padding.left,
                bottom: 0,
                right: gpInputStyle.padding.right
            )
        }
        return UIEdgeInsets(
            top: 0,
            left: hasOutline ? 2 : gpInputStyle.padding.left,
            bottom: hasOutline ? 4 : 0,
            right: hasOutline ? 2 : gpInputStyle.padding.right
        )
    }

    var inputPadding: UIEdgeInsets {
        if gpLabelStyle.floating {
            return UIEdgeInsets(
                top: 0,
                left: gpInputStyle.padding.left,
                bottom: gpInputStyle.padding.bottom,
                right: gpInputStyle.padding.right
            )
        }
        return gpInputStyle.padding
    }

    // MARK: Build Rects

    fileprivate func buildInputRect(_ superRect: CGRect) -> CGRect {
        let inset = UIEdgeInsets(
            top: labelHeight + inputPadding.top,
            left: gpInputStyle.padding.left + leadingWidth,
            bottom: gpInputStyle.padding.bottom,
            right: gpInputStyle.padding.right + trailingWidth
        )
        return superRect.inset(by: inset)
    }

    fileprivate func buildLabelRect() -> CGRect {
        if floated {
            return CGRect(
                x: labelPadding.left + (hasOutline ? 0 : leadingWidth),
                y: labelPadding.top,
                width: bounds.size.width - labelPadding.left - labelPadding.right,
                height: titleHeight
            )
        }

        let inset = UIEdgeInsets(
            top: inputPadding.top,
            left: inputPadding.left + leadingWidth,
            bottom: inputPadding.bottom,
            right: inputPadding.right + trailingWidth
        )
        return bounds.inset(by: inset)
    }

    fileprivate func buildBorderRect() -> CGRect {
        if !gpLabelStyle.floating {
            return CGRect(x: 0, y: labelHeight, width: bounds.size.width, height: bounds.height - labelHeight)
        }
        return CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
    }

    fileprivate func buildLineRect() -> CGRect {
        let borderRect = buildBorderRect()
        let targetWidth = isEditing ? gpBorderStyle.activeWidth : gpBorderStyle.width
        return CGRect(x: 0, y: borderRect.size.height - targetWidth, width: borderRect.size.width, height: targetWidth)
    }

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.textRect(forBounds: bounds)
        return buildInputRect(superRect)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        updateAllStyles(_layedOut)
        if !_layedOut {
            _layedOut = true
        }
    }

//    @discardableResult
//    override open func becomeFirstResponder() -> Bool {
//        let result = super.becomeFirstResponder()
//        updateAllStyles(true)
//        return result
//    }
//
//    @discardableResult
//    override open func resignFirstResponder() -> Bool {
//        let result = super.resignFirstResponder()
//        updateAllStyles(true)
//        return result
//    }

    override open var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.size.width, height: viewHeight)
    }
}

extension GPInput: GPFormObs {
    func configDidChange() {
        DispatchQueue.main.async {
            self.updateAllStyles()
        }
    }

    func countryDidChange() {}

    func doValidate(
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        onError("Not implemented")
    }

    var valid: Bool {
        return false
    }

    func isEnabledDidChange(_ isEnabled: Bool) {
        DispatchQueue.main.async {
            [weak self] in
            self?.isEnabled = isEnabled
        }
    }

    func didScan(_ cardNumber: String?, _ expiryDate: String?) {}
    func didFinishField(_ val: Int) {}
}
