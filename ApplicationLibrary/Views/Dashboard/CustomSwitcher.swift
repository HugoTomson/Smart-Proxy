import SwiftUI
import AVKit
import Combine


struct CustomSwitcher: ToggleStyle {
    
    
    func makeBody(configuration: Configuration) -> some View {
        
        let screenWidth = UIScreen.main.bounds.width
        let lineWidth: CGFloat = 9
        let width: CGFloat = min(260, screenWidth - 80)
        let height: CGFloat = width / 2.2
        let paddingCircle: CGFloat = 18
        var sizeCircle: CGFloat {
            return height - paddingCircle * 2
        }
        let fontSize: CGFloat = height / 2
        _ = Color(UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1))
        let circleOffset = configuration.isOn ? (width - sizeCircle) / 2 - paddingCircle : -(width - sizeCircle) / 2 + paddingCircle
        

        return ZStack {
            GIFView(gifName: "switchVideo", isPlaying: configuration.$isOn)
                .frame(width: width - lineWidth+1, height: height - lineWidth+1+16)
                .cornerRadius(height / 2)
               .opacity(configuration.isOn ? 1 : 0)
                .clipped()
        
            RoundedRectangle(cornerRadius: height / 2)
                .frame(width: width, height: height)
                .foregroundColor(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: height / 2)
                        .stroke(Color("basic"), lineWidth: lineWidth)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
            Circle()
                .fill(configuration.isOn ? Color("background").opacity(0.7) : Color("background"))
                .overlay(Circle().stroke(Color("basic"), lineWidth: lineWidth - 2))
            
                .frame(width: sizeCircle, height: sizeCircle)
                .offset(x: circleOffset)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
           
            if !configuration.isOn {
                Text("OFF")
                    .font(.system(size: fontSize))
                    .foregroundColor(Color("basic"))
                    .offset(x: (width / 4)-paddingCircle)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
        .onTapGesture {
            configuration.isOn.toggle()
          
        }
    }
}


class StateManager: ObservableObject {
    @Published var isToggleOn: Bool = false
}

