//
//  GrubPayResponse.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-18.
//

import Foundation

public struct GrubPayOrder {
    public let payOrderId: String
    public let mchId: String
    public let mchOrderNo: String
    public let originalOrderId: String?
    public let currency: String
    public let amount: Int
    public let payType: String
    public let refundable: Int
    public let status: Int
    public let invoiceNum: String?
    public let paySuccTime: String?
    public let authNum: String?
    public let transNum: String?
    public let channel: String?
    public let recurringId: String?

    internal static func fromJson(_ json: [String: Any]) -> GrubPayOrder? {
        guard let payOrderId = tStringOrNil(json["payOrderId"]) else {
            return nil
        }

        return GrubPayOrder(
            payOrderId: payOrderId,
            mchId: tString(json["mchId"]),
            mchOrderNo: tString(json["mchOrderNo"]),
            originalOrderId: tStringOrNil(json["originalOrderId"]),
            currency: tString(json["currency"]),
            amount: tInt(json["amount"]),
            payType: tString(json["payType"]),
            refundable: tInt(json["refundable"]),
            status: tInt(json["status"]),
            invoiceNum: tStringOrNil(json["invoiceNum"]),
            paySuccTime: tStringOrNil(json["paySuccTime"]),
            authNum: tStringOrNil(json["authNum"]),
            transNum: tStringOrNil(json["transNum"]),
            channel: tStringOrNil(json["channel"]) ?? "CC_CARD",
            recurringId: tStringOrNil(json["recurringId"])
        )
    }
}

public struct GrubPayCard {
    // Only when saveUser or tokenize
    public let cardNum: String
    public let token: String?
    public let expiryDate: String?
    public let cardType: String?
    public let zip: String?
    public let pan: String?
    public let brand: GrubPayCardBrand

    internal static func fromJson(_ json: [String: Any], brand: GrubPayCardBrand = .unknown) -> GrubPayCard? {
        guard let cardNum = tStringOrNil(json["cardNum"]) else {
            return nil
        }
        return GrubPayCard(
            cardNum: cardNum,
            token: tStringOrNil(json["token"]),
            expiryDate: tStringOrNil(json["expiryDate"]),
            cardType: tStringOrNil(json["cardType"]),
            zip: tStringOrNil(json["zip"]),
            pan: tStringOrNil(json["pan"]),
            brand: brand
        )
    }
}

public struct GrubPayACHAccount {
    public let acctNum: String
    public let token: String?

    internal static func fromJson(_ json: [String: Any]) -> GrubPayACHAccount? {
        guard let acctNum = tStringOrNil(json["acctNum"]) else {
            return nil
        }
        return GrubPayACHAccount(
            acctNum: acctNum,
            token: tStringOrNil(json["token"])
        )
    }
}

public struct GrubPayResponse {
    public let json: [String: Any]
    public let capture: String?
    // Only if returnUrl is set
    public let returnUrl: String?
    public let creditCard: GrubPayCard?
    public let achAccount: GrubPayACHAccount?
    public let order: GrubPayOrder?

    internal static func fromJson(_ json: [String: Any], brand: GrubPayCardBrand = .unknown) -> GrubPayResponse {
        return GrubPayResponse(
            json: json,
            capture: tStringOrNil(json["capture"]),
            returnUrl: tStringOrNil(json["returnUrl"]),
            creditCard: GrubPayCard.fromJson(json, brand: brand),
            achAccount: GrubPayACHAccount.fromJson(json),
            order: GrubPayOrder.fromJson(json)
        )
    }
}
