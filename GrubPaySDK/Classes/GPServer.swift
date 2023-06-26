//
//  GPRequest.swift
//  GrubPaySDK
//
//  Created by Edward Yuan on 2023-05-17.
//

import Foundation

class GPServer {
    private static func sendPOSTRequest(
        url: String,
        params: [String: Any],
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        let baseUrl = "https://api.grubpay.io/v4/"
        guard let url = URL(string: baseUrl + url) else {
            let error = NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            completion(.failure(error))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the Content-Type header
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert the parameters to JSON data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let responseData = data else {
                let error = NSError(domain: "No data in response", code: 0, userInfo: nil)
                completion(.failure(error))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(
                    with: responseData,
                    options: []
                ) as? [String: Any] {
                    print("Response data: \(json)")
                    print("Response retCode: \(String(describing: json["retCode"]))")
                    if json["retCode"] as? String == "SUCCESS" {
                        completion(.success(json))
                        return
                    }

                    if let errMsg = json["retMsg"] as? String {
                        let error = NSError(domain: errMsg, code: 0, userInfo: nil)
                        completion(.failure(error))
                        return
                    }

                    let error = NSError(
                        domain: "Server error: no retData or retMsg found",
                        code: 0,
                        userInfo: nil
                    )
                    completion(.failure(error))
                    return
                }
                let error = NSError(domain: "Invalid JSON format", code: 0, userInfo: nil)
                completion(.failure(error))

            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    static func initialize(
        _ secureId: String,
        completion: @escaping (
            _ success: Bool,
            _ message: String,
            _ config: GPFormConfig?
        ) -> Void
    ) {}
}
