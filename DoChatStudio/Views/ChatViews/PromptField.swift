//
//  PromptField.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

// Provides the prompt editor and animated send, stop, and media attachment controls.

import SwiftUI

struct PromptField: View {
    @FocusState private var isUsernameFocused: Bool

    @Binding var style:StyleModel
    @Binding var prompt: String
    @State private var task: Task<Void, Never>?
    @EnvironmentObject var document: DoChatStudioDocument
//    @Environment(\.saveAction) private var saveAction

    /// Async callback supplied by `ChatView`; in production this invokes
    /// `ChatModel.generate()` and remains active for the streamed response.
    let sendButtonAction: () async -> Void
    let mediaButtonAction: (() -> Void)?

    /// Starts the UI task that owns one generation request.
    ///
    /// Cancelling this task propagates cancellation to `ChatModel.generate()`,
    /// while the model's observable state drives the animated control styling.
    fileprivate func startGeneration() {
        withAnimation(.linear(duration: 1/5)) {
            document.chat.style.currentSelectedTab = 2
            dashPhase = 0
            
            task?.cancel()
            removeTask()
            
            task = Task {
                if prompt.count != 0 {
                    await sendButtonAction()
                }
                removeTask()
            }
        }
    }
    
    private func removeTask() {
        task = nil
    }

    
    let timer = Timer.publish(every: 1 / 4, on: .main, in: .common).autoconnect()

    @State private var startPoint: UnitPoint = UnitPoint(x: 0, y: 0)
    @State private var endPoint: UnitPoint = UnitPoint(x: 1, y: 1)
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                (document.chat.model?.state?.color ?? style.accent).opacity(0.4),
                style.transparentAccent.mix(with: .white, by: 0.25).opacity(0.4),
                (document.chat.model?.state?.color ?? style.accent).opacity(0.4)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    var strokeStyle: StrokeStyle {
        isRunning
        ? StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [-110], dashPhase: dashPhase)
        : StrokeStyle(lineWidth: 4)
    }

    /// Reflects the lifetime of the UI task, not the lower-level MLX model state.
    var isRunning: Bool {
        task != nil && !(task!.isCancelled)
    }

    @State var dashPhase: CGFloat = 0
    
    
    var body: some View {
        HStack {
            if let mediaButtonAction {
                Button {
                        mediaButtonAction()
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .shadow(color: .black, radius: 2.0)
                        .frame(width:36, height: 36)
                        .font(.system(.title3))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.green, Color.primary)
                        .background(Circle().fill(DoStyle.gradient(color: style.accent.mix(with: .black, by: 0.05).opacity(0.25))))
                        .overlay(
                            Circle()
                                .fill(Color.clear)
                                .stroke(DoStyle.gradient(color: style.accent.mix(with: .black, by: 0.05).opacity(0.5)), style: StrokeStyle(lineWidth: 4.0))
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
                    if prompt.count == 0 {
                        return
                    }
                        startGeneration()
                }
                .textFieldStyle(.plain)
            #if os(macOS)
                .focusable(true, interactions: .automatic)
            #else
                .focused($isUsernameFocused)
            #endif
                .onAppear{
                    isUsernameFocused = true
                }
//                .on
            Button {
                startGeneration()
            } label: {
                
                Image(systemName: isRunning == false ? "play.fill" : "stop.fill")
                    .shadow(color: .black, radius: 2.0)
                    .frame(width:36, height: 36)
                    .font(.system(.title3))
                    .foregroundStyle(Color.primary)
                    .background(Circle().fill(DoStyle.gradient(color: (document.chat.model?.state?.color ?? style.accent).mix(with: .black, by: 0.05).opacity(0.25))))
                    .overlay(
                        Circle()
                            .fill(Color.clear)
                            .stroke(isRunning ? gradient : DoStyle.gradient(color: (document.chat.model?.state?.color ?? style.accent).mix(with: .black, by: 0.05).opacity(0.5)), style: strokeStyle)
                            .shadow(radius: 2)
                            .rotationEffect(Angle(degrees: 180))
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(isRunning ? .cancelAction : .defaultAction)
        }
        .disabled(document.chat.model?.modelDownloadProgress != nil)
//        .ignoresSafeArea(.container)
        // Conditionally animate only while running
        .onReceive(timer) { _ in
            guard isRunning else { return }
            withAnimation(.linear(duration: 1/4)) {
                let prevStart = startPoint
                startPoint = UnitPoint(x: 1 - prevStart.y, y: prevStart.x)
                let prevEnd = endPoint
                endPoint = UnitPoint(x: 1 - prevEnd.y, y: prevEnd.x)
                dashPhase -= 15
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard() // or isUsernameFocused = false
                }
            }
        }
        #endif
    }
}

#Preview {
    PromptField(style: .constant(StyleModel()), prompt: .constant("")) {
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
