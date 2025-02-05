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
        DocumentGroup(newDocument: DoChatStudioDocument()) { file in
                ContentView(document: file.document)
//                .background(.white)
//                .colorScheme(.light)
                            .background(colorScheme == .dark
                                        ?
                                .brown.opacity(0.25)
                                        :
                                    .brown.opacity(0.25)
                            )
                            .blendMode(.normal/*.luminosity*/)
        }
    }
}
