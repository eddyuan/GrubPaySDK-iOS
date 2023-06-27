//
//  GrubPayButton.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-23.
//

import Foundation
import UIKit

internal class GrubPayButton: UIButton {
    private var activityIndicator: UIActivityIndicatorView = .init()

    var isLoading: Bool = false {
        didSet {
            updateView()
        }
    }

    private func updateView() {
        if isLoading {
            activityIndicator.startAnimating()
            titleLabel?.alpha = 0
//            imageView?.alpha = 0
            isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            titleLabel?.alpha = 1
//            imageView?.alpha = 0
            isEnabled = true
        }
    }

    private func commonInit() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        if #available(iOS 13.0, *) {
            activityIndicator.style = .medium
        }
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func setBackground(_ color: UIColor, for state: UIControl.State) {
        setBackgroundImage(color.createOnePixelImage(), for: state)
    }
}

private extension UIColor {
    func createOnePixelImage() -> UIImage? {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
