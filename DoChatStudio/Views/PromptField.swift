//
//  PromptField.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import SwiftUI

struct PromptField: View {
    @Binding var prompt: String
    @State private var task: Task<Void, Never>?
    @EnvironmentObject var document: DoChatStudioDocument
    
    let sendButtonAction: () async -> Void
    let mediaButtonAction: (() -> Void)?

    fileprivate func startGeneration() {
        if isRunning {
            task?.cancel()
            removeTask()
            
        } else {
            task = Task {
                await sendButtonAction()
                document.save()
                removeTask()
                
            }
        }
    }
    
    var body: some View {
        HStack {
            if let mediaButtonAction {
                Button(action: mediaButtonAction) {
                    Image(systemName: "photo.badge.plus")
                }
            }

            TextField("Prompt", text: $prompt, axis: .vertical)
                .onKeyPress(keys: [.return]) { event in
                    if event.modifiers == .shift {
                        prompt += "\n"
                           return .handled
                       }
                       return .ignored
                    }
                .onSubmit {
                    withAnimation {
                        startGeneration()
                    }
                }
            Button {
                withAnimation {
                    startGeneration()
                }
            } label: {
                
                Image(systemName: isRunning == false ? "play.fill" : "stop.fill")
                    .frame(width:36, height: 36)
                    .background(Circle().fill(DoStyle.gradient(color: .accentColor.mix(with: .black, by: 0.25))))
                    .overlay(Circle().fill(Color.clear)
                        .strokeBorder(DoStyle.gradient(color: .accentColor.mix(with: .black, by: 0.35)), lineWidth: 2)
                        .shadow(radius: 2)
                        .rotationEffect(Angle(degrees: 180)))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(isRunning ? .cancelAction : .defaultAction)
        }
        .ignoresSafeArea(.container)
    }

    private var isRunning: Bool {
        task != nil && !(task!.isCancelled)
    }

    private func removeTask() {
        task = nil
    }
}

#Preview {
    PromptField(prompt: .constant("")) {
    } mediaButtonAction: {
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

