//
//  Enums.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-04-27.
//

import Foundation

private enum CPCardCountry: String {
    case us,
         ca,
         uk,
         others
}

enum GPCardType: String {
    case unknown,
         amex,
         visa,
         maestro,
         master,
         bcglobal,
         discover,
         diners,
         jcb,
         unionpay

    static let allCards = [
        amex,
        visa,
        maestro,
        master,
        bcglobal,
        discover,
        diners,
        jcb,
        unionpay
    ]

    var regex: String {
        switch self {
        case .amex:
            return "^3[47][0-9]{5,}$"
        case .visa:
            return "^4[0-9]{6,}([0-9]{3})?$"
        case .maestro:
            return "^(5018|5081|5044|5020|5038|603845|6304|6759|676[1-3]|6799|6220|504834|504817|504645)[0-9]{8,15}$"
        case .master:
            return "^(5[1-5][0-9]{4,}|222[1-9][0-9]{1,}|22[3-9][0-9]{4,}|2[3-6][0-9]{5,}|27[01][0-9]{4,}|2720[0-9]{3,})$"
        case .bcglobal:
            return "^(6541|6556)[0-9]{2,}$"
        case .discover:
            return "^6(?:011|5[0-9]{2})[0-9]{3,}$"
        case .diners:
            return "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$"
        case .jcb:
            return "^(?:2131|1800|35[0-9]{3})[0-9]{3,}$"
        case .unionpay:
            return "^(62|88)[0-9]{5,}$"
        default:
            return ""
        }
    }

    var imageName: String {
        switch self {
        case .amex:
            return "cc-amex"
        case .visa:
            return "cc-visa"
        case .maestro:
            return "cc-maestro"
        case .master:
            return "cc-master"
        case .bcglobal:
            return "cc-bcglobal"
        case .discover:
            return "cc-discover"
        case .diners:
            return "cc-dinner"
        case .jcb:
            return "cc-jcb"
        case .unionpay:
            return "cc-unionpay"
        default:
            return "cc-generic"
        }
    }
}
