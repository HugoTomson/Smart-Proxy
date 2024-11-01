import Foundation
import Libbox
import Library
import SwiftUI

@MainActor
public struct OverviewViewProxy: View {
    @Environment(\.selection) private var selection
    @EnvironmentObject private var environments: ExtensionEnvironments
    @EnvironmentObject private var profile: ExtensionProfile
    @Binding private var profileList: [ProfilePreview]
    @Binding private var selectedProfileID: Int64
    @Binding private var systemProxyAvailable: Bool
    @Binding private var systemProxyEnabled: Bool
    @Binding private var doAllTrafic: Bool
    @Binding private var alert: Alert?
    @State private var reasserting = false
    @Binding private var isLoading: Bool
    @State private var showStartStopBtn: Bool?
    @EnvironmentObject var counter: SingCounter
    
    private var selectedProfileIDLocal: Binding<Int64> {
        $selectedProfileID.withSetter { newValue in
            reasserting = true
            Task { [self] in
                await switchProfile(newValue)
            }
        }
    }
    
    public init(_ profileList: Binding<[ProfilePreview]>, _ selectedProfileID: Binding<Int64>, _ systemProxyAvailable: Binding<Bool>, _ systemProxyEnabled: Binding<Bool>, _ doAllTrafic: Binding<Bool>, _ isLoading: Binding<Bool>, _ alert: Binding<Alert?>) {
        _profileList = profileList
        _selectedProfileID = selectedProfileID
        _systemProxyAvailable = systemProxyAvailable
        _systemProxyEnabled = systemProxyEnabled
        _doAllTrafic = doAllTrafic
        _isLoading = isLoading
        _alert = alert
        showStartStopBtn = true
    }
    
    public var body: some View {
        print(doAllTrafic)
       return VStack {
            Spacer()
                .frame(height: 40)
            Spacer()
            
            ZStack{
                if showStartStopBtn ?? true{  VStack {
                    Text(NSLocalizedString("pressToTurnVPN", comment:"Press the button\nto turn on VPN"))
                        .multilineTextAlignment(.center)
                    
                    StartStopButtonProxy()
                    
                    
                    Text(profile.status.isConnected ? NSLocalizedString(doAllTrafic ? "smartVpnIsOn" : "vpnIsOn", comment:"VPN is ON") : NSLocalizedString("vpnIsOff", comment:"VPN is OFF"))
                        .foregroundColor(profile.status.isConnected ?  Color.green : Color("basic"))
                }
                .ignoresSafeArea()
                }
                if !(showStartStopBtn ?? true)
                {
                    VStack{
                        Text(NSLocalizedString("getConfig", comment: "Configuration Settings"))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                    }
                }
            }
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                ExtensionStatusView().opacity(profile.status.isConnected ? 1 : 0).frame(height: 100)
                VStack(alignment: .leading, spacing: 10) {
                    VStack {
                        Toggle(NSLocalizedString("allTrafficTogle", comment:"Smart VPN") , isOn: $doAllTrafic)
                            .disabled(profileList.isEmpty)
                            .onChange(of: doAllTrafic){ newState in
                                manageAllTrafic()
                            }
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 44)
                    .background(Color("secondaryBackground"))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    
                    Text( NSLocalizedString("routingTraffic", comment:"Routing all traffic through VPN when turned off"))
                        .font(.footnote)
                        .fontWeight(.light)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 13)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture {
                            counter.singCount = counter.singCount+1
                        }
                }
                .padding(EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16))
            }
            HStack {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(Color("basic"))
                    Text(NSLocalizedString("addConfigFromBufer", comment:"Add configuration"))
                        .foregroundColor(Color("basic"))
                    
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(Color("secondaryBackground"))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .onTapGesture {
                    showAlert(titleKey: "configSettings", messageKey: "addFromBufer", primaryButton:
                            .default(Text(NSLocalizedString("add", comment:"Add"))) {
                                if let clipboardText = UIPasteboard.general.string {
                                    if clipboardText.contains("kodalink")
                                    {
                                        if let url = URL(string:clipboardText) {
                                            showStartStopBtn = false
                                            UIApplication.shared.open(url)
                                        }
                                    }else{
                                        openConfig(url: clipboardText)
                                    }
                                }else{
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showAlert(titleKey: "error", messageKey: "copyLink")
                                    }
                                }
                            },
                              secondaryButton: .cancel())
                }
                Spacer().frame(width: 10)
                HStack {
                    NavigationLink(destination: QRCodeScannerView {
                        if $0 == "denied"
                        {
                            showAlert(titleKey: "cameraDisconnect", messageKey: "cameraSettings",
                                      primaryButton: .default(Text(NSLocalizedString("go", comment:"Go")).fontWeight(.semibold), action: {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsURL)
                                }
                            }),
                                      secondaryButton: .cancel(Text(NSLocalizedString("cancel", comment:"Cancel")) )
                            )
                        }else{
                            let t = $0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                openConfig(url: t)
                            }
                        }
                    }
                        .edgesIgnoringSafeArea(.all)) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 24))
                                .foregroundColor(Color("basic"))
                        }
                }
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(Color("secondaryBackground"))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .onTapGesture {
                    
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 30, trailing: 16))
            
        }.background(Color("background"))
            .alertBinding($alert)
            .disabled(!ApplicationLibrary.inPreview && (!profile.status.isSwitchable || reasserting))
        
            .onReceive(environments.profileUpdate) { _ in
                    showStartStopBtn = true
            }
       
        
    }
    
    
    private func switchProfile(_ newProfileID: Int64) async {
        await SharedPreferences.selectedProfileID.set(newProfileID)
        environments.selectedProfileUpdate.send()
        if profile.status.isConnected {
            do {
                try await serviceReload()
            } catch {
                alert = Alert(error)
            }
        }
        reasserting = false
    }
    
    private nonisolated func serviceReload() async throws {
        try LibboxNewStandaloneCommandClient()!.serviceReload()
    }
    
    private nonisolated func setSystemProxyEnabled(_ isEnabled: Bool) async {
        do {
            try LibboxNewStandaloneCommandClient()!.setSystemProxyEnabled(isEnabled)
            await SharedPreferences.systemProxyEnabled.set(isEnabled)
        } catch {
            await MainActor.run {
                alert = Alert(error)
            }
        }
    }
    
    private func manageAllTrafic() {
        Task {
            guard !profileList.isEmpty else { return }
            let localDoAllTrafic = await SharedPreferences.doAllTrafic.get()
            if doAllTrafic != localDoAllTrafic {
                await SharedPreferences.doAllTrafic.set(doAllTrafic)
                guard let profile = try? await ProfileManager.get(selectedProfileID) else {
                    showAlert(titleKey: "error", messageKey: "errorAll")
                    return
                }
                try await profile.changeTypeProfile(doAllTrafic: self.doAllTrafic)
                try await serviceReload()
            }
        }
    }
    
    private func openConfig(url: String){
        var finalUrl = url
        if !finalUrl.contains("kodalink")   {
            finalUrl = "kodalink://config=\(finalUrl)"
        }
        showStartStopBtn = false
        if let urlRes = URL(string: finalUrl) {
            UIApplication.shared.open(urlRes)
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showAlert(titleKey: "error", messageKey: "configWrong",
                          primaryButton: .default(Text(NSLocalizedString("close", comment:"Close"))))
                showStartStopBtn = true
            }
        }
    }
    
    private func showAlert(titleKey: String, messageKey: String, primaryButton: Alert.Button = .default(Text("OK")), secondaryButton: Alert.Button? = nil) {
        if secondaryButton != nil
        { alert = Alert(title: Text(NSLocalizedString(titleKey, comment: "")), message: Text(NSLocalizedString(messageKey, comment: "")), primaryButton: primaryButton, secondaryButton: secondaryButton!)
        }else{
            alert = Alert(title: Text(NSLocalizedString(titleKey, comment: "")), message: Text(NSLocalizedString(messageKey, comment: "")), dismissButton: primaryButton)
        }
    }
}
