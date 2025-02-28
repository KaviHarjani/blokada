//
//  This file is part of Blokada.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2020 Blocka AB. All rights reserved.
//
//  @author Karol Gusak
//

import Foundation

class ActivityViewModel: ObservableObject {

    private let log = Logger("ActivityVM")
    private let service = ActivityService.shared
    private let sharedActions = SharedActionsService.shared
    private let api = BlockaApiService.shared

    @Published var logRetention = Config.shared.logRetention()
    @Published var logRetentionSelected = ""

    var allEntries = [HistoryEntry]()
    @Published var entries = [HistoryEntry]()

    @Published var whitelist = [String]()
    @Published var blacklist = [String]()

    @Published var sorting = 0 {
        didSet {
            refreshStats(ok: { _ in self.apply() })
        }
    }

    @Published var filtering = 0 {
        didSet {
            refreshStats(ok: { _ in self.apply() })
        }
    }

    @Published var search = "" {
        didSet {
            apply()
        }
    }

    func fetch() {
        service.setOnUpdated { entries, whitelist, blacklist in
            onMain {
                self.whitelist = whitelist
                self.blacklist = blacklist
                self.allEntries = entries
                self.apply()
                self.objectWillChange.send()
            }
        }
    }

    func apply() {
        // Apply search term
        if search.isEmpty {
            entries = allEntries
        } else {
            entries = allEntries.filter { $0.name.range(of: search, options: .caseInsensitive) != nil }
        }

        // Apply filtering
        if filtering == 1 {
            // Blocked only
            entries = entries.filter { $0.type == .blocked }
        } else if filtering == 2 {
            // Allowed only
            entries = entries.filter { $0.type != .blocked }
        }

        // Apply sorting
        switch(sorting) {
        case 1:
            // Sorted by the number of requests
            entries = entries.sorted { $0.requests > $1.requests }
        default:
            // Sorted by recent
            entries = entries.sorted { $0.time > $1.time }
        }
    }

    func allow(_ entry: HistoryEntry) {
        self.service.allow(entry: entry)
    }

    func unallow(_ entry: HistoryEntry) {
        self.service.unallow(entry: entry)
    }

    func deny(_ entry: HistoryEntry) {
        self.service.deny(entry: entry)
    }

    func undeny(_ entry: HistoryEntry) {
        self.service.undeny(entry: entry)
    }

    func refreshStats(ok: @escaping Ok<Void> = { _ in }) {
        self.sharedActions.refreshStats(ok)
        self.api.getCurrentDeviceActivity { error, activity in
            guard let activity = activity else {
                return self.log.w("refreshStats: failed getting activity".cause(error))
            }

            self.service.setEntries(entries: convertActivity(activity: activity))

            ok(())
        }
    }

    func foreground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1), execute: {
            self.refreshStats()
        })
    }

    func checkLogRetention() {
        // Set quickly from local storage and then refresh with a request
        self.logRetentionSelected = self.logRetention
        self.api.getCurrentDevice { error, device in
            guard error == nil else {
                return self.log.w("checkLogRetention: error getting device".cause(error))
            }

            guard let device = device else {
                return self.log.v("checkLogRetention: no device")
            }

            self.logRetention = device.retention
            Config.shared.setLogRetention(retention: self.logRetention)
            self.logRetentionSelected = self.logRetention
            self.sharedActions.refreshPauseInformation(device.paused)
        }
    }

    func applyLogRetention() {
        self.api.postDevice(request: DeviceRequest(
            account_id: Config.shared.accountId(),
            lists: nil,
            retention: self.logRetentionSelected,
            paused: nil
        )) { error, _ in
            guard error == nil else {
                return self.log.w("applyLogRetention: request failed".cause(error))
            }

            Config.shared.setLogRetention(retention: self.logRetentionSelected)
            self.logRetention = self.logRetentionSelected
        }
    }

}
