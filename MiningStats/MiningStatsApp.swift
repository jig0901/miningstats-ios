//
//  MiningStatsApp.swift
//  MiningStats
//
//  Created by Jigish Belani on 7/29/25.
//

// MiningStats iOS App (SwiftUI)
// Native rewrite of the Streamlit dashboard.
// 2025‑07‑30 update: ➊ Navigation‑style title bar stays fixed while content scrolls. ➋ Added trailing countdown in the bar. ➌ Stats cards get a fixed min‑height so “Worker Count” & “Last Share” stay equal.
// Requires iOS 16+ (Charts + NavigationStack).

import SwiftUI
import Charts

// MARK: - Data Models

struct Worker: Codable, Identifiable {
    let id = UUID()
    let workername: String
    let hashrate1m: String
    let hashrate5m: String
    let hashrate1hr: String
    let hashrate1d: String
    let hashrate7d: String
    let lastshare: Double
    let shares: Double
    let bestshare: Double
    let bestever: Double?
}

struct MinerStats: Codable {
    let workerCount: Int
    let bestShares: Double
    let hashrate1minThs: Double
    let odds1yrPercent: Double
    let lastShareTime: String?
    let acceptedShares: Double?
    let hashrate5mThs: Double?
    let hashrate1hrThs: Double?
    let hashrate1dThs: Double?
    let hashrate7dThs: Double?
    let odds24hrPercent: Double?
    let odds7dPercent: Double?
    let odds30dPercent: Double?
    let workers: [Worker]?

    enum CodingKeys: String, CodingKey {
        case workerCount = "worker_count"
        case bestShares = "best_shares"
        case hashrate1minThs = "hashrate_1min_ths"
        case odds1yrPercent = "odds_1yr_percent"
        case lastShareTime = "last_share_time"
        case acceptedShares = "accepted_shares"
        case hashrate5mThs = "hashrate_5min_ths"
        case hashrate1hrThs = "hashrate_1hr_ths"
        case hashrate1dThs = "hashrate_1d_ths"
        case hashrate7dThs = "hashrate_7d_ths"
        case odds24hrPercent = "odds_24hr_percent"
        case odds7dPercent = "odds_7d_percent"
        case odds30dPercent = "odds_30d_percent"
        case workers
    }
}

struct HistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hashrate: Double
}

// MARK: - View Model

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var stats: MinerStats?
    @Published var history: [HistoryPoint] = []
    @Published var countdown: Int

    private let apiURL = URL(string: "http://10.229.65.149:8000/metrics")!
    private let refreshInterval: Int
    private var timer: Timer?

    init(refreshInterval: Int = 60) {
        self.refreshInterval = refreshInterval
        self.countdown = refreshInterval
        fetch()
        startTimer()
    }

    deinit { timer?.invalidate() }

    func fetch() {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: apiURL)
                let decoded = try JSONDecoder().decode(MinerStats.self, from: data)
                stats = decoded
                history.append(HistoryPoint(date: Date(), hashrate: decoded.hashrate1minThs))
            } catch { print("❌ API fetch failed:", error) }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if countdown > 0 {
                countdown -= 1
            } else {
                countdown = refreshInterval
                fetch()
            }
        }
    }
}

// MARK: - Reusable UI Components

struct StatsCard: View {
    let title: String
    let value: String
    private let minHeight: CGFloat = 80   // keeps all cards same height

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.title3)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .padding(12)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(uiColor: .systemGray4))
        )
    }
}

// MARK: - Main View

struct MiningStatsView: View {
    @StateObject private var vm = StatsViewModel()
    private let cols = [GridItem(.adaptive(minimum: 140))]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let s = vm.stats {
                        generalStats(for: s)
                        hashrateStats(for: s)
                        oddsStats(for: s)
                    }
                    chartSection
                    if let workers = vm.stats?.workers, !workers.isEmpty {
                        workersTable(workers)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("⛏️ Belani Solo Mining")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("🔄 \(vm.countdown)s")
                        .font(.footnote)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: Stats Sections
    private func generalStats(for s: MinerStats) -> some View {
        LazyVGrid(columns: cols, spacing: 16) {
            StatsCard(title: "Worker Count", value: "\(s.workerCount)")
            if let last = s.lastShareTime {
                StatsCard(title: "Last Share", value: last)
            }
            if let accepted = s.acceptedShares {
                StatsCard(title: "Total Shares", value: formatValue(accepted))
            }
            StatsCard(title: "Best Share", value: formatValue(s.bestShares))
        }
        .padding(.horizontal)
    }

    private func hashrateStats(for s: MinerStats) -> some View {
        LazyVGrid(columns: cols, spacing: 16) {
            StatsCard(title: "Hashrate (1 m)", value: "\(String(format: "%.2f", s.hashrate1minThs)) TH/s")
            if let v = s.hashrate5mThs { StatsCard(title: "Hashrate (5 m)", value: "\(String(format: "%.2f", v)) TH/s") }
            if let v = s.hashrate1hrThs { StatsCard(title: "Hashrate (1 h)", value: "\(String(format: "%.2f", v)) TH/s") }
            if let v = s.hashrate1dThs { StatsCard(title: "Hashrate (1 d)", value: "\(String(format: "%.2f", v)) TH/s") }
            if let v = s.hashrate7dThs { StatsCard(title: "Hashrate (7 d)", value: "\(String(format: "%.2f", v)) TH/s") }
        }
        .padding(.horizontal)
    }

    private func oddsStats(for s: MinerStats) -> some View {
        VStack(alignment: .leading) {
            Text("🎲 Odds of Finding a Block")
                .font(.subheadline)
                .padding(.horizontal)
            LazyVGrid(columns: cols, spacing: 16) {
                if let o = s.odds24hrPercent { StatsCard(title: "Odds (24 h)", value: percentString(o)) }
                if let o = s.odds7dPercent { StatsCard(title: "Odds (7 d)", value: percentString(o)) }
                if let o = s.odds30dPercent { StatsCard(title: "Odds (30 d)", value: percentString(o)) }
                StatsCard(title: "Odds (1 yr)", value: percentString(s.odds1yrPercent))
            }
            .padding(.horizontal)
        }
    }

    // MARK: Chart
    private var chartSection: some View {
        VStack(alignment: .leading) {
            Text("📈 Historical Hashrate (1 m TH/s)")
                .font(.subheadline)
                .padding(.horizontal)
            if !vm.history.isEmpty {
                Chart(vm.history) { p in
                    LineMark(x: .value("Time", p.date), y: .value("TH/s", p.hashrate))
                }
                .chartXAxis(.hidden)
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
    }


    // MARK: Worker Table
    private func workersTable(_ workers: [Worker]) -> some View {
        VStack(alignment: .leading) {
            Text("👷 Worker Details")
                .font(.subheadline)
                .padding(.horizontal)
            ScrollView(.horizontal) {
                LazyVStack(alignment: .leading, spacing: 4) {
                    headerRow
                    ForEach(workers) { w in
                        row(for: w)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var headerRow: some View {
            HStack {
                Text("Name")   .frame(width: 180, alignment: .leading).bold()
                Text("1 m")    .frame(width: 80,  alignment: .trailing).bold()
                Text("5 m")    .frame(width: 80,  alignment: .trailing).bold()
                Text("1 h")    .frame(width: 80,  alignment: .trailing).bold()
                Text("1 d")    .frame(width: 80,  alignment: .trailing).bold()
                Text("7 d")    .frame(width: 80,  alignment: .trailing).bold()
                Text("Shares") .frame(width: 100, alignment: .trailing).bold()
                Text("Best")   .frame(width: 110, alignment: .trailing).bold()
            }
            .font(.caption2)
        }

        private func row(for w: Worker) -> some View {
            let best = w.bestever ?? w.bestshare
            return HStack {
                Text(cleanName(w.workername)).frame(width: 180, alignment: .leading)
                Text(w.hashrate1m)            .frame(width: 80,  alignment: .trailing)
                Text(w.hashrate5m)            .frame(width: 80,  alignment: .trailing)
                Text(w.hashrate1hr)           .frame(width: 80,  alignment: .trailing)
                Text(w.hashrate1d)            .frame(width: 80,  alignment: .trailing)
                Text(w.hashrate7d)            .frame(width: 80,  alignment: .trailing)
                Text(shortNumber(w.shares))   .frame(width: 100, alignment: .trailing)
                Text(shortNumber(best))       .frame(width: 110, alignment: .trailing)
            }
            .font(.caption2)
        }

    // MARK: Helpers
    private func percentString(_ p: Double) -> String {
        String(format: "%.6f%%", p)
    }

    private func formatValue(_ n: Double) -> String {
        let absN = abs(n)
        switch absN {
        case 1e12...: return String(format: "%.2fT", n / 1e12)
        case 1e9...:  return String(format: "%.2fG", n / 1e9)
        case 1e6...:  return String(format: "%.2fM", n / 1e6)
        case 1e3...:  return String(format: "%.2fk", n / 1e3)
        default:      return String(format: "%.2f", n)
        }
    }

    private func shortNumber(_ n: Double) -> String { formatValue(n) }

    /// Trim “address.” prefix so just the worker alias shows, matching Streamlit logic.
    private func cleanName(_ full: String) -> String {
        if let dot = full.firstIndex(of: ".") {
            return String(full[full.index(after: dot)...])
        }
        return full
    }
}

// MARK: - App Entry

@main
struct MiningStatsApp: App {
    var body: some Scene {
        WindowGroup { MiningStatsView() }
    }
}

