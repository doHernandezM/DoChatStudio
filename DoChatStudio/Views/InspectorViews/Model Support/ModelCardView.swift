//
//  ModelInfoCardView.swift
//  DoChatStudio
//
//  Created by Cosas on 9/28/25.
//

import SwiftUI

enum ModelCardState: Equatable {
    case hidden
    case loading
    case loaded(String)
    case failed(Error?) // optional, useful for debugging or a retry UI
    
    static func == (lhs: ModelCardState, rhs: ModelCardState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let a), .loaded(let b)):
            return a == b
        case (.failed(let a), .failed(let b)):
            return a?.localizedDescription == b?.localizedDescription
        default:
            return false
        }
    }
}

struct ModelCardView: View {
    @Binding var modelName: String?
    @Binding var modelCardState: ModelCardState
    @Binding var fetchTask: Task<Void, Never>?
    var style: StyleModel
    
    var body: some View {
        Group {
            if let name = modelName {
                switch modelCardState {
                case .hidden:
                    HStack {
                        Spacer()
                    }
                case .loading:
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(style.accent)
                        Text("Fetching model\nReadMe…")
                        Spacer()
                    }
                    .padding(.vertical, 4)
                case .loaded(let markdown):
                    HStack {
                        Text("ReadMe:")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    // If you want Markdown rendering (optional):
                    ScrollView(.vertical, content: {
                        Text(.init(markdown))
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                            .tint(style.accent)
                    })
                    
                case .failed:
                    // Optional: show a small error & retry
                    VStack{
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.red, style.accent)
                            Text("Failed to load model details for:\n\(name)")
                            Button(action: {
                                modelCardState = .loading
                                fetchTask?.cancel()
                                fetchTask = fetchMarkdownTask(name: name)
                            }, label: {
                                Text("Retry")
                                    .padding()
                            })
                            .buttonStyle(.plain)
                            .background(content:{
                                RoundedRectangle(cornerRadius: 8 )
                                    .stroke(Color.red.opacity(0.7))
                                    .background(Color.red.opacity(0.1))
                            })
                        }
                        .padding()
                    }
                    .padding([.leading])
                }
            } else {
                VStack{
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.red, style.accent)
                            .padding([.leading])
                        
                        Text("No model is Selected. Please select a model to see its ReadMe.")
                        //                        .padding()
                        Spacer()
                    }
                    .padding()
                    .background(content:{
                        RoundedRectangle(cornerRadius: 8 )
                            .stroke(Color.red.opacity(0.7))
                            .background(Color.red.opacity(0.1))
                    })
                }
                .padding([.leading])
                
            }
        }
    }
    
    func fetchMarkdownTask(name: String) -> Task<Void, Never> {
        return Task { @MainActor in
            do {
                let markdown = try await ModelModel.hub.fetchModelCardMarkdown(repoId: name)
                modelCardState = .loaded(markdown ?? "Model readme not available.")
            } catch {
                modelCardState = .failed(error)
            }
        }
    }
}

#Preview {
    ModelCardView(modelName: .constant(""), modelCardState: .constant(.hidden), fetchTask: .constant(nil), style: StyleModel())
}

