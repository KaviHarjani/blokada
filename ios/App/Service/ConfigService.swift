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

class ConfigService {

    private let log = Logger("Config")

    private let decoder = initJsonDecoder()
    private let encoder = initJsonEncoder()

    // We persist config either on local storage, in the iCloud, or in RAM only. There is also legacy iCloud destination to only read data from.
    private let localStorage = UserDefaults.standard
    private let _deviceToken = Atomic<DeviceToken?>(nil)
    //private let _account = Atomic<Account?>(nil)
    private let _lease = Atomic<Lease?>(nil)
    private let _gateway = Atomic<Gateway?>(nil)

    private let _account = CurrentValueSubject<Account?, Never>(nil)
    var account: AnyPublisher<Account, Never> {
        self._account.compactMap { $0 }.eraseToAnyPublisher()
    }

    private let _hasAccount = CurrentValueSubject<Bool?, Never>(nil)
    var hasAccount: AnyPublisher<Bool, Never> {
        self._hasAccount.compactMap { $0 }.eraseToAnyPublisher()
    }

    private let _error = CurrentValueSubject<Error?, Never>(nil)
    var error: AnyPublisher<Error, Never> {
        self._error.compactMap { $0 }.eraseToAnyPublisher()
    }

    private let remote: PersistenceService
    private let remoteLegacy: PersistenceService

    init(remote: PersistenceService, remoteLegacy: PersistenceService) {
        self.remote = remote
        self.remoteLegacy = remoteLegacy

       load()
    }

    func load() {
        var cancellables = Set<AnyCancellable>()
        let fork = PassthroughSubject<Account, Error>()
        let pub = self.loadAccount().multicast(subject: fork)
        pub.sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let err):
                self._error.send(err)
                break
            default:
                break
            }
        }, receiveValue: { it in
            self._account.send(it)
        })
        .store(in: &cancellables)

        fork.tryMap { it -> Bool in return true }
        .replaceEmpty(with: false)
        .sink(
            receiveCompletion: { completion in },
            receiveValue: { it in self._hasAccount.send(it) }
        )
        .store(in: &cancellables)

        pub.connect().store(in: &cancellables)
    }

    func setAccount(_ account: Account) {
        Just(account).encode(encoder: self.encoder)
        .tryMap { it -> String in
            guard let it = String(data: it, encoding: .utf8) else {
                throw "setAccount: could not encode json data to string"
            }
            return it
        }
        .tryMap { it in
            return self.remote.setString(it, forKey: "account")
        }
        .tryCatch { err in
            self._error.send(err)
        }
        .sink(
            receiveCompletion: { completion in },
            receiveValue: { it in }
        )
    }

//        self._account.value = self.loadAccount()
//        self._lease.value = self.loadLease()
//        self._gateway.value = self.loadGateway()
//
//        onMain {
//            self.onConfigUpdated()
//            self.onAccountUpdated()
//        }
    //}

    private func loadAccount() -> AnyPublisher<Account, Error> {
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
        .mapError { return "ConfigService: loadAccount: \($0)" }
        .eraseToAnyPublisher()
    }

}
