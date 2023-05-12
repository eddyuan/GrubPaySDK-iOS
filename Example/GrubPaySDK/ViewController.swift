//
//  ViewController.swift
//  GrubPaySDK
//
//  Created by 43017558 on 04/21/2023.
//  Copyright (c) 2023 43017558. All rights reserved.
//

import GrubPaySDK
import UIKit

class ViewController: UIViewController {
    // MARK: - Properties

//    private let grubpayInputField: GrubPayInputField = GrubPayInputField()

    private let grubpayElement: GrubPayElement = {
        let grubpayElement = GrubPayElement()
        grubpayElement.translatesAutoresizingMaskIntoConstraints = false
        return grubpayElement
    }()

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
//        grubpayElement.creditCardDataDelegate = grubpayElement
        view.addSubview(grubpayElement)
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {}
        configureUI()
    }

    // MARK: - Helper Methods

    private func configureUI() {
        NSLayoutConstraint.activate([
            grubpayElement.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            grubpayElement.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            grubpayElement.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            grubpayElement.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),

        ])
    }
}
