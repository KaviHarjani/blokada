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

struct PaymentGatewayView: View {

    @ObservedObject var vm: PaymentGatewayViewModel

    @Binding var activeSheet: ActiveSheet?

    @State var showPrivacySheet = false
    @State var showPlusFeaturesSheet = false

    private let networkDns = NetworkDnsService.shared

    var body: some View {
        if self.vm.accountActive {
            self.activeSheet = nil
            self.networkDns.isBlokadaNetworkDnsEnabled { error, dnsEnabled in
                guard dnsEnabled == true else {
                    // If not, show the prompt
                    DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(1), execute: {
                        //self.activeSheet = .activated
                        self.activeSheet = .dnsProfile
                    })
                    return
                }
            }
        }

        return ZStack(alignment: .topTrailing) {
            ScrollView {
                ZStack {
                    // Main part - payment options and all
                    HStack {
                        Spacer()
                        VStack {
                            Text(L10n.paymentActionCompare)
                                .foregroundColor(Color.cActivePlus)
                                .onTapGesture {
                                    withAnimation {
                                        self.showPlusFeaturesSheet = true
                                    }
                                }
                                .sheet(isPresented: self.$showPlusFeaturesSheet) {
                                    PlusFeaturesView(showSheet: self.$showPlusFeaturesSheet)

                                }
                                .padding(.top, 12)
                                .padding(.bottom, 14)

                            VStack {
                                HStack {
                                    Spacer()
                                    Text("BLOKADA")
                                        .fontWeight(.heavy).kerning(2).font(.system(size: 15))

                                    Text("CLOUD")
                                        .fontWeight(.heavy).kerning(2).font(.system(size: 15))
                                        .foregroundColor(Color.cActive)
                                    Spacer()
                                }
                                .padding(.bottom, 2)

                                Text(L10n.paymentPlanSluglineCloud)
                                   .multilineTextAlignment(.center)
                                   .lineLimit(2)
                                   .font(.system(size: 13))
                                   .foregroundColor(Color.secondary)
                                   .padding(.bottom, 24)

                                PaymentListView(vm: vm, showType: "cloud")
                            }
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(Color.cActive)
                                    RoundedRectangle(cornerRadius: 10).fill(Color.cSemiTransparent)
                                }
                            )

                            ZStack {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("BLOKADA")
                                            .fontWeight(.heavy).kerning(2).font(.system(size: 15))

                                        Text("PLUS")
                                            .fontWeight(.heavy).kerning(2).font(.system(size: 15))
                                            .foregroundColor(Color.cActivePlus)
                                        Spacer()
                                    }
                                    .padding(.bottom, 2)

                                    Text(L10n.paymentPlanSluglinePlus)
                                       .multilineTextAlignment(.center)
                                       .lineLimit(2)
                                       .font(.system(size: 13))
                                       .foregroundColor(Color.secondary)
                                       .padding(.bottom, 1)

                                    Text(L10n.paymentPlanSluglineCloudDetail)
                                       .multilineTextAlignment(.center)
                                       .lineLimit(2)
                                       .font(.system(size: 13))
                                       .foregroundColor(Color.secondary)
                                       .padding(.bottom, 24)

                                    PaymentListView(vm: vm, showType: "plus")
                                        .frame(minHeight: 128)
                                }
                                .padding()
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color.cActivePlus)
                                        RoundedRectangle(cornerRadius: 10).fill(Color.cSemiTransparent)
                                    }
                                )
                            }.padding(.top, 16)

                            Spacer()

                            VStack {
                                Text(L10n.paymentActionRestore)
                                    .foregroundColor(Color.cActivePlus)
                                    .multilineTextAlignment(.center)
                                    .onTapGesture {
                                        withAnimation {
                                            self.vm.restoreTransactions()
                                        }
                                    }

                                Text(L10n.paymentActionTermsAndPrivacy)
                                    .foregroundColor(Color.cActivePlus)
                                    .padding(.top, 8)
                                    .multilineTextAlignment(.center)
                                    .actionSheet(isPresented: self.$showPrivacySheet) {
                                        ActionSheet(title: Text(L10n.paymentActionTermsAndPrivacy), buttons: [
                                            .default(Text(L10n.paymentActionTerms)) {
                                                self.vm.showTerms()
                                            },
                                            .default(Text(L10n.paymentActionPolicy)) {
                                                self.vm.showPrivacy()
                                            },
                                            .default(Text(L10n.universalActionSupport)) {
                                                self.vm.showSupport()
                                            },
                                            .cancel()
                                        ])
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            self.showPrivacySheet = true
                                        }
                                    }
                            }
                            .padding(.top, 16)
                        }
                        .frame(maxWidth: 500)
                        .padding()
                        .alert(isPresented: self.$vm.showError) {
                            Alert(title: Text(L10n.paymentAlertErrorHeader), message: Text(self.vm.error!),
                                dismissButton: Alert.Button.default(
                                    Text(L10n.universalActionClose), action: { self.vm.cancel() }
                                )
                            )
                        }
                        .onAppear {
                            self.vm.fetchOptions()
                        }
                        Spacer()
                    }

                    // Overlay when loading or error
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            if self.vm.working {
                                if #available(iOS 14.0, *) {
                                    ProgressView()
                                        .padding(.bottom)
                                } else {
                                    SpinnerView()
                                        .frame(width: 24, height: 24)
                                        .padding(.bottom)
                                }
                                Text(L10n.universalStatusProcessing)
                                    .multilineTextAlignment(.center)
                            } else if self.vm.accountActive {
                                Text(L10n.errorPaymentCanceled)
                                    .multilineTextAlignment(.center)
                            } else if self.vm.error != nil {
                                Text(errorDescriptions[CommonError.paymentFailed]!)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .background(Color.cPrimaryBackground)
                    .opacity(self.vm.working || self.vm.error != nil || self.vm.options.isEmpty || self.vm.accountActive ? 1.0 : 0.0)
                    .transition(.opacity)
                    .animation(
                        Animation.easeIn(duration: 0.3).repeatCount(1)
                    )
                    .frame(maxWidth: 500)
                    .padding()
                }
            }
        }
    }
}

struct PaymentGatewayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentGatewayView(vm: PaymentGatewayViewModel(mocked: true), activeSheet: .constant(nil))
            PaymentGatewayView(vm: PaymentGatewayViewModel(), activeSheet: .constant(nil))
                .environment(\.sizeCategory, .extraExtraExtraLarge)
            PaymentGatewayView(vm: PaymentGatewayViewModel(), activeSheet: .constant(nil))
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))
        }
    }
}
