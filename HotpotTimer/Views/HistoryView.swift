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
                        .font(Theme.font(15, .bold))
                        .foregroundStyle(Theme.gold)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
        .background(JapaneseBackground())
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
            Text("記録 · PERSONAL RECORD")
                .font(Theme.font(15, .bold))
                .tracking(2)
            Text("\(record.total)")
                .font(Theme.font(80, .black))
                .monospacedDigit()
            Text("plates · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                .font(Theme.font(16, .semibold))
                .opacity(0.85)
            if record.people > 1 {
                Text("👥 \(record.people) people · \(record.perPerson.platesString) each")
                    .font(Theme.font(15, .semibold))
                    .opacity(0.85)
            }
        }
        .foregroundStyle(Theme.washi)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Theme.vermilion, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(color: Theme.shu.opacity(0.45), radius: 16, y: 6)
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
                        .font(Theme.font(17, .bold))
                    Text("⏱ \(session.duration.hotpotDuration) · 👥 \(session.people) · \(session.perPerson.platesString)/person")
                        .font(Theme.font(14, .medium))
                        .foregroundStyle(Theme.washi.opacity(0.55))
                }
                Spacer()
                if isRecord {
                    Text("🏆").font(.title2)
                }
                Text("\(session.total)")
                    .font(Theme.font(40))
                    .monospacedDigit()
                    .foregroundStyle(isRecord ? AnyShapeStyle(Theme.vermilion) : AnyShapeStyle(Theme.washi))
            }

        }
        .foregroundStyle(Theme.washi)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(isRecord ? AnyShapeStyle(Theme.vermilion) : AnyShapeStyle(Theme.cardStroke), lineWidth: isRecord ? 2 : 1)
        )
    }
}
