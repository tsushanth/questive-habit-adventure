//
//  AddQuestView.swift
//  Questive
//
//  Sheet for creating a new quest
//

import SwiftUI
import SwiftData

struct AddQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var questDescription = ""
    @State private var selectedCategory: QuestCategory = .health
    @State private var selectedFrequency: QuestFrequency = .daily
    @State private var selectedIcon = "star.fill"
    @State private var xpReward = 50
    @State private var goldReward = 10

    private let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill",
        "drop.fill", "moon.fill", "sun.max.fill", "figure.run", "book.fill",
        "pencil.and.outline", "brain.head.profile", "music.note", "fork.knife",
        "bicycle", "cross.fill", "dollarsign.circle.fill", "person.2.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Title & Description
                Section("Quest Details") {
                    TextField("Quest title", text: $title)
                        .font(.headline)
                    TextField("Description (optional)", text: $questDescription, axis: .vertical)
                        .lineLimit(3)
                }

                // Icon picker
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == icon ? Color.purple.opacity(0.2) : Color.gray.opacity(0.08))
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundStyle(selectedIcon == icon ? .purple : .primary)
                                }
                                .frame(height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color.purple : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Category
                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(QuestCategory.allCases, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                        Text(cat.rawValue)
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? cat.color : cat.color.opacity(0.1))
                                    .foregroundStyle(selectedCategory == cat ? .white : cat.color)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // Frequency
                Section("Frequency") {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(QuestFrequency.allCases, id: \.self) { freq in
                            Label(freq.rawValue, systemImage: freq.icon).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Rewards
                Section("Rewards") {
                    Stepper("XP: \(xpReward)", value: $xpReward, in: 10...200, step: 10)
                    Stepper("Gold: \(goldReward)🪙", value: $goldReward, in: 5...100, step: 5)
                }
            }
            .navigationTitle("New Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createQuest()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createQuest() {
        let quest = QuestModel(
            title: title.trimmingCharacters(in: .whitespaces),
            questDescription: questDescription,
            iconName: selectedIcon,
            frequency: selectedFrequency,
            category: selectedCategory,
            xpReward: xpReward,
            goldReward: goldReward
        )
        modelContext.insert(quest)
        AnalyticsService.shared.track(.questCreated(category: selectedCategory.rawValue))
        dismiss()
    }
}
