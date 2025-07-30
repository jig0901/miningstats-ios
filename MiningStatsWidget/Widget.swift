import WidgetKit
import SwiftUI

// ---------------------
// Home‑Screen Widget
// ---------------------
struct MiningStatsEntry: TimelineEntry, Codable {
    let date: Date
    let workerCount: Int
    let bestShare: Double
    let hashrate1m: Double   // TH/s over last 1 minute
    let odds1yr: Double      // Percent for 1 year
}

struct MiningStatsProvider: TimelineProvider {
    // Default entry when API is unreachable
    private func defaultEntry() -> MiningStatsEntry {
        MiningStatsEntry(date: Date(), workerCount: 0, bestShare: 0, hashrate1m: 0, odds1yr: 0)
    }

    func placeholder(in context: Context) -> MiningStatsEntry {
        defaultEntry()
    }
    func getSnapshot(in context: Context, completion: @escaping (MiningStatsEntry) -> Void) {
        completion(defaultEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MiningStatsEntry>) -> Void) {
        fetchStats { entry in
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
    private func fetchStats(completion: @escaping (MiningStatsEntry) -> Void) {
        guard let url = URL(string: "http://10.229.65.149:8000/metrics") else {
            completion(defaultEntry()); return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let api = try? JSONDecoder().decode(APIResponse.self, from: data)
            else {
                completion(defaultEntry()); return
            }
            let entry = MiningStatsEntry(
                date: Date(),
                workerCount: api.worker_count,
                bestShare: api.best_shares,
                hashrate1m: api.hashrate_1min_ths,
                odds1yr: api.odds_1yr_percent
            )
            completion(entry)
        }.resume()
    }
}

// Shared JSON structure
private struct APIResponse: Codable {
    let worker_count: Int
    let best_shares: Double
    let hashrate_1min_ths: Double
    let odds_1yr_percent: Double
}

struct MiningStatsWidgetEntryView: View {
    var entry: MiningStatsEntry
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                stat("Workers", "\(entry.workerCount)")
                stat("Best", formatLarge(entry.bestShare))
            }
            HStack(spacing: 12) {
                stat("1m HR", fmtTH(entry.hashrate1m))
                stat("1y Odds", fmtPct(entry.odds1yr))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .containerBackground(
            Color(.systemBackground).opacity(0.5),
            for: .widget
        )
    }
    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).bold()
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    private func fmtTH(_ v: Double) -> String { String(format: "%.1f TH/s", v) }
    private func fmtPct(_ v: Double) -> String { String(format: "%.2f%%", v) }
    private func formatLarge(_ v: Double) -> String {
        let absV = abs(v)
        switch absV {
        case 0..<1_000: return String(format: "%.0f", v)
        case 1_000..<1_000_000: return String(format: "%.1fK", v / 1_000)
        case 1_000_000..<1_000_000_000: return String(format: "%.1fM", v / 1_000_000)
        case 1_000_000_000..<1_000_000_000_000: return String(format: "%.1fG", v / 1_000_000_000)
        default: return String(format: "%.1fT", v / 1_000_000_000_000)
        }
    }
}

// --------------------------------
// Lock‑Screen Accessory Widgets
// --------------------------------

// Worker Count Widget
struct WorkerCountEntry: TimelineEntry, Codable {
    let date: Date
    let workerCount: Int
}
struct WorkerCountProvider: TimelineProvider {
    private func defaultEntry() -> WorkerCountEntry { WorkerCountEntry(date: Date(), workerCount: 0) }
    func placeholder(in context: Context) -> WorkerCountEntry { defaultEntry() }
    func getSnapshot(in context: Context, completion: @escaping (WorkerCountEntry) -> Void) { completion(defaultEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkerCountEntry>) -> Void) {
        fetch { entry in
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
    private func fetch(completion: @escaping (WorkerCountEntry) -> Void) {
        guard let url = URL(string: "http://10.229.65.149:8000/metrics") else { completion(defaultEntry()); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var c = defaultEntry().workerCount
            if let data = data,
               let api = try? JSONDecoder().decode(APIResponse.self, from: data) {
                c = api.worker_count
            }
            completion(WorkerCountEntry(date: Date(), workerCount: c))
        }.resume()
    }
}

struct WorkerCountWidgetEntryView: View {
    var entry: WorkerCountEntry
    var body: some View {
        VStack(spacing: 4) {
            Text("Workers").font(.caption2).foregroundColor(.secondary)
            Text("\(entry.workerCount)").font(.system(size: 36, weight: .bold))
        }
        .padding(8)
        .containerBackground(Color(.systemBackground).opacity(0.5), for: .widget)
    }
}

// Best Shares Widget
struct BestSharesEntry: TimelineEntry, Codable {
    let date: Date
    let bestShares: Double
}
struct BestSharesProvider: TimelineProvider {
    private func defaultEntry() -> BestSharesEntry { BestSharesEntry(date: Date(), bestShares: 0) }
    func placeholder(in context: Context) -> BestSharesEntry { defaultEntry() }
    func getSnapshot(in context: Context, completion: @escaping (BestSharesEntry) -> Void) { completion(defaultEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BestSharesEntry>) -> Void) {
        fetch { entry in
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
    private func fetch(completion: @escaping (BestSharesEntry) -> Void) {
        guard let url = URL(string: "http://10.229.65.149:8000/metrics") else { completion(defaultEntry()); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var bs = defaultEntry().bestShares
            if let data = data,
               let api = try? JSONDecoder().decode(APIResponse.self, from: data) {
                bs = api.best_shares
            }
            completion(BestSharesEntry(date: Date(), bestShares: bs))
        }.resume()
    }
}

struct BestSharesWidgetEntryView: View {
    var entry: BestSharesEntry
    var body: some View {
        VStack(spacing: 4) {
            Text("Best Shares").font(.caption2).foregroundColor(.secondary)
            Text(formatLarge(entry.bestShares)).font(.system(size: 36, weight: .bold))
        }
        .padding(8)
        .containerBackground(Color(.systemBackground).opacity(0.5), for: .widget)
    }
}

// Hashrate Widget
struct HashrateEntry: TimelineEntry, Codable {
    let date: Date
    let hashrate: Double
}
struct HashrateProvider: TimelineProvider {
    private func defaultEntry() -> HashrateEntry { HashrateEntry(date: Date(), hashrate: 0) }
    func placeholder(in context: Context) -> HashrateEntry { defaultEntry() }
    func getSnapshot(in context: Context, completion: @escaping (HashrateEntry) -> Void) { completion(defaultEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HashrateEntry>) -> Void) {
        fetch { entry in
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
    private func fetch(completion: @escaping (HashrateEntry) -> Void) {
        guard let url = URL(string: "http://10.229.65.149:8000/metrics") else { completion(defaultEntry()); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var hr = defaultEntry().hashrate
            if let data = data,
               let api = try? JSONDecoder().decode(APIResponse.self, from: data) {
                hr = api.hashrate_1min_ths
            }
            completion(HashrateEntry(date: Date(), hashrate: hr))
        }.resume()
    }
}

struct HashrateWidgetEntryView: View {
    var entry: HashrateEntry
    var body: some View {
        VStack(spacing: 4) {
            Text("1m HR").font(.caption2).foregroundColor(.secondary)
            Text(fmtTH(entry.hashrate)).font(.system(size: 36, weight: .bold))
        }
        .padding(8)
        .containerBackground(Color(.systemBackground).opacity(0.5), for: .widget)
    }
}

// Odds Widget
struct OddsEntry: TimelineEntry, Codable {
    let date: Date
    let odds: Double
}
struct OddsProvider: TimelineProvider {
    private func defaultEntry() -> OddsEntry { OddsEntry(date: Date(), odds: 0) }
    func placeholder(in context: Context) -> OddsEntry { defaultEntry() }
    func getSnapshot(in context: Context, completion: @escaping (OddsEntry) -> Void) { completion(defaultEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<OddsEntry>) -> Void) {
        fetch { entry in
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
    private func fetch(completion: @escaping (OddsEntry) -> Void) {
        guard let url = URL(string: "http://10.229.65.149:8000/metrics") else { completion(defaultEntry()); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var o = defaultEntry().odds
            if let data = data,
               let api = try? JSONDecoder().decode(APIResponse.self, from: data) {
                o = api.odds_1yr_percent
            }
            completion(OddsEntry(date: Date(), odds: o))
        }.resume()
    }
}

struct OddsWidgetEntryView: View {
    var entry: OddsEntry
    var body: some View {
        VStack(spacing: 4) {
            Text("1y Odds").font(.caption2).foregroundColor(.secondary)
            Text(fmtPct(entry.odds)).font(.system(size: 36, weight: .bold))
        }
        .padding(8)
        .containerBackground(Color(.systemBackground).opacity(0.5), for: .widget)
    }
}

// --------------------
// Widget Bundle
// --------------------
@main
struct MiningWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        MiningStatsWidget()
        WorkerCountLockWidget()
        BestSharesLockWidget()
        HashrateLockWidget()
        OddsLockWidget()
    }
}

struct MiningStatsWidget: Widget {
    let kind = "MiningStatsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MiningStatsProvider()) { entry in
            MiningStatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Mining Stats")
        .description("Home‑screen stats")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WorkerCountLockWidget: Widget {
    let kind = "WorkerCountLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkerCountProvider()) { entry in
            WorkerCountWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Worker Count")
        .description("Lock‑screen count")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct BestSharesLockWidget: Widget {
    let kind = "BestSharesLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BestSharesProvider()) { entry in
            BestSharesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Best Shares")
        .description("Lock‑screen best share")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct HashrateLockWidget: Widget {
    let kind = "HashrateLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HashrateProvider()) { entry in
            HashrateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("1m Hashrate")
        .description("Lock‑screen 1m hashrate")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct OddsLockWidget: Widget {
    let kind = "OddsLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OddsProvider()) { entry in
            OddsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("1y Odds")
        .description("Lock‑screen 1y odds")
        .supportedFamilies([.accessoryRectangular])
    }
}

// Helpers for lock‑screen views
private func fmtTH(_ v: Double) -> String { String(format: "%.1f TH/s", v) }
private func fmtPct(_ v: Double) -> String { String(format: "%.2f%%", v) }
private func formatLarge(_ v: Double) -> String {
    let absV = abs(v)
    switch absV {
    case 0..<1_000: return String(format: "%.0f", v)
    case 1_000..<1_000_000: return String(format: "%.1fK", v/1_000)
    case 1_000_000..<1_000_000_000: return String(format: "%.1fM", v/1_000_000)
    case 1_000_000_000..<1_000_000_000_000: return String(format: "%.1fG", v/1_000_000_000)
    default: return String(format: "%.1fT", v/1_000_000_000_000)
    }
}

