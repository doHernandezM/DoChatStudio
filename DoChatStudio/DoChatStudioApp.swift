//
//  DoChatStudioApp.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI

@main
struct DoChatStudioApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: DoChatStudioDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
