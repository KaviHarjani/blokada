//
//  This file is part of Blokada.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2021 Blocka AB. All rights reserved.
//
//  @author Karol Gusak
//

import Foundation
import Combine
import UIKit

class BlockaApiService2 {

    private let baseUrl = "https://api.blocka.net"

    private let log = Logger("BlockaApi")

    private let session = URLSession.shared
    private let bgQueue = DispatchQueue(label: "httpClientBgQueue")

    private let decoder = initJsonDecoder()
    private let encoder = initJsonEncoder()

    func userAgent() -> String {
        return "blokada/\(Env.appVersion) (ios-\(UIDevice.current.systemVersion) ios \(Env.buildType) \(Env.cpu) apple \(Env.deviceModel) touch api compatible)"
    }

    func getAccount(id: AccountId) -> AnyPublisher<Account, Error> {
        return self.get("/v1/account?account_id=\(id)")
            .decode(type: AccountWrapper.self, decoder: self.decoder)
            .map { result in
                return result.account
            }
            .eraseToAnyPublisher()
    }

    func postNewAccount() -> AnyPublisher<Account, Error> {
        return self.post("/v1/account", payload: nil)
            .decode(type: AccountWrapper.self, decoder: self.decoder)
            .map { result in
                return result.account
            }
            .eraseToAnyPublisher()
    }

    private func get(_ path: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(self.baseUrl)\(path)") else {
            return Fail(error: "BlockaApi: get: invalid url: \(path)")
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.setValue(self.userAgent(), forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"

        return self.session.dataTaskPublisher(for: request)
            .tryCatch { error in
                // A delayed retry
                return self.session.dataTaskPublisher(for: request)
                    .delay(for: DispatchQueue.SchedulerTimeType.Stride(integerLiteral: Int.random(in: 1..<5)), scheduler: self.bgQueue)
                    .retry(2)
            }
            .tryMap { response -> Data in
                guard let r = response.response as? HTTPURLResponse else {
                    throw "no response"
                }

                guard r.statusCode == 200 else {
                    throw "response code: \(r.statusCode)"
                }

                return response.data
            }
            .mapError { return "BlockaApi: get: \($0)" }
            .eraseToAnyPublisher()
    }

    private func post(_ path: String, payload: Encodable?) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(self.baseUrl)\(path)") else {
            return Fail(error: "BlockaApi: post: invalid url: \(path)")
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.setValue(self.userAgent(), forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"

        if payload != nil {
            guard let payloadEncoded = payload?.toJsonData() else {
                return Fail(error: "BlockaApi: post: invalid payload (could not encode)")
                    .eraseToAnyPublisher()
            }
            request.httpBody = payloadEncoded
        }

        return self.session.dataTaskPublisher(for: request)
            .tryMap { response -> Data in
                guard let r = response.response as? HTTPURLResponse else {
                    throw "no response"
                }

                guard r.statusCode == 200 else {
                    throw "response code: \(r.statusCode)"
                }

                return response.data
            }
            .mapError { return "BlockaApi: post: \($0)" }
            .eraseToAnyPublisher()
    }
}
