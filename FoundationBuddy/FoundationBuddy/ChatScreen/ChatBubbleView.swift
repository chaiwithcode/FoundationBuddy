//
//  ChatBubbleView.swift
//  FoundationBuddy
//
//  Created by Deepak Sharma on 02/07/2025.
//  Copyright © 2025 ChaiWithCode. All rights reserved.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.isFromUser ? Color.blue : Color.indigo)
                .foregroundColor(.white)
                .frame(alignment: message.isFromUser ? .trailing : .leading)
                .clipShape(.rect(cornerRadius: 18))
                .glassEffect(in: .rect(cornerRadius: 18))
            
            if !message.isFromUser { Spacer() }
        }
        .padding(.vertical)
    }
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    var content: String
    let isFromUser: Bool
    let timestamp = Date()
}

struct TypingIndicatorView: View {
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle().frame(width: 8, height: 8).scaleEffect(scale)
                Circle().frame(width: 8, height: 8).scaleEffect(scale)
                Circle().frame(width: 8, height: 8).scaleEffect(scale)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(.primary.opacity(0.5))
            .onAppear {
                let baseAnimation = Animation.easeInOut(duration: 0.6)
                let repeated = baseAnimation.repeatForever(autoreverses: true)
                withAnimation(repeated) {
                    scale = 1.0
                }
            }
            Spacer()
        }
    }
}
