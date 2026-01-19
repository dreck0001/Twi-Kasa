//
//  LearnView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/12/26.
//

import SwiftUI

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    wordOfTheDaySection
                    
                    proverbsSection
                    
                    commonPhrasesSection
                    
                    randomWordsSection
                }
                .padding()
            }
            .navigationTitle("Learn & Discover")
        }
    }

    private var wordOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Word of the Day")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming soon!")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var proverbsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.orange)
                Text("Twi Proverbs")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming soon!")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var commonPhrasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.blue)
                Text("Common Phrases")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming soon!")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var randomWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shuffle")
                    .foregroundColor(.green)
                Text("Random Words")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming soon!")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    LearnView()
}
