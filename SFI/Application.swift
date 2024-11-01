import Foundation
import Library
import SwiftUI

@main
struct Application: App {
    @UIApplicationDelegateAdaptor private var appDelegate: ApplicationDelegate
    @StateObject private var environments = ExtensionEnvironments()
    @AppStorage("hasFetchedConfig") private var hasFetchedConfig: Bool = false
    @StateObject private var configService = ConfigService()
    @StateObject private var counter = SingCounter()
    
    var body: some Scene {
        WindowGroup {
            contentView()
                .environmentObject(environments)
                .environmentObject(counter)
                .onAppear {
                    if !hasFetchedConfig {
                        configService.fetchConfig()
                    }
                }
            
                .onChange(of: configService.config) { newConfig in
                    if let config = newConfig {
                        if(!hasFetchedConfig && config.config != "error"){
                            if let url = URL(string: "kodalink://config=\(config.config)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    hasFetchedConfig = true
                }
        }
    }
    
    @ViewBuilder
       private func contentView() -> some View {
           if counter.singCount >= 10 {
               MainView()
           } else {
               MainViewProxy()
           }
       }
}
