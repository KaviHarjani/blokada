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
 This file is meant to contain the only singleton object in the app, which contains all publishers used
 by various components. Other components publish to these publishers (actually subjects). This is
 meant to solve the circular dependency problem without introducing DI libs, or sacraficing testability
 and modularity. The subjects themselves are never needed to be mocked, so they can be singleton.
 */

let Pubs = PublishersRepository()

class PublishersRepository {

    fileprivate init() {}

    let writeError = CurrentValueSubject<Error?, Never>(nil)
    var error: AnyPublisher<Error, Never> {
        self.writeError.compactMap { $0 }.eraseToAnyPublisher()
    }

    let writeAccount = CurrentValueSubject<AccountWithKeypair?, Never>(nil)
    var account: AnyPublisher<AccountWithKeypair, Never> {
        self.writeAccount.compactMap { $0 }.eraseToAnyPublisher()
    }

    let writeHasAccount = CurrentValueSubject<Bool?, Never>(nil)
    var hasAccount: AnyPublisher<Bool, Never> {
        self.writeHasAccount.compactMap { $0 }.eraseToAnyPublisher()
    }

    
}
