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

/**
 A wrapper on top of BlockaApiService that uses current user
 info to expose convenient api relevant to the current user.
 */
class BlockaApiCurrentUserService {

    private let client: BlockaApiService2

    init(client: BlockaApiService2) {
        self.client = client
    }

    func getAccountForCurrentUser() -> AnyPublisher<Account, Error> {
        return pubs.account.flatMap { it in
            self.client.getAccount(id: it.id)
        }
        .eraseToAnyPublisher()
    }

}
