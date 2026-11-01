import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SessionRecord.date, order: .reverse) private var sessions: [SessionRecord]

    /// Highest total; on a tie the earliest session keeps the crown.
    private var record: SessionRecord? {
        sessions.reversed().max { $0.total < $1.total }
    }

    var body: some View {
        List {
            if let record {
                Section {
                    recordBanner(record)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section {
                ForEach(sessions) { session in
                    SessionRow(session: session, isRecord: session.persistentModelID == record?.persistentModelID)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowSeparator(.hidden)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(sessions[index]) }
                }
            } header: {
                if !sessions.isEmpty {
                    Text("Past sessions")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.orange)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("History")
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "flame",
                    description: Text("Tap Save & Close Session after a meal to save it here.")
                )
            }
        }
    }

    private func recordBanner(_ record: SessionRecord) -> some View {
        VStack(spacing: 4) {
            Text("🏆 PERSONAL RECORD")
                .font(Theme.rounded(15, .bold))
                .tracking(2)
            Text("\(record.total)")
                .font(Theme.rounded(80, .black))
                .monospacedDigit()
            Text("plates · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                .font(Theme.rounded(16, .semibold))
                .opacity(0.85)
            if record.people > 1 {
                Text("👥 \(record.people) people · \(record.perPerson.platesString) each")
                    .font(Theme.rounded(15, .semibold))
                    .opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Theme.flame, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.red.opacity(0.45), radius: 16, y: 6)
        .padding(.vertical, 8)
    }
}

private struct SessionRow: View {
    let session: SessionRecord
    let isRecord: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.rounded(17, .bold))
                    Text("⏱ \(session.duration.hotpotDuration) · 👥 \(session.people) · \(session.perPerson.platesString)/person")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                if isRecord {
                    Text("🏆").font(.title2)
                }
                Text("\(session.total)")
                    .font(Theme.rounded(40))
                    .monospacedDigit()
                    .foregroundStyle(isRecord ? AnyShapeStyle(Theme.flame) : AnyShapeStyle(.white))
            }

            let tallies = session.tallies
            if !tallies.isEmpty {
                FlowChips(tallies: tallies)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isRecord ? AnyShapeStyle(Theme.flame) : AnyShapeStyle(Theme.cardStroke), lineWidth: isRecord ? 2 : 1)
        )
    }
}

private struct FlowChips: View {
    let tallies: [MeatTally]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(tallies, id: \.self) { tally in
                    Text("\(tally.emoji) \(tally.name) \(tally.count)")
                        .font(Theme.rounded(14, .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
