import SwiftUI

// Модель данных для хранения состояния счетчика
public class SingCounter: ObservableObject {
     @Published public var singCount: Int = 0 
    public init(){}
}
