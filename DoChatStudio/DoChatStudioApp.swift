//
//  DoChatStudioApp.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI

@main
struct DoChatStudioApp: App {
    @Environment(\.colorScheme) var colorScheme

    var body: some Scene {
        DocumentGroup(newDocument: DoChatStudioDocument(text: "")) { file in
            Group {
                ContentView(document: file.document)
            }
            .onAppear() {
                print("file:\(file)")
            }
        }
    }
}
