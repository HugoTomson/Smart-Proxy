import Foundation
import Combine

public class ConfigService: ObservableObject {
    @Published public var config: Config?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
   
    public init(){}
    
    public func fetchConfig() {
        guard let url = URL(string: "https://api.pandatainment.ru/referal/getConfig/") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .handleEvents(receiveOutput: { data in 
                           if let jsonString = String(data: data, encoding: .utf8) {
                               print("Received JSON: \(jsonString)")
                           }
                       })
            .decode(type: Config.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    DispatchQueue.main.async{
                        self.config = Config(config:  "error")
                    }
                }
            }, receiveValue: { config in
                self.config = config
            })
            .store(in: &cancellables)
    }
}
