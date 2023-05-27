//
//  GPRequest.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-17.
//

import Foundation

class GPRequest {
    static func loadSession(
        _ sessionId: String,
        _ completion: @escaping (
            _ success: Bool,
            _ message: String?,
            _ config: GPFormConfig?
        ) -> Void
    ) {}
}
