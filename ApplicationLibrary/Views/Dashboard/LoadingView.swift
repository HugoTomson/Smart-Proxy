//
//  LoadingView.swift
//  ApplicationLibrary
//
//  Created by  mac user 2 on 12.09.2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack { 
//            ProgressView()
//                .progressViewStyle(CircularProgressViewStyle())
//                .scaleEffect(1.5)
//                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            Text("Smart Proxy")
                .font(.system(size: 34))
                .fontWeight(.bold)
                .offset(y: -230)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(Color("background"))
    }
}
