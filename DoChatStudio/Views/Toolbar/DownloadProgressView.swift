//
//  DownloadProgressView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import Foundation
import SwiftUI
import Charts

struct DownloadProgressView: View {
    let progress: Progress
    let fractionCompleted: Double
    
    @State private var isShowingDownload = false
    
    var body: some View {
        VStack {
            ProgressView(value: fractionCompleted) {
                HStack {
                    Text(progress.localizedAdditionalDescription)
                        .bold()
                    Spacer()
                    Text(progress.localizedDescription)
//                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(progress.throughput ?? 0), countStyle: .file))")
                }
            }
            .padding()
        }
    }
}
    #Preview {
        DownloadProgressView(progress: Progress(totalUnitCount: 6), fractionCompleted: 50.0)
    }

