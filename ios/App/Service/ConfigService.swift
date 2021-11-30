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

class ConfigService {

    private init() {
        oldiCloud.synchronizable = true
    }

    private let log = Logger("Config")

    private let decoder = initJsonDecoder()
    private let encoder = initJsonEncoder()

    // We persist config either on local storage, in the iCloud, or in RAM only. There is also legacy iCloud destination to only read data from.
    private let localStorage = UserDefaults.standard
    private let iCloud = NSUbiquitousKeyValueStore()
    private let oldiCloud = KeychainSwift()

    private let _deviceToken = Atomic<DeviceToken?>(nil)
    private let _account = Atomic<Account?>(nil)
    private let _lease = Atomic<Lease?>(nil)
    private let _gateway = Atomic<Gateway?>(nil)
}
