import ApplicationLibrary
import Libbox
import Library
import SwiftUI

struct MainViewProxy: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var environments: ExtensionEnvironments
    
    @State private var selection = NavigationPage.dashboard
    @State private var importProfile: LibboxProfileContent?
    @State private var importRemoteProfile: LibboxImportRemoteProfile?
    @State private var alert: Alert?
    @AppStorage("hasFetchedConfig") private var hasFetchedConfig: Bool = false
    
    
    var body: some View {
        if ApplicationLibrary.inPreview {
            body1.preferredColorScheme(.dark)
        } else {
            bodyProxy
        }
    }
    
    var bodyProxy: some View {
        
        NavigationStackCompat {
            DashboardViewProxy()
        }
        .onAppear {
            environments.postReload()
        }
        .alertBinding($alert)
        .onChangeCompat(of: scenePhase) { newValue in
            if newValue == .active {
                environments.postReload()
            }
        }
        .onChangeCompat(of: selection) { newValue in
            if newValue == .logs {
                environments.connectLog()
            }
        }
        .environment(\.selection, $selection)
        .environment(\.importProfile, $importProfile)
        .environment(\.importRemoteProfile, $importRemoteProfile)
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL(perform: openURL)
    }
    
    var body1: some View {
        TabView(selection: $selection) {
            ForEach(NavigationPage.allCases, id: \.self) { page in
                NavigationStackCompat {
                    page.contentView
                        .navigationTitle(page.title)
                }
                .tag(page)
                .tabItem { page.label }
            }
        }
        .onAppear {
            environments.postReload()
        }
        .alertBinding($alert)
        .onChangeCompat(of: scenePhase) { newValue in
            if newValue == .active {
                environments.postReload()
            }
        }
        .onChangeCompat(of: selection) { newValue in
            if newValue == .logs {
                environments.connectLog()
            }
        }
        .environment(\.selection, $selection)
        .environment(\.importProfile, $importProfile)
        .environment(\.importRemoteProfile, $importRemoteProfile)
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL(perform: openURL)
    }
    
    private func openURL(url: URL) {
        
        if url.host == "import-remote-profile" {
            var error: NSError?
            importRemoteProfile = LibboxParseRemoteProfileImportLink(url.absoluteString, &error)
            if let error {
                alert = Alert(error)
                return
            }
            if selection != .profiles {
                selection = .profiles
            }
        } else if url.pathExtension == "bpf" {
            
            do {
                _ = url.startAccessingSecurityScopedResource()
                importProfile = try .from(Data(contentsOf: url))
                url.stopAccessingSecurityScopedResource()
            } catch {
                alert = Alert(error)
                return
            }
            if selection != .profiles {
                selection = .profiles
            }
            
        } else if url.scheme?.contains("kodalink") ?? false{
            hasFetchedConfig = true
            let pattern = "(?<=config=).*"
        
       
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let nsString =  url.absoluteString as NSString
                let results = regex.matches(in:  url.absoluteString, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = results.first {
                    let urlString = nsString.substring(with: match.range).replacingOccurrences(of:  "https//", with:  "https://")
                    let isClean = nsString.contains("clean=1")
                    Task {
                        try await createRemote(urlString: urlString, clean: isClean)
                    }
                    var error: NSError?
                    if let error {
                        alert = Alert(error)
                        return
                    }
                    if selection != .profiles {
                        selection = .profiles
                    }
                }
            } catch let error {
                print("Invalid regex: \(error.localizedDescription)")
            }
            
            
            
        }else{
            alert = Alert(errorMessage: "Handled unknown URL \(url.absoluteString)")
        }
    }
    
    private func createRemote(urlString: String, clean: Bool) async throws
    {
        var error: NSError?
        let nextProfileID = try await ProfileManager.nextID()
        let remoteContent = try HTTPClient().getString(urlString)
        
        LibboxCheckConfig(remoteContent, &error)
        if let error {
            throw error
        }
        let profileConfigDirectory = FilePath.sharedDirectory.appendingPathComponent("configs", isDirectory: true)
        try FileManager.default.createDirectory(at: profileConfigDirectory, withIntermediateDirectories: true)
        let profileConfig = profileConfigDirectory.appendingPathComponent("config_\(nextProfileID).json")
        try remoteContent.write(to: profileConfig, atomically: true, encoding: .utf8)
        let savePath = profileConfig.relativePath
        let remoteURL = urlString
        if clean{
            do {
                let profiles = try await ProfileManager.list()
                for profile in profiles {
                    try await ProfileManager.delete(profile)
                }
            } catch {
                print("Ошибка: \(error.localizedDescription)")
            }
        }
        let lastUpdated : Date = .now
        try await ProfileManager.create(Profile(
            name: "VPN_\(nextProfileID)",
            type: .remote,
            path: savePath,
            remoteURL: remoteURL,
            autoUpdate: true,
            autoUpdateInterval: 60,
            lastUpdated: lastUpdated
        ))
        
        try   UIProfileUpdateTask.configure()
        environments.profileUpdate.send()
    }
}
