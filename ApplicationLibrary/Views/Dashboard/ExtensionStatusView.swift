import Libbox
import Library
import SwiftUI

public struct ExtensionStatusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var commandClient = CommandClient(.status)
    @State private var columnCount: Int = 4
    @State private var alert: Alert?
    
    private let infoFont = Font.system(.caption, design: .monospaced)
    
    public init() {}
    public var body: some View {
        if columnCount == 1 {
            ScrollView {
                body0
            }
        } else {
            body0
        }
    }
    
    public var body0: some View {
        viewBuilder {
            VStack {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columnCount), alignment: .leading) {
                    if ApplicationLibrary.inPreview {
                        
                        StatusItem(NSLocalizedString("speed", comment: "Speed")) {
                            StatusLine(NSLocalizedString("uplink", comment: "Uplink"), "38 B/s")
                            StatusLine(NSLocalizedString("downlink", comment: "Downlink"), "249 MB/s")
                        }
                        StatusItem(NSLocalizedString("totalTraffic", comment: "Traffic Total")) {
                            StatusLine(NSLocalizedString("uplink", comment: "Uplink"), "52 MB")
                            StatusLine(NSLocalizedString("downlink", comment: "Downlink"), "5.6 GB")
                        }
                    } else if let message = commandClient.status {
                        //                        StatusItem("Status") {
                        //                            StatusLine("Memory", LibboxFormatMemoryBytes(message.memory))
                        //                            StatusLine("Goroutines", "\(message.goroutines)")
                        //                        }
                        //                        StatusItem("Connections") {
                        //                            StatusLine("Inbound", "\(message.connectionsIn)")
                        //                            StatusLine("Outbound", "\(message.connectionsOut)")
                        //                        }
                        if message.trafficAvailable {
                            StatusItem(NSLocalizedString("speed", comment: "Speed")) {
                                StatusLine(NSLocalizedString("uplink", comment: "Uplink"), "\(LibboxFormatBytes(message.uplink))/s")
                                StatusLine(NSLocalizedString("downlink", comment: "Downlink"), "\(LibboxFormatBytes(message.downlink))/s")
                            }
                            StatusItem(NSLocalizedString("totalTraffic", comment: "Traffic Total")) {
                                StatusLine(NSLocalizedString("uplink", comment: "Uplink"), LibboxFormatBytes(message.uplinkTotal))
                                StatusLine(NSLocalizedString("downlink", comment: "Downlink"), LibboxFormatBytes(message.downlinkTotal))
                            }
                        }
                    } else {
                        StatusItem(NSLocalizedString("speed", comment: "Speed")) {
                            StatusLine("Uplink", "...")
                            StatusLine(NSLocalizedString("downlink", comment: "Downlink"), "...")
                        }
                        StatusItem(NSLocalizedString("totalTraffic", comment: "Traffic Total")) {
                            StatusLine(NSLocalizedString("uplink", comment: "Uplink"), "...")
                            StatusLine(NSLocalizedString("downlink", comment: "Downlink"), "...")
                        }
                    }
                }.background {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .frame(height: 1)
                            .onChangeCompat(of: geometry.size.width) { newValue in
                                updateColumnCount(newValue)
                            }
                            .onAppear {
                                updateColumnCount(geometry.size.width)
                            }
                    }.padding()
                }
            }
            .frame(alignment: .topLeading)
            .padding([.top, .leading, .trailing])
        }
        .onAppear {
            commandClient.connect()
        }
        .onDisappear {
            commandClient.disconnect()
        }
        .onChangeCompat(of: scenePhase) { newValue in
            if newValue == .active {
                commandClient.connect()
            } else {
                commandClient.disconnect()
            }
        }
        .alertBinding($alert)
    }
    
    private func updateColumnCount(_ width: Double) {
        let v = Int(Int(width) / 155)
        let new = v <= 1 ? 1 : (v > 4 ? 4 : (v % 2 == 0 ? v : v - 1))
        
        if new != columnCount {
            columnCount = new
        }
    }
    
    private struct StatusItem<T>: View where T: View {
        private let title: String
        @ViewBuilder private let content: () -> T
        
        init(_ title: String, @ViewBuilder content: @escaping () -> T) {
            self.title = title
            self.content = content
        }
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                    Spacer()
                }.padding(.bottom, 8)
                content()
            }
            .frame(minWidth: 125, alignment: .topLeading)
#if os(tvOS)
            .padding(EdgeInsets(top: 20, leading: 26, bottom: 20, trailing: 26))
#else
            .padding(EdgeInsets(top: 10, leading: 13, bottom: 10, trailing: 13))
#endif
            .background(Color("secondaryBackground"))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        
        private var backgroundColor: Color {
#if os(iOS)
            return Color(uiColor: .secondarySystemGroupedBackground)
#elseif os(macOS)
            return Color(nsColor: .textBackgroundColor)
#elseif os(tvOS)
            return Color(uiColor: .black)
#endif
        }
    }
    
    private struct StatusLine: View {
        private let name: String
        private let value: String
        
        init(_ name: String, _ value: String) {
            self.name = name
            self.value = value
        }
        
        var body: some View {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                Text(value)
                    .font(.subheadline)
                
            }
        }
    }
}
