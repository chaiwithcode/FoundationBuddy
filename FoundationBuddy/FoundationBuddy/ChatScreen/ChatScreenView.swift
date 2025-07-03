//
//  ChatScreenView.swift
//  Foundation Buddy
//
//  Created by Deepak Sharma on 02/07/2025.
//  Copyright © 2025 ChaiWithCode. All rights reserved.
//

import SwiftUI
import FoundationModels

struct ChatScreenView: View {
    @State private var conversationHistory: [Message] = [
        Message(content: "Hello! How can I help you today?", isFromUser: false)
    ]
    
    @State private var currentInput: String = ""
    @State private var showTypingIndicator: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    conversationView
                    Spacer()
                    messageInputBar
                        .padding()
                }
            }
            .navigationTitle("Foundation Buddy")
            .navigationSubtitle("Your Apple Intelligence Chat Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(conversationHistory) { message in
                        if !message.content.isEmpty {
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    
                    if showTypingIndicator {
                        TypingIndicatorView()
                            .padding()
                    }
                }
                .padding()
            }
            .onChange(of: conversationHistory.last?.content) {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private var messageInputBar: some View {
        ZStack {
            TextField("Ask Anything...", text: $currentInput, axis: .vertical)
                .textFieldStyle(.plain)
                .disabled(showTypingIndicator)
                .onSubmit {
                    if isValidInput(currentInput) {
                        handleSendAction()
                    }
                }
                .padding(16)
            
            HStack {
                Spacer()
                Button(action: handleSendAction) {
                    Image(systemName: showTypingIndicator ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .foregroundStyle(inputIsIdle ? Color.gray.opacity(0.6) : .primary)
                        .font(.system(size: 32))
                }
                .disabled(!isValidInput(currentInput))
                .glassEffect(.regular.interactive())
                .padding(.trailing, 8)
            }
        }
        .glassEffect(.regular.interactive())
    }
    
    private var inputIsIdle: Bool {
        return currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !showTypingIndicator
    }
    
    private func isValidInput(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @MainActor
    private func handleSendAction() {
        let userMessage = Message(content: currentInput, isFromUser: true)
        conversationHistory.append(userMessage)
        currentInput = ""
        
        showTypingIndicator = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let message = Message(content: "Response from Apple Foundation Model", isFromUser: false)
            conversationHistory.append(message)
            showTypingIndicator = false
        }
    }
    
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessageId = conversationHistory.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastMessageId, anchor: .bottom)
        }
    }
    
}
