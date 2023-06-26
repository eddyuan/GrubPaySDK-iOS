//
//  GPScannerConfig.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-19.
//

import Foundation

class GPScannerConfig {
    static let placeholderOpacity: Float = 0.4
    static let cardNumberPlaceholder = "####  ####  ####  ####"
    static let cardDatePlaceholder = "MM/YY"
    static let buttonSize: CGFloat = 84.0

    // The edge space for button to the bound
    static let buttonPaddingEdge: CGFloat = 60.0

    // For all 4 sides of which the card container is in
    static let cardPaddingEdge: CGFloat = 36.0

    // Define max absolute width of the card area
    static let maxCardWidth: CGFloat = 460.0

    // For 3 sizes of the hint, from sides, and between card
    static let hintPadding: CGFloat = 16.0

    static let cardRatio = 0.631

    static let minTries = 1

    // When reaches this confirmation tries, confirm is called
    static let triesForConfirm = 5
}
