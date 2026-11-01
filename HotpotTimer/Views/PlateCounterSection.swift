import SwiftData
import SwiftUI

/// One shared plate counter for the table, the head count, and Save & Close.
struct PlateCounterSection: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SharedStore.Keys.people, store: SharedStore.defaults) private var people = 1
    @State private var confirmingClose = false

    private let engine = TimerEngine.shared

    private var total: Int { engine.totalPlates }
    private var perPerson: Double { Double(total) / Double(max(1, people)) }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                HankoLabel(kanji: "合計", english: people > 1 ? "GROUP TOTAL" : "TOTAL")

                Text("\(total)")
                    .font(Theme.font(110, .black))
                    .monospacedDigit()
                    .foregroundStyle(Theme.vermilion)
                    .shadow(color: Theme.shu.opacity(0.35), radius: 14)
                    .contentTransition(.numericText(value: Double(total)))
                    .animation(.snappy, value: total)
                Text(total == 1 ? "plate of meat" : "plates of meat")
                    .font(Theme.font(17, .semibold))
                    .foregroundStyle(Theme.washi.opacity(0.6))

                plateButtons
                    .padding(.top, 18)

                peopleRow
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .card()

            Button {
                Haptics.tap(.medium)
                confirmingClose = true
            } label: {
                Label("Save & Close Session", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(ChunkyButtonStyle(kind: .plain, height: 64))
            .disabled(total == 0)
            .opacity(total == 0 ? 0.4 : 1)
            .padding(.top, 6)
        }
        .onChange(of: people) {
            engine.reloadWidgets()
        }
        .confirmationDialog(
            "Save this session (\(total) plates, \(people) \(people == 1 ? "person" : "people")) to History, reset the counter and stop the timer?",
            isPresented: $confirmingClose,
            titleVisibility: .visible
        ) {
            Button("Save & Close Session", action: saveAndClose)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var plateButtons: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap(.light)
                engine.addPlates(-1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .heavy))
            }
            .buttonStyle(ChunkyButtonStyle(kind: .plain, height: 88))
            .frame(width: 88)
            .disabled(total == 0)
            .opacity(total == 0 ? 0.4 : 1)
            .accessibilityLabel("Remove one plate")

            Button {
                Haptics.tap(.heavy)
                SessionClock.markStartedIfNeeded()
                engine.addPlates(1)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .black))
                    Text("1 plate")
                        .font(Theme.font(26))
                }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .flame, height: 88))
            .accessibilityLabel("Add one plate")
        }
    }

    private var peopleRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("人数 People")
                    .font(Theme.font(19, .bold))
                    .foregroundStyle(Theme.washi)
                Text("\(perPerson.platesString) plates each")
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.gold)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: perPerson)
            }

            Spacer(minLength: 4)

            Button {
                Haptics.tap(.light)
                if people > 1 { people -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Theme.washi.opacity(0.8))
                    .frame(width: 48, height: 48)
                    .background(Theme.washi.opacity(0.08), in: Circle())
                    .overlay(Circle().strokeBorder(Theme.cardStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(people <= 1)
            .opacity(people <= 1 ? 0.4 : 1)
            .accessibilityLabel("One fewer person")

            Text("\(people)")
                .font(Theme.font(34))
                .monospacedDigit()
                .foregroundStyle(Theme.washi)
                .frame(minWidth: 40)
                .contentTransition(.numericText(value: Double(people)))
                .animation(.snappy, value: people)

            Button {
                Haptics.tap(.medium)
                people += 1
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Theme.washi)
                    .frame(width: 48, height: 48)
                    .background(Theme.washi.opacity(0.14), in: Circle())
                    .overlay(Circle().strokeBorder(Theme.cardStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("One more person")
        }
        .padding(12)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func saveAndClose() {
        let startedAt = SessionClock.startedAt ?? .now
        context.insert(SessionRecord(
            date: startedAt,
            duration: Date.now.timeIntervalSince(startedAt),
            total: total,
            people: people
        ))
        engine.setTotalPlates(0)
        SessionClock.reset()
        Task { await engine.stop() }
        Haptics.success()
    }
}
