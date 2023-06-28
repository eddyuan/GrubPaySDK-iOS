//
//  GPCardOverlay.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-16.
//

import Foundation
import UIKit

class GPCardOverlay: UIView {
    open var cutout: CGRect? {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isOpaque = false
        backgroundColor = .clear
    }

//    override func draw(_ rect: CGRect) {
//        guard let cutout = cutout else {
//            return
//        }
//
//        // Create the background path
//        let backgroundPath = UIBezierPath(rect: rect)
//
//        // Create the cutout path
//        let cornerRadius: CGFloat = 10.0
//        let cutoutPath = UIBezierPath(
//            roundedRect: cutout,
//            byRoundingCorners: .allCorners,
//            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
//        )
//
//        // Add the cutout path as a subpath of the background path
//        backgroundPath.append(cutoutPath)
//
//        // Set up the gradient for the cutout
//        let gradient = CGGradient(
//            colorsSpace: CGColorSpaceCreateDeviceRGB(),
//            colors: [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor] as CFArray,
//            locations: [0.3, 1.0]
//        )
//
//        // Get the center point of the cutout rect
//        let center = CGPoint(x: cutout.midX, y: cutout.midY)
//
//        // Calculate the radius of the largest circle that fits within the cutout rect
//        let radius = sqrt(pow(cutout.width, 2) + pow(cutout.height, 2)) / 2.0
//
//        // Create a radial gradient from the center to the outer edge of the cutout
//        let gradientStartRadius = radius * 0.5
//        let gradientEndRadius = radius
//
//        // Create a context for drawing the gradient
//        guard let context = UIGraphicsGetCurrentContext() else {
//            return
//        }
//
//        // Save the current graphics state
//        context.saveGState()
//
//        // Add the cutout path as a clipping region
//        backgroundPath.addClip()
//
//        // Draw the gradient within the cutout area
//        context.drawRadialGradient(
//            gradient!,
//            startCenter: center,
//            startRadius: gradientStartRadius,
//            endCenter: center,
//            endRadius: gradientEndRadius,
//            options: [.drawsAfterEndLocation]
//        )
//
//        // Restore the graphics state
//        context.restoreGState()
//
//        // Fill the background with the black color
//        UIColor.black.withAlphaComponent(0.5).setFill()
//        backgroundPath.fill()
//    }

    override func draw(_ rect: CGRect) {
        guard let cutout = cutout else {
            return
        }
        UIColor.black.withAlphaComponent(0.5).setFill()
        UIRectFill(rect)
        let cornerRadius: CGFloat = 10.0
        let cutoutPath = UIBezierPath(
            roundedRect: cutout,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        UIColor.clear.setFill()
        cutoutPath.fill(with: .clear, alpha: 1.0)
        cutoutPath.addClip()
    }
}
