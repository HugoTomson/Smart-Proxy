import Foundation
import Libbox
import Library
import SwiftUI

@MainActor
public struct InstallButtonView: View {
    @State private var alert: Alert?

    private let callback: () async -> Void
    public init(_ callback: @escaping (() async -> Void)) {
        self.callback = callback
    }
    
    private func installProfile() async {
        do {
            try await ExtensionProfile.install()
            await callback()
        } catch {
           // alert = Alert(error)
        }
    }
    
    public var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let width: CGFloat = min(260, screenWidth - 80)
        let height: CGFloat = width / 2.2
        
       return VStack {
            Spacer()
                .frame(height: 40)
            Spacer()
            
            ZStack{
                VStack {
                    Text(NSLocalizedString("pressToTurnVPN", comment:"Press the button\nto turn on VPN"))
                        .multilineTextAlignment(.center)
                    ZStack{
                        
                   Toggle("", isOn: .constant(false))
                        .toggleStyle(CustomSwitcher())
                        .disabled(true)
                    Rectangle()
                            .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity: 0.01))
                        .frame(width: width+20,height: height+20)
                        .onTapGesture {
                            Task {
                                await installProfile()
                            }
                        }
                    
                }
                      
                        

                    
                    Text(  NSLocalizedString("vpnIsOff", comment:"VPN is OFF"))
                        .foregroundColor(Color("basic"))
                }
                .ignoresSafeArea()
                
            }
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 100)
                VStack(alignment: .leading, spacing: 10) {
                    VStack {
                        Toggle(NSLocalizedString("allTrafficTogle", comment:"Smart VPN") , isOn:  .constant(false))
                            .disabled(true)
                        
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
                    Task {
                        await installProfile()
                    }
                }
                Spacer().frame(width: 10)
                HStack {
                    
                    
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 24))
                        .foregroundColor(Color("basic"))
                    
                }
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(Color("secondaryBackground"))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .onTapGesture {
                    Task {
                        await installProfile()
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 30, trailing: 16))
            
        }.background(Color("background"))
            .alertBinding($alert)
    }
    
}
