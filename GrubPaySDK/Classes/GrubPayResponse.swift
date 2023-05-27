//
//  GrubPayResponse.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-18.
//

import Foundation

struct GrubPayResponseError {
    let message: String?
    let data: GrubPayResponseData?
    let requireRefresh: Bool?
    let timeout: Bool?
    let validatorErrors: [String]?
}

struct GrubPayResponseData {
    let isPending: Bool
    let data: [String: Any]
}

// class GrubPayResponse {
//    let success: Bool
//    let message: String?
//    let data: GrubPayResponseData?
//    let invalidSecureId: Bool?
//    let timeout: Bool?
//    let validatorErrors: [String]?
//
//    init(
//        success: Bool,
//        message: String? = nil,
//        data: GrubPayResponseData? = nil,
//        invalidSecureId: Bool? = nil,
//        timeout: Bool? = nil,
//        validatorErrors: [String]? = nil
//    ) {
//        self.success = success
//        self.message = message
//        self.data = data
//        self.invalidSecureId = invalidSecureId
//        self.timeout = timeout
//        self.validatorErrors = validatorErrors
//    }
// }
