//
//  ContentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: DoChatStudioDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(DoChatStudioDocument()))
}
