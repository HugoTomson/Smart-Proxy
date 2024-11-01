import Foundation
import GRDB
import Libbox

public extension Profile { 
    nonisolated func changeTypeProfile(doAllTrafic :Bool ) async throws {
        var newConfig = try read()
        let pattern = "\"route(?s).*(?=,(?s).*\"dns\")"
        var routeConfig = UserDefaults.standard.string(forKey: "routeConfig") ?? ""
        if !doAllTrafic{
            newConfig = removeRouteConfigFromJson(jsonString: newConfig)
        }else {
            if !routeConfig.isEmpty{
                newConfig = addRouteConfigToJson(jsonString: newConfig)
            }
        }
        //   print(routeConfig);
        try write(newConfig)
        try await ProfileManager.update(self)
    }
    
    func removeRouteConfigFromJson(jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8) else {
            return ""
        }
        
        do {
            if var json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                if let routeConfig = json.removeValue(forKey: "route") as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: routeConfig, options: [])
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            UserDefaults.standard.set(jsonString, forKey: "routeConfig")
                        }
                    } catch {
                        print("Ошибка при сериализации JSON: \(error.localizedDescription)")
                    }
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
            }
        } catch {
            print("Error parsing JSON: \(error.localizedDescription)")
        }
        return ""
    }
    
    
    func addRouteConfigToJson(jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8) else {
            return jsonString
        }
        
        do {
            if var json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if json["route"] != nil {
                    return jsonString
                }
                if let routeConfigString = UserDefaults.standard.string(forKey: "routeConfig"),
                   let routeConfigData = routeConfigString.data(using: .utf8),
                   let routeConfigJson = try JSONSerialization.jsonObject(with: routeConfigData, options: []) as? [String: Any] {
                    
                    json["route"] = routeConfigJson
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
            }
        } catch {
            print("Ошибка при работе с JSON: \(error.localizedDescription)")
        }
        
        return jsonString
    }
    
}
