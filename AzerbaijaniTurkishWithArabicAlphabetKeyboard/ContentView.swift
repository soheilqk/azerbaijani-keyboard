//
//  ContentView.swift
//  AzerbaijaniTurkishWithArabicAlphabetKeyboard
//
//  Created by Soheil on 4/11/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var username: String = ""
    @FocusState private var emailFieldIsFocused: Bool 
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            TextField("test",text: $username)
                .focused($emailFieldIsFocused)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
