import Foundation
import Libbox
import Library
import SwiftUI

@MainActor
public struct ActiveDashboardViewProxy: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.selection) private var parentSelection
    @EnvironmentObject private var environments: ExtensionEnvironments
    @EnvironmentObject private var profile: ExtensionProfile
    @State private var isLoading = true
    @State private var profileList: [ProfilePreview] = []
    @State private var selectedProfileID: Int64 = 0
    @State private var doAllTraffic: Bool = false
    @Binding private var alert: Alert?
    @State private var selection = DashboardPage.overview
    @State private var systemProxyAvailable = false
    @State private var systemProxyEnabled = false

    public init(  _ alert: Binding<Alert?>) {
        _alert = alert
    }
    
    public var body: some View {
        if isLoading {
            LoadingView().onAppear {
                Task {
                    doAllTraffic = await SharedPreferences.doAllTrafic.get()
                    await doReload()
                }
            }
        } else {
            if ApplicationLibrary.inPreview {
                body1
            } else {
                body1
                    .onAppear {
                        Task {
                            await doReloadSystemProxy()
                        }
                    }
                    .onChangeCompat(of: profile.status) { newStatus in
                        if newStatus == .connected {
                            Task {
                                await doReloadSystemProxy()
                            }
                        }
                    }
            }
        }
    }

    private var body1: some View {
        VStack {
            #if os(iOS) || os(tvOS)
//                if ApplicationLibrary.inPreview || profile.status.isConnectedStrict {
//                    OverviewViewProxy($profileList, $selectedProfileID, $systemProxyAvailable, $systemProxyEnabled, $doAllTraffic, $isLoading, $alert )
////
//                } else {
                         OverviewViewProxy($profileList, $selectedProfileID, $systemProxyAvailable, $systemProxyEnabled, $doAllTraffic, $isLoading, $alert ) 
               // }
            #elseif os(macOS)
                OverviewView($profileList, $selectedProfileID, $systemProxyAvailable, $systemProxyEnabled)
            #endif
        }
        .onReceive(environments.profileUpdate) { _ in
            Task {
                await doReload()
            }
        }
        .onReceive(environments.selectedProfileUpdate) { _ in
            Task {
                selectedProfileID = await SharedPreferences.selectedProfileID.get()
                if profile.status.isConnected {
                    await doReloadSystemProxy()
                }
            }
        }
        
    }
 
    private func doReload() async {
        defer {
            isLoading = false
        }
        if ApplicationLibrary.inPreview {
            profileList = [
                ProfilePreview(Profile(id: 0, name: "profile local", type: .local, path: "")),
                ProfilePreview(Profile(id: 1, name: "profile remote", type: .remote, path: "", lastUpdated: Date(timeIntervalSince1970: 0))),
            ]
            systemProxyAvailable = true
            systemProxyEnabled = true
            selectedProfileID = 0

        } else {
            do {
                profileList = try await ProfileManager.list().map { ProfilePreview($0) }
                if profileList.isEmpty {
                    return
                }
                selectedProfileID = await SharedPreferences.selectedProfileID.get()
                if profileList.filter({ profile in
                    profile.id == selectedProfileID
                })
                .isEmpty {
                    selectedProfileID = profileList[0].id
                    await SharedPreferences.selectedProfileID.set(selectedProfileID)
                }

            } catch {
                alert = Alert(error)
                return
            }
        }
        environments.emptyProfiles = profileList.isEmpty
    }

    private nonisolated func doReloadSystemProxy() async {
        do {
            let status = try LibboxNewStandaloneCommandClient()!.getSystemProxyStatus()
            await MainActor.run {
                systemProxyAvailable = status.available
                systemProxyEnabled = status.enabled
            }
        } catch {
//            await MainActor.run {
//                alert = Alert(error)
//            }
        }
    }
}
