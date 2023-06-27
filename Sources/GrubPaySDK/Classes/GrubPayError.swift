//
//  GrubPayError.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-21.
//

import AVFoundation
import Foundation

public enum GrubPayErrorType: Int {
    // When request timeout
    case timeout = 10

    // When network error
    case network = 20

    // Invalid secureId, please use a new one
    case secureId = 1

    // Previous request not completed yet
    case loading = 2

    // Please initialize first
    case mount = 3

    // Form validator error, ask user to check input
    case validator = 30

    // This indicates error from our server ends, please check message
    case other = 0

    // This indicates error from our server ends, please check message
    case server = 50

    // This secureId is already paid.
    case paid = 4

    // this secureId is already failed.
    case failed = 5

    // This is when user canceled by exiting the ViewController
    case cancel = 9

    // Root ViewController not found
    case viewController = 8
}

public class GrubPayError: Error {
    public let type: GrubPayErrorType
    public let message: String
    public let validatorErrors: [String]?
    public let requireNewSecureId: Bool

    internal init(
        type: GrubPayErrorType,
        message: String,
        validatorErrors: [String]? = nil,
        requireNewSecureId: Bool = false
    ) {
        self.type = type
        self.message = message
        self.validatorErrors = validatorErrors
        self.requireNewSecureId = requireNewSecureId
    }

    internal static let viewController: GrubPayError
        = .init(
            type: .viewController,
            message: "View controller not found",
            requireNewSecureId: true
        )

    internal static let cancel: GrubPayError
        = .init(
            type: .cancel,
            message: "User has cancelled the action",
            requireNewSecureId: false
        )

    internal static let loading: GrubPayError
        = .init(
            type: .loading,
            message: "Please wait for previous request to finish before make another call",
            requireNewSecureId: false
        )

    internal static let mount: GrubPayError
        = .init(
            type: .mount,
            message: "Form not yet loaded. Please call load(secureId) first",
            requireNewSecureId: true
        )

    internal static let paid: GrubPayError
        = .init(
            type: .paid,
            message: "This secureId is already paid.",
            requireNewSecureId: true
        )

    internal static let failed: GrubPayError
        = .init(
            type: .failed,
            message: "This secureId is already failed. You will need to use a new secureId",
            requireNewSecureId: true
        )

    internal static let invalidUrl: GrubPayError
        = .init(type: .other, message: "Invalid URL")

    internal static let jsonParse: GrubPayError
        = .init(
            type: .other,
            message: "Invalid JSON format",
            requireNewSecureId: true
        )

    internal static let noResponseData: GrubPayError = .init(
        type: .server,
        message: "No data in response",
        requireNewSecureId: true
    )

    internal static let noRetData: GrubPayError = .init(
        type: .server,
        message: "No data in response",
        requireNewSecureId: true
    )

    internal static let invalidSecureId: GrubPayError = .init(
        type: .secureId,
        message: "Invalid secureId",
        requireNewSecureId: true
    )

    internal static let cannotRetrieveMethod: GrubPayError = .init(
        type: .server,
        message: "Can not retrieve payment method. Server responded with incorrect data.",
        requireNewSecureId: true
    )

    // Some convenient initializers

    internal static func other(_ message: String) -> GrubPayError {
        return GrubPayError(type: .other, message: message)
    }

    internal static func requireNewSecureId(_ message: String) -> GrubPayError {
        return GrubPayError(type: .other, message: message, requireNewSecureId: true)
    }

    internal static func server(_ message: String) -> GrubPayError {
        return GrubPayError(type: .server, message: message, requireNewSecureId: true)
    }

    internal static func validator(_ errors: [String]) -> GrubPayError {
        return GrubPayError(
            type: .validator,
            message: "Invalid inputs",
            validatorErrors: errors,
            requireNewSecureId: false
        )
    }
}

internal struct CameraInitializationError: Error {}
internal struct CameraPermissionError: Error {
    let authorizationStatus: AVAuthorizationStatus
}
