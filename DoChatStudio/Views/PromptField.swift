//
//  PromptField.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import SwiftUI

struct PromptField: View {
    @FocusState private var isUsernameFocused: Bool

    @Binding var prompt: String
    @State private var task: Task<Void, Never>?
    @EnvironmentObject var document: DoChatStudioDocument
    
    let sendButtonAction: () async -> Void
    let mediaButtonAction: (() -> Void)?

    fileprivate func startGeneration() {
        withAnimation(.linear(duration: 1)) {
            dashPhase = 0
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
    }
    
    
    private var isRunning: Bool {
        withAnimation(.linear(duration: 1)) {
            
            task != nil && !(task!.isCancelled)
        }
    }

    private func removeTask() {
        task = nil
    }

    
    let timer = Timer.publish(every: 1 / 4, on: .main, in: .common).autoconnect()

    @State private var startPoint: UnitPoint = UnitPoint(x: 0, y: 0)
    @State private var endPoint: UnitPoint = UnitPoint(x: 1, y: 1)
    
//    let modelStateColor: Color = document.chatModel?.selectedModel?.state?.color ?? .red
    var gradient: LinearGradient {
        withAnimation(.linear(duration: 1)) {
            
            LinearGradient(
                colors: [
                    (document.chatModel?.selectedModel?.state?.color ?? .accentColor).opacity(0.4),
                    .transparentAccent.mix(with: .white, by: 0.25).opacity(0.4),
                    (document.chatModel?.selectedModel?.state?.color ?? .accentColor).opacity(0.4)],
                startPoint: startPoint,
                endPoint: endPoint
                
            )
        }
    }
    @State var dashPhase: CGFloat = 0
    
    var strokeStyle: StrokeStyle {
        withAnimation(.linear(duration: 1)) {
            
            //dashPhase = isRunning ? dashPhase : 0
            return isRunning ?
            StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [-110], dashPhase: dashPhase) :
            StrokeStyle(lineWidth: 4)}
    }

    var body: some View {
        HStack {
            if let mediaButtonAction {
                Button {
                        mediaButtonAction()
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .shadow(color: .black, radius: 2.0)
                        .frame(width:36, height: 36)
                        .background(Circle().fill(DoStyle.gradient(color: .accentColor.mix(with: .black, by: 0.05).opacity(0.25))))
                        .overlay(
                            Circle()
                                .fill(Color.clear)
                                .stroke(DoStyle.gradient(color: .accentColor.mix(with: .black, by: 0.05).opacity(0.5)), style: StrokeStyle(lineWidth: 4.0))
                                .shadow(radius: 2)
                                .rotationEffect(Angle(degrees: 180))
                        )
                }
                .buttonStyle(.plain)
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
                        startGeneration()
                }
                .textFieldStyle(.plain)
                .focusable(true, interactions: .automatic)
                .focused($isUsernameFocused)
                .onAppear{
                    isUsernameFocused.toggle()
                }
//                .on
            Button {
                    startGeneration()
            } label: {
                
                Image(systemName: isRunning == false ? "play.fill" : "stop.fill")
                    .shadow(color: .black, radius: 2.0)
                    .frame(width:36, height: 36)
                    .background(Circle().fill(DoStyle.gradient(color: (document.chatModel?.selectedModel?.state?.color ?? .accentColor).mix(with: .black, by: 0.05).opacity(0.25))))
                    .overlay(
                        Circle()
                            .fill(Color.clear)
                            .stroke(isRunning ? gradient : DoStyle.gradient(color: (document.chatModel?.selectedModel?.state?.color ?? .accentColor).mix(with: .black, by: 0.05).opacity(0.5)), style: strokeStyle)
                            .shadow(radius: 2)
                            .rotationEffect(Angle(degrees: 180))
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(isRunning ? .cancelAction : .defaultAction)
        }
        .disabled(document.chatModel?.selectedModel?.modelDownloadProgress != nil)
        .ignoresSafeArea(.container)
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 1/4)) {
                let previousStartPoint = startPoint
                startPoint = UnitPoint(x: 1 - previousStartPoint.y, y: previousStartPoint.x)
                let previousEndPoint = endPoint
                endPoint = UnitPoint(x: 1 - previousEndPoint.y, y: previousEndPoint.x)
                dashPhase = /*dashPhase > 2220 ? -2220 : */(dashPhase - 15)
            }
        }
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

