import Libbox
import Library
import SwiftUI

@MainActor
public struct DashboardViewProxy: View {
    #if os(macOS)
        @Environment(\.controlActiveState) private var controlActiveState
        @State private var isLoading = true
        @State private var systemExtensionInstalled = true
    #endif

    public init() {}
    public var body: some View {
        viewBuilder {
            #if os(macOS)
                if Variant.useSystemExtension {
                    viewBuilder {
                        if !systemExtensionInstalled {
                            FormView {
                                InstallSystemExtensionButton {
                                    await reload()
                                }
                            }
                        } else {
                            DashboardView0()
                        }
                    }.onAppear {
                        Task {
                            await reload()
                        }
                    }
                } else {
                    DashboardView0()
                }
            #else
                DashboardView0()
            #endif
        }
        #if os(macOS)
        .onChangeCompat(of: controlActiveState) { newValue in
            if newValue != .inactive {
                if Variant.useSystemExtension {
                    if !isLoading {
                        Task {
                            await reload()
                        }
                    }
                }
            }
        }
        #endif
    }

    #if os(macOS)
        private nonisolated func reload() async {
            let systemExtensionInstalled = await SystemExtension.isInstalled()
            await MainActor.run {
                self.systemExtensionInstalled = systemExtensionInstalled
                isLoading = false
            }
        }
    #endif

    struct DashboardView0: View {
        @EnvironmentObject private var environments: ExtensionEnvironments

        var body: some View {
            if ApplicationLibrary.inPreview { 
                LoadingView()
            } else if environments.extensionProfileLoading {
                LoadingView()
            } else if let profile = environments.extensionProfile {
                DashboardView1().environmentObject(profile)
            } else {
                 
                    InstallButtonView {
                        await environments.reload()
                    }
               
            }
        }
    }

    struct DashboardView1: View {
        @EnvironmentObject private var environments: ExtensionEnvironments
        @EnvironmentObject private var profile: ExtensionProfile
        @State private var alert: Alert?

        var body: some View {
            VStack {
                ActiveDashboardViewProxy($alert)
            }
            .alertBinding($alert)
            .onChangeCompat(of: profile.status) { newValue in
                if newValue == .disconnecting || newValue == .connected {
                    Task {
                        await checkServiceError()
                    }
                }
            }
        }

        private nonisolated func checkServiceError() async {
            var error: NSError?
            let message = LibboxReadServiceError(&error)
            if error != nil {
                return
            }
            await MainActor.run {
                if(message.contains("missing selected")){
                    alert = Alert(title: Text(NSLocalizedString("error", comment: "")), message: Text(NSLocalizedString("copyLink", comment: "")))
                }else{
                    alert = Alert(title: Text("Service Error"), message: Text(message))
                }
            }
        }
    }
}
