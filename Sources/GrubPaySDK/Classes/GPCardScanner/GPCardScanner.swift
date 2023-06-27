//
//  GPCardScanner.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-06-19.
//

import Foundation

@available(iOS 13.0, *)
class GPCardScanner: UIViewController {
    private var scannerView: GPScannerView?
    private let resultsHandler: (_ number: String?, _ date: String?) -> Void
    private func onSuccess(_ number: String?, _ date: String?) {
        resultsHandler(number, date)
        DispatchQueue.main.async {
            [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    private func onError(_ error: Error) {
        DispatchQueue.main.async {
            [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func onCancel() {
        DispatchQueue.main.async {
            [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    init(
        resultsHandler: @escaping (_ number: String?, _ date: String?) -> Void,
        buttonColor: UIColor
    ) {
        self.resultsHandler = resultsHandler
        super.init(nibName: nil, bundle: nil)
        self.scannerView = GPScannerView(
            onSuccess: onSuccess,
            onError: onError,
            buttonColor: buttonColor
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let buttomItem = UIBarButtonItem(
            barButtonSystemItem: .stop,
            target: self,
            action: #selector(onCancel)
        )
        view.backgroundColor = UIColor.black
        buttomItem.tintColor = .white
        navigationItem.leftBarButtonItem = buttomItem

        view.addSubview(scannerView!)
        scannerView!.frame = view.frame
        scannerView!.startCapture()
    }

    override func viewDidLayoutSubviews() {
        scannerView?.frame = view.frame
        super.viewDidLayoutSubviews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        scannerView?.stopCapture()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func showScanner(
        buttonColor: UIColor,
        rootViewController: UIViewController,
        completed: @escaping (_ number: String?, _ date: String?) -> Void
    ) {
        let viewScanner = GPCardScanner(
            resultsHandler: completed,
            buttonColor: buttonColor
        )
        let navigation = UINavigationController(rootViewController: viewScanner)
        navigation.modalPresentationStyle = .pageSheet
        rootViewController.present(
            navigation,
            animated: true,
            completion: nil
        )
    }
}
