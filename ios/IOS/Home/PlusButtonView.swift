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

import SwiftUI

struct PlusButtonView: View {

    @ObservedObject var vm: HomeViewModel

    @Binding var activeSheet: ActiveSheet?

    @State var orientationOpacity = 0.0

    var body: some View {
        return ZStack {
            ButtonView(enabled: .constant(!self.vm.vpnEnabled), plus: .constant(true))
            HStack {
                Button(action: {
                    self.vm.expiredAlertShown = false

                    if !self.vm.accountActive {
                        self.activeSheet = .plus
                    } else if self.vm.accountType == "cloud" {
                        Links.openInBrowser(Links.manageSubscriptions())
                    } else {
                        self.activeSheet = .location
                    }
                }) {
                    ZStack {
                        HStack {
                            if !self.vm.accountActive || self.vm.accountType != "plus" {
                                Spacer()
                                L10n.universalActionUpgrade
                                    .toBlokadaPlusText(color: self.vm.vpnEnabled ? Color.primary : Color.white, plusColor: self.vm.vpnEnabled ? Color.primary : Color.white)
                                    .foregroundColor(self.vm.vpnEnabled ? Color.primary : Color.white)
                                    .font(.system(size: 14))
                            } else if !self.vm.vpnEnabled {
                                if !self.vm.hasLease {
                                    Spacer()
                                }

                                Text(L10n.homePlusButtonDeactivatedCloud)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            } else if !self.vm.hasSelectedLocation {
                                Spacer()
                                Text(L10n.homePlusButtonSelectLocation)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            } else {
                                L10n.homePlusButtonLocation(self.vm.location)
                                    .withBoldSections(font: .system(size: 14))
                                    .foregroundColor(.primary)
                                    .font(.system(size: 14))
                            }
                            Spacer()
                        }
                        .padding(.leading)
                    }
                }
                if self.vm.hasLease {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.cBackground)
                            .frame(width: 58)

                        if #available(iOS 14.0, *) {
                            Toggle("", isOn: self.$vm.vpnEnabled)
                                .labelsHidden()
                                .frame(width: 64)
                                .padding(.trailing, 4)
                                .onTapGesture {
                                    self.vm.switchVpn(activate: !self.vm.vpnEnabled, noPermissions: {
                                        // A callback trigerred when there is no VPN profile
                                        self.activeSheet = .askvpn
                                    })
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.cAccent))
                        } else {
                            Toggle("", isOn: self.$vm.vpnEnabled)
                                .labelsHidden()
                                .frame(width: 64)
                                .padding(.trailing, 4)
                                .onTapGesture {
                                    self.vm.switchVpn(activate: !self.vm.vpnEnabled, noPermissions: {
                                        // A callback trigerred when there is no VPN profile
                                        self.activeSheet = .askvpn
                                    })
                                }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                }
            }
        }
        .frame(height: 44)
        .padding([.bottom, .leading, .trailing])
        .transition(.slide)
        .offset(y: self.vm.mainSwitch && !self.vm.isPaused ? 8 : 69)
        .animation(
            Animation.easeInOut(duration: 0.6).repeatCount(1)
        )
        .disabled(self.vm.working || self.vm.isPaused)
        .opacity(self.orientationOpacity)
        .onAppear {
            self.orientationOpacity = 1.0
        }
    }
}

struct PlusButtonView_Previews: PreviewProvider {
    static var previews: some View {
        PlusButtonView(
            vm: HomeViewModel(),
            activeSheet: .constant(nil)
        )
    }
}
