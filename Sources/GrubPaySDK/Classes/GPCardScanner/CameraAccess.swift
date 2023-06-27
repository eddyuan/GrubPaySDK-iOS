//
//  CameraAccess.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-02.
//

import AVFoundation
import Foundation

protocol CameraAccessProtocol {
    func request(_ compltion: @escaping (Bool) -> Void)
}

struct CameraAccess: CameraAccessProtocol {
    public init() {}
    public func request(_ compltion: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            compltion(true)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { success in
                DispatchQueue.main.async {
                    compltion(success)
                }
            }
        }
    }
}
