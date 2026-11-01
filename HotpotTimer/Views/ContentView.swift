import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    TimerCard()
                    MeatCounterSection()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Hotpot Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.ember, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("History", systemImage: "trophy.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.orange)
                    }
                }
            }
        }
        .tint(Theme.orange)
        .overlay {
            // iPhone in landscape: show the table display on top, keeping the
            // portrait navigation state underneath for when it's rotated back.
            if verticalSizeClass == .compact {
                TableDisplayView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: verticalSizeClass)
        .task {
            seedMeatTypesIfNeeded()
            await TimerEngine.shared.requestNotificationPermission()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                Task { await TimerEngine.shared.sync() }
            }
        }
    }

    private func seedMeatTypesIfNeeded() {
        let existing = (try? context.fetchCount(FetchDescriptor<MeatType>())) ?? 0
        guard existing == 0 else { return }
        for (index, meat) in MeatType.builtIns.enumerated() {
            context.insert(MeatType(name: meat.name, emoji: meat.emoji, sortOrder: index, isCustom: false))
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [MeatType.self, SessionRecord.self], inMemory: true)
}
