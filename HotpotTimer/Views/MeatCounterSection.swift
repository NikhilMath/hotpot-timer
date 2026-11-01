import SwiftData
import SwiftUI

struct MeatCounterSection: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MeatType.sortOrder) private var meats: [MeatType]

    @State private var showingAddType = false
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var confirmingNewSession = false
    @AppStorage("session.people") private var people = 1

    private var total: Int { meats.reduce(0) { $0 + $1.count } }
    private var perPerson: Double { Double(total) / Double(max(1, people)) }

    var body: some View {
        VStack(spacing: 14) {
            totalHeader

            ForEach(meats) { meat in
                MeatRow(meat: meat)
                    .contextMenu {
                        if meat.isCustom {
                            Button("Delete \(meat.name)", systemImage: "trash", role: .destructive) {
                                context.delete(meat)
                            }
                        }
                    }
            }

            Button {
                Haptics.tap(.light)
                newName = ""
                newEmoji = ""
                showingAddType = true
            } label: {
                Label("Add type", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ChunkyButtonStyle(kind: .plain, height: 60))

            Button {
                Haptics.tap(.medium)
                confirmingNewSession = true
            } label: {
                Label("Save & Close Session", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(ChunkyButtonStyle(kind: .flame, height: 64))
            .disabled(total == 0)
            .opacity(total == 0 ? 0.4 : 1)
            .padding(.top, 6)
        }
        .onChange(of: total, initial: true) { _, newTotal in
            Task { await TimerEngine.shared.setTotalPlates(newTotal) }
        }
        .alert("Add meat type", isPresented: $showingAddType) {
            TextField("Name (e.g. Wagyu)", text: $newName)
            TextField("Emoji (optional)", text: $newEmoji)
            Button("Add", action: addCustomType)
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Save this session (\(total) plates, \(people) \(people == 1 ? "person" : "people")) to History, reset the counter and stop the timer?",
            isPresented: $confirmingNewSession,
            titleVisibility: .visible
        ) {
            Button("Save & Close Session", action: saveSession)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var totalHeader: some View {
        VStack(spacing: 0) {
            Text(people > 1 ? "GROUP TOTAL" : "TOTAL")
                .font(Theme.rounded(16, .bold))
                .tracking(4)
                .foregroundStyle(Theme.orange)
            Text("\(total)")
                .font(Theme.rounded(96, .black))
                .monospacedDigit()
                .foregroundStyle(Theme.flame)
                .contentTransition(.numericText(value: Double(total)))
                .animation(.snappy, value: total)
            Text(total == 1 ? "plate of meat 🥩" : "plates of meat 🥩")
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(.white.opacity(0.6))

            peopleRow
                .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .card()
    }

    private var peopleRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("👥 People")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(.white)
                Text("\(perPerson.platesString) plates each")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.orange)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: perPerson)
            }

            Spacer(minLength: 4)

            Button {
                Haptics.tap(.light)
                if people > 1 { people -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(people <= 1)
            .opacity(people <= 1 ? 0.4 : 1)
            .accessibilityLabel("One fewer person")

            Text("\(people)")
                .font(Theme.rounded(36))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 44)
                .contentTransition(.numericText(value: Double(people)))
                .animation(.snappy, value: people)

            Button {
                Haptics.tap(.medium)
                people += 1
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("One more person")
        }
        .padding(12)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func addCustomType() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let emoji = newEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextOrder = (meats.map(\.sortOrder).max() ?? 0) + 1
        context.insert(MeatType(
            name: name,
            emoji: emoji.isEmpty ? "🍖" : String(emoji.prefix(2)),
            sortOrder: nextOrder,
            isCustom: true
        ))
        Haptics.success()
    }

    private func saveSession() {
        let tallies = meats
            .filter { $0.count > 0 }
            .map { MeatTally(name: $0.name, emoji: $0.emoji, count: $0.count) }
        let startedAt = SessionClock.startedAt ?? .now
        context.insert(SessionRecord(
            date: startedAt,
            duration: Date.now.timeIntervalSince(startedAt),
            total: total,
            people: people,
            tallies: tallies
        ))
        for meat in meats { meat.count = 0 }
        SessionClock.reset()
        Task { await TimerEngine.shared.stop() }
        Haptics.success()
    }
}

struct MeatRow: View {
    @Bindable var meat: MeatType

    var body: some View {
        HStack(spacing: 10) {
            Text(meat.emoji)
                .font(.system(size: 34))

            Text(meat.name)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 4)

            Button {
                Haptics.tap(.light)
                if meat.count > 0 { meat.count -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove one \(meat.name)")

            Text("\(meat.count)")
                .font(Theme.rounded(40))
                .monospacedDigit()
                .foregroundStyle(meat.count > 0 ? .white : .white.opacity(0.35))
                .frame(minWidth: 52)
                .contentTransition(.numericText(value: Double(meat.count)))
                .animation(.snappy, value: meat.count)

            Button {
                Haptics.tap(.heavy)
                SessionClock.markStartedIfNeeded()
                meat.count += 1
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(Theme.flame, in: Circle())
                    .shadow(color: Theme.red.opacity(0.5), radius: 8, y: 3)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Add one \(meat.name)")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .card()
    }
}

private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}
