
//
//  ViewController.swift
//  GrubPaySDK
//
//  Created by 43017558 on 04/21/2023.
//  Copyright (c) 2023 43017558. All rights reserved.
//
import UIKit

public class GrubPayElement: UIView {
    // MARK: Style Options

    open var inputStyle: GPInputStyle = .init() {
        didSet {
            cardForm.inputStyle = inputStyle
        }
    }

    // MARK: ServerProperties

    fileprivate var isAch: Bool = false
    fileprivate var requireName: Bool = false
    fileprivate var initialized: Bool = false
    fileprivate var paid: Bool = false

    // MARK: Validates

    fileprivate var validCardNumber: Bool = false
    fileprivate var validCardHolder: Bool = false
    fileprivate var validCountry: Bool = false
    fileprivate var validZip: Bool = false

    // MARK: Hierarchy

    private lazy var cardForm: GPCardForm = {
        let cardForm = GPCardForm()
        cardForm.inputStyle = inputStyle
        return cardForm
    }()

    @objc func testButtonClicked() {}

    private lazy var testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test", for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 84)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(testButtonClicked), for: .touchUpInside)
        return button
    }()

    // MARK: Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupAllViews()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAllViews()
    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    // MARK: Setup

    private func setupAllViews() {
        setupViewHierarchy()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }

    private func setupViewHierarchy() {
        addSubview(cardForm)
    }
}
