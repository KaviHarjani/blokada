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

class AccountRepository {

    private let log = Logger("AccRepo")
    private let decoder = blockaDecoder
    private let encoder = blockaEncoder

    private lazy var local = Factories.persistenceLocal
    private lazy var remote = Factories.persistenceRemote
    private lazy var remoteLegacy = Factories.persistenceRemoteLegacy
    private lazy var crypto = Factories.crypto
    private lazy var api = Factories.api
    private lazy var apiForCurrentUser = Factories.apiForCurrentUser

    private lazy var writeError = Pubs.writeError
    private lazy var writeAccount = Pubs.writeAccount

    init() {
        initialLoad()
    }

    func initialLoad() {
        var cancellables = Set<AnyCancellable>()

        // Load user from persistence. Create if not existing.
        Publishers.CombineLatest(
            self.loadAccountFromPersistence(),
            self.loadKeypairFromPersistence()
        )
        .tryMap { it in
            try self.validateAccount(it.0)
            return AccountWithKeypair(account: it.0, keypair: it.1)
        }
        .tryCatch { err -> AnyPublisher<AccountWithKeypair, Error> in
            // TODO: create new user on any error?
            if err as? CommonError == CommonError.emptyResult {
                return self.createNewUser()
            }
            throw err
        }
        .sink(
            // Publish account or error to other components
            onValue: { it in self.writeAccount.send(it) },
            onFailure: { err in self.writeError.send(err) }
        )
        .store(in: &cancellables)
    }

//func restoreAccount(_ newAccountId: AccountId) -> AnyPublisher<Void, Error> {
//
//}

    private func createNewUser() -> AnyPublisher<AccountWithKeypair, Error> {
        return
    }

    private func validateAccount(_ account: Account) throws {
        if account.id.isEmpty {
            throw "account with empty ID"
        }
    }

    private func saveAccountToPersistence(_ account: Account) {
        var cancellables = Set<AnyCancellable>()
        Just(account).encode(encoder: self.encoder)
        .tryMap { it -> String in
            guard let it = String(data: it, encoding: .utf8) else {
                throw "setAccount: could not encode json data to string"
            }
            return it
        }
        .tryMap { it in
            return self.remote.setString(it, forKey: "account").eraseToAnyPublisher()
        }
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let err):
                    Pubs.writeError.send(err)
                    break
                default:
                    break
                }
            },
            receiveValue: { it in }
        )
        .store(in: &cancellables)
    }

    private func loadAccountFromPersistence() -> AnyPublisher<Account, Error> {
        return remote.getString(forKey: "account").tryCatch { err -> AnyPublisher<String, Error> in
            // A legacy read of the account - to be removed later
            return self.remoteLegacy.getString(forKey: "account")
        }
        .tryMap { it -> Data in
            guard let it = it.data(using: .utf8) else {
                throw "failed reading persisted account data"
            }

            return it
        }
        .decode(type: Account.self, decoder: self.decoder)
        .eraseToAnyPublisher()
    }

    private func loadKeypairFromPersistence() -> AnyPublisher<Keypair, Error> {
        return local.getString(forKey: "keypair").tryMap { it -> Data in
            guard let it = it.data(using: .utf8) else {
                throw "failed reading persisted keypair data"
            }

            return it
        }
        .decode(type: Keypair.self, decoder: self.decoder)
        .tryCatch { err -> AnyPublisher<Keypair, Error> in
            // A legacy read of the keys - to be removed later
            return Publishers.CombineLatest(
                self.local.getString(forKey: "privateKey"),
                self.local.getString(forKey: "publicKey")
            ).tryMap { it in
                return Keypair(privateKey: it.0, publicKey: it.1)
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
