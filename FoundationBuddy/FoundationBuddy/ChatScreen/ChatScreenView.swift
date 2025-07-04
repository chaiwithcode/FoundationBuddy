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
    
    @State private var userInput: String = ""
    @State private var showTypingIndicator: Bool = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var session: LanguageModelSession?
    @State private var streamingTask: Task<Void, Never>?
    @State private var languageModel = SystemLanguageModel.default
    
    @State private var useStreamingMode = true
    @State private var showSettingsMenu = false
    @State private var isChatVisible: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isChatVisible {
                    VStack(spacing: 0) {
                        conversationView
                        Spacer()
                        messageInputBar
                            .padding()
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Foundation Buddy")
            .navigationSubtitle("Your Apple Intelligence Chat Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            useStreamingMode = true
                        } label: {
                            Label("Streaming Mode", systemImage: "text.bubble")
                        }

                        Button {
                            useStreamingMode = false
                        } label: {
                            Label("Respond Mode", systemImage: "bolt.fill")
                        }

                        Divider()

                        Button {
                            clearChat()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .alert("Oops!", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
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
            TextField("Ask Anything...", text: $userInput, axis: .vertical)
                .textFieldStyle(.plain)
                .disabled(showTypingIndicator)
                .onSubmit {
                    if isValidInput(userInput) {
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
                .disabled(!isValidInput(userInput))
                .glassEffect(.regular.interactive())
                .padding(.trailing, 8)
            }
        }
        .glassEffect(.regular.interactive())
    }
    
    private var inputIsIdle: Bool {
        return userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !showTypingIndicator
    }
    
    private func isValidInput(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @MainActor
    private func handleSendAction() {
        if showTypingIndicator {
            streamingTask?.cancel()
        } else {
            guard languageModel.isAvailable else {
                showAlert(message: "The language model is not available. Reason: \(describeModelAvailability(for: languageModel.availability))")
                return
            }
            sendMessage()
        }
    }
    
    @MainActor
    private func sendMessage() {
        showTypingIndicator = true
        let userMessage = Message(content: userInput, isFromUser: true)
        conversationHistory.append(userMessage)
        
        let prompt = Prompt(userInput)
        let options = GenerationOptions()
        
        userInput = ""
        conversationHistory.append(Message(content: "", isFromUser: false))
        
        streamingTask = Task {
            do {
                let currentSession = LanguageModelSession(model: languageModel)
                self.session = currentSession
                
                if useStreamingMode {
                    let streamResponse = currentSession.streamResponse(to: prompt, options: options)
                    for try await partialResponse in streamResponse {
                        updateChat(response: partialResponse)
                    }
                } else {
                    let response = try await currentSession.respond(to: prompt, options: options)
                    updateChat(response: response.content)
                }
            } catch {
                showAlert(message: "Model failed to generate response: \(error.localizedDescription)")
            }
            
            showTypingIndicator = false
        }
    }
    
    @MainActor
    private func updateChat(response: String) {
        conversationHistory[conversationHistory.count - 1].content = response
    }
    
    private func describeModelAvailability(for availability: SystemLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "Available"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "Device not eligible"
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence not enabled in Settings"
            case .modelNotReady:
                return "Model assets not downloaded"
            @unknown default:
                return "Unknown reason"
            }
        @unknown default:
            return "Unknown availability"
        }
    }
    
    @MainActor
    private func showAlert(message: String) {
        alertMessage = message
        showAlert.toggle()
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessageId = conversationHistory.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastMessageId, anchor: .bottom)
        }
    }
    
    private func clearChat() {
        streamingTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            isChatVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            userInput = ""
            showTypingIndicator = false
            conversationHistory = [
                Message(content: "Hello! How can I help you today?", isFromUser: false)
            ]

            withAnimation(.easeInOut(duration: 0.3)) {
                isChatVisible = true
            }
        }
    }
}
