//
//  GrubPay.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-22.
//

import Foundation

public enum GrubPay {
    public static func element(
        viewController: UIViewController? = nil,
        onValidChange: @escaping (_ isValid: Bool) -> Void = { _ in },
        onEnableChange: @escaping (_ isEnabled: Bool) -> Void = { _ in },
        onLoadingChange: @escaping (_ isLoading: Bool) -> Void = { _ in }
    ) -> GrubPayElement {
        return GrubPayElement(
            viewController: viewController,
            onValidChange: onValidChange,
            onEnableChange: onEnableChange,
            onLoadingChange: onLoadingChange
        )
    }

    public static func launch(
        _ secureId: String,
        saveCard: Bool = false,
        inputStyle: GPInputStyle = .init(),
        viewController: UIViewController? = nil,
        completion: @escaping (Result<GrubPayResponse, GrubPayError>) -> Void
    ) {
        DispatchQueue.main.async {
            guard let rootViewController = viewController ?? UIApplication.shared.windows.first(
                where: { $0.isKeyWindow }
            )?.rootViewController else {
                completion(.failure(.viewController))
                return
            }
            _ = GrubPayVC(
                secureId,
                inputStyle: inputStyle,
                launchAfterLoaded: true,
                rootViewController: rootViewController,
                completion: completion
            )
        }
    }
}
