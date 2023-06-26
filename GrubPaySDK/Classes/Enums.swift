//
//  Enums.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-04-27.
//

import Foundation

internal enum GPCountry: String, CaseIterable {
    case us = "US"
    case ca = "Canada"
    case uk = "UK"
    case others = "Others"

//    var name: String {
//        switch self {
//        case .us:
//            return "US"
//        case .ca:
//            return "Canada"
//        case .uk:
//            return "UK"
//        case .others:
//            return "Others"
//        }
//    }

    var zipName: String {
        switch self {
        case .us:
            return "Zip"
        default:
            return "Postal"
        }
    }

    var zipPh: String {
        switch self {
        case .us:
            return "#####"
        case .ca:
            return "A1A 1A1"
        case .uk:
            return "WS11 1DB"
        default:
            return "#####"
        }
    }

    var inputMask: String? {
        switch self {
        case .us:
            return "#####-####"
        case .ca:
            return "A#A #A#"
        case .uk:
            return "AA## #AA"
        default:
            return nil
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .us:
            return .numberPad
        default:
            return .default
        }
    }

    func validateText(_ text: String) -> Bool {
        switch self {
        case .us:
            return text.count > 4
        case .ca:
            return text.count == 7
        case .uk:
            return text.count > 3
        default:
            return true
        }
    }
}

internal enum GPInputType: Int {
    case name = 1
    case card = 2
    case expiry = 3
    case cvc = 4
    case country = 5
    case zip = 6
    case routing = 7
    case account = 8
}

public enum GrubPayACHAccountType: String {
    case ECHK
    case ESAV
}

public enum GrubPayChannel: String {
    case ach = "CC_ACH"
    case card = "CC_CARD"
}

public enum GrubPayCardBrand: String {
    case unknown = ""
    case amex = "AMEX"
    case visa = "VISA"
    case maestro = "Maestro"
    case master = "Master"
    case bcglobal = "BC Global"
    case discover = "Discover"
    case diners = "Diners Club"
    case jcb = "JCB"
    case unionpay = "UnionPay"

    internal static let allCards = [
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

    internal var regex: String {
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

    internal var imageName: String {
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

    internal static func fromCardNumber(_ cardNumber: String) -> GrubPayCardBrand {
        return GrubPayCardBrand.unknown
    }
}
