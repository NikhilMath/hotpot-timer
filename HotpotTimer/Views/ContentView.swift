import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    TimerCard()
                    PlateCounterSection()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(JapaneseBackground())
            .navigationTitle("Hotpot Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.sumi, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("食べ放題")
                            .font(Theme.mincho(11))
                            .foregroundStyle(Theme.shu)
                        Text("Hotpot Timer")
                            .font(Theme.font(17, .bold))
                            .foregroundStyle(Theme.washi)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("History", systemImage: "trophy.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
        }
        .tint(Theme.gold)
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
            await TimerEngine.shared.requestNotificationPermission()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                Task { await TimerEngine.shared.sync() }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: SessionRecord.self, inMemory: true)
}
