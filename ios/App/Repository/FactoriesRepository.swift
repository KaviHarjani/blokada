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

let Factories = FactoriesRepository()

class FactoriesRepository {

    fileprivate init() {}

    lazy var persistenceLocal = LocalStoragePersistenceService()
    lazy var persistenceRemote = ICloudPersistenceService()
    lazy var persistenceRemoteLegacy = ICloudPersistenceService()

    lazy var crypto = CryptoServiceMock()

    private lazy var http = HttpClientService()
    lazy var api = BlockaApiService2(client: http)
    lazy var apiForCurrentUser = BlockaApiCurrentUserService(client: api)
}
