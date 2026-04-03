//
//  MessageView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import AVKit
import SwiftUI

/// A view that displays a single message in the chat interface.
/// Supports different message roles (user, assistant, system) and media attachments.
struct MessageView: View {
    
    @Binding var style:StyleModel
    
    /// The message to be displayed
    let message: Message

    /// Creates a message view
    /// - Parameter message: The message model to display


    var body: some View {
        
   
        switch message.role {
        case .prompt:
            HStack {
                Text(.init(message.content))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            }
        
        case .user:
            VStack{
            // User messages are right-aligned with colored background
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Display first image if present
                    if let firstImage = message.images.first {
                        AsyncImage(url: firstImage) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: 250, maxHeight: 200)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    
                    // Display first video if present
                    if let firstVideo = message.videos.first {
                        VideoPlayer(player: AVPlayer(url: firstVideo))
                            .frame(width: 250, height: 340)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    
                    // Message content with tinted background.
                    Text(.init(message.content))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8).foregroundStyle(DoStyle.gradient(color:Color(style.userColor?.platformColor ?? style.accent.platformColor)/*.mix(with: .transparentAccent, by: 0.5)*/,angle: (.top,.bottom)).opacity(0.25))
                        )
                        .textSelection(.enabled)
                }
                .background(content:{
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                })
            }
        }
        case .assistant:
            // Assistant messages are left-aligned without background
            if message.content.count == 0 {
                HStack{
                    ProgressView()
                    Image(systemName: "ellipsis")
                        .font(.title)
                        .symbolEffect(.drawOn.individually, options: (.repeat(.continuous)), isActive: true)
                        .foregroundColor(.white)
                        .padding()
                        .background(content:{
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .stroke((style.agentColor?.color ?? .white).mix(with: Color.gray.opacity(0.5), by: 0.5))
                        })
                    Spacer()
                }
            } else {

                VStack{
                    HStack {
                        Text(.init(message.content))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(content:{
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .stroke((style.agentColor?.color ?? .white).mix(with: Color.gray.opacity(0.5), by: 0.5))
                            })
                            .textSelection(.enabled)
                        Spacer()
                        VStack{
                            GenerationInfoView(style: $style, message: message)
                                .background(content:{
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.gray.opacity(0.05))
                                    
                                })
                                .frame(maxWidth: 275, maxHeight: 200)
                            //                            .background(Rectangle().stroke(.orange))
//                            Rectangle()
//                                .fill(.clear)
                            //                            .background(Rectangle().stroke(.blue))
                            Spacer()
                        }
                        
                        //                    .background(Rectangle().stroke(.green))
                    }
                    //                .background(Rectangle().stroke(.red))
                }
                HStack{
                    TimeStampView(message: message)
                        .padding([.leading], 4)
                    Spacer()
                }
                
                Divider().foregroundStyle(style.accent)
            }

        case .system:
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageView(style:.constant(StyleModel()), message: .system("You are a helpful assistant."))

        MessageView(style:.constant(StyleModel()), message:
            .user(
                "Here's a photo",
                images: [URL(string: "https://picsum.photos/200")!]
            )
        )

        MessageView(style:.constant(StyleModel()), message: .assistant("I see your photo!"))
    }
    .padding()
}
