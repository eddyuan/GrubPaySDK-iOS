//
//  GPInputStyle.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-04.
//

import Foundation

public class GPBorderStyle {
    let color: UIColor
    let width: CGFloat
    let activeColor: UIColor
    let activeWidth: CGFloat
    let radius: CGFloat
    let underline: Bool

    fileprivate init(
        color: UIColor,
        width: CGFloat,
        activeColor: UIColor,
        activeWidth: CGFloat,
        radius: CGFloat,
        underline: Bool
    ) {
        self.color = color
        self.width = width
        self.activeColor = activeColor
        self.activeWidth = activeWidth
        self.radius = radius
        self.underline = underline
    }
}

public extension GPBorderStyle {
    static func noBorder(
        radius: CGFloat = 8
    ) -> GPBorderStyle {
        return GPBorderStyle(
            color: UIColor.clear,
            width: 0,
            activeColor: UIColor.clear,
            activeWidth: 0,
            radius: radius,
            underline: false
        )
    }

    static func outline(
        color: UIColor = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.1),
        activeColor: UIColor? = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.2),
        width: CGFloat = 1.0,
        activeWidth: CGFloat? = nil,
        radius: CGFloat = 8
    ) -> GPBorderStyle {
        return GPBorderStyle(
            color: color,
            width: width,
            activeColor: activeColor ?? color,
            activeWidth: activeWidth ?? width,
            radius: radius,
            underline: false
        )
    }

    static func underline(
        color: UIColor = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.1),
        activeColor: UIColor? = UIColor.systemBlue,
        width: CGFloat = 1.0,
        activeWidth: CGFloat? = 2,
        radius: CGFloat = 0
    ) -> GPBorderStyle {
        return GPBorderStyle(
            color: color,
            width: width,
            activeColor: activeColor ?? color,
            activeWidth: activeWidth ?? width,
            radius: radius,
            underline: true
        )
    }
}

public class GPLabelStyle {
    let floating: Bool
    let color: UIColor
    let font: UIFont
    let activeColor: UIColor
    let noLabel: Bool

    fileprivate init(
        floating: Bool,
        color: UIColor,
        font: UIFont,
        activeColor: UIColor,
        noLabel: Bool
    ) {
        self.floating = floating
        self.color = color
        self.font = font
        self.activeColor = activeColor
        self.noLabel = noLabel
    }
}

public extension GPLabelStyle {
    static func floating(
        color: UIColor = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.4),
        font: UIFont = UIFont.systemFont(ofSize: 12.0),
        activeColor: UIColor? = UIColor.systemBlue
    ) -> GPLabelStyle {
        return GPLabelStyle(
            floating: true,
            color: color,
            font: font,
            activeColor: activeColor ?? color,
            noLabel: false
        )
    }

    static func normal(
        color: UIColor = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.5),
        font: UIFont = UIFont.systemFont(ofSize: 12.0),
        activeColor: UIColor? = GPInputStyle.getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.8)
    ) -> GPLabelStyle {
        return GPLabelStyle(
            floating: false,
            color: color,
            font: font,
            activeColor: activeColor ?? color,
            noLabel: false
        )
    }

    static func noLabel() -> GPLabelStyle {
        return GPLabelStyle(
            floating: false,
            color: UIColor.clear,
            font: UIFont.systemFont(ofSize: 12),
            activeColor: UIColor.clear,
            noLabel: true
        )
    }
}

public class GPInputStyle {
    let padding: UIEdgeInsets
    let color: UIColor
    let font: UIFont
    let placeholderColor: UIColor
    let backgroundColor: UIColor
    let errorColor: UIColor
    let borderStyle: GPBorderStyle
    let labelStyle: GPLabelStyle

    let verticalGap: CGFloat
    let horizontalGap: CGFloat

    init(
        padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8),
        color: UIColor = getAdaptiveColor(light: UIColor.black, dark: UIColor.white),
        font: UIFont = UIFont.systemFont(ofSize: 16.0),
        placeholderColor: UIColor = getAdaptiveColor(light: UIColor.black, dark: UIColor.white).withAlphaComponent(0.2),
        backgroundColor: UIColor = UIColor.clear,
        errorColor: UIColor = UIColor.red,
        borderStyle: GPBorderStyle = GPBorderStyle.underline(),
        labelStyle: GPLabelStyle = GPLabelStyle.floating(),
        verticalGap: CGFloat = 8,
        horizontalGap: CGFloat = 8
    ) {
        self.padding = padding
        self.color = color
        self.font = font
        self.placeholderColor = placeholderColor
        self.backgroundColor = backgroundColor
        self.errorColor = errorColor
        self.borderStyle = borderStyle
        self.labelStyle = labelStyle
        self.verticalGap = verticalGap
        self.horizontalGap = horizontalGap
    }
}

public extension GPInputStyle {
    static func getAdaptiveColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            // Use system color for iOS 13 and later
            return UIColor { traitCollection -> UIColor in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            // Manually define color based on interface style for iOS 10
            let currentStyle = UIApplication.shared.statusBarStyle
            return currentStyle == .default ? light : dark
        }
    }
}
