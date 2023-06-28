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
//            let navigationController: UINavigationController!
            let grubPayVC = GrubPayVC(
                secureId,
                inputStyle: inputStyle,
                completion: completion
            )

            let navigationController = UINavigationController(rootViewController: grubPayVC)
            navigationController.modalPresentationStyle = .pageSheet
            navigationController.presentationController?.delegate = grubPayVC
            rootViewController.present(
                navigationController,
                animated: true,
                completion: nil
            )
        }
    }
}
