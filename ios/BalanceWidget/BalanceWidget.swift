import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(
            date: Date(),
            hasData: true,
            currentWeight: "78.5",
            unit: "kg",
            deltaText: "-0.4 kg",
            deltaIsLoss: true,
            targetWeight: "75.0 kg",
            goalProgressPct: 70,
            lastEntryDate: "Dzisiaj, 08:30"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> ()) {
        let entry = getEntryFromUserDefaults()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntryFromUserDefaults()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func getEntryFromUserDefaults() -> BalanceEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.ekerstudio.balance")
        let hasData = userDefaults?.bool(forKey: "has_data") ?? false
        let currentWeight = userDefaults?.string(forKey: "current_weight") ?? "--"
        let unit = userDefaults?.string(forKey: "unit") ?? "kg"
        let deltaText = userDefaults?.string(forKey: "delta_text") ?? ""
        let deltaIsLoss = userDefaults?.bool(forKey: "delta_is_loss") ?? false
        let targetWeight = userDefaults?.string(forKey: "target_weight") ?? ""
        let goalProgressPct = userDefaults?.integer(forKey: "goal_progress_pct") ?? 0
        let lastEntryDate = userDefaults?.string(forKey: "last_entry_date") ?? ""

        return BalanceEntry(
            date: Date(),
            hasData: hasData,
            currentWeight: currentWeight,
            unit: unit,
            deltaText: deltaText,
            deltaIsLoss: deltaIsLoss,
            targetWeight: targetWeight,
            goalProgressPct: goalProgressPct,
            lastEntryDate: lastEntryDate
        )
    }
}

struct BalanceEntry: TimelineEntry {
    let date: Date
    let hasData: Bool
    let currentWeight: String
    let unit: String
    let deltaText: String
    let deltaIsLoss: Bool
    let targetWeight: String
    let goalProgressPct: Int
    let lastEntryDate: String
}

struct BalanceWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.hasData {
            VStack(spacing: 6) {
                Text("Balance")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)
                Spacer()
                Text("Brak pomiarów")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Dotknij, aby dodać")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
        } else {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
    }
}

struct SmallWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Balance")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)
                Spacer()
                Text(entry.lastEntryDate)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(entry.currentWeight)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(entry.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !entry.deltaText.isEmpty {
                Text(entry.deltaText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(entry.deltaIsLoss ? Color.green : Color.red)
            }

            Spacer()

            if !entry.targetWeight.isEmpty {
                ProgressView(value: Double(entry.goalProgressPct), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                HStack {
                    Text("Cel: \(entry.targetWeight)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(entry.goalProgressPct)%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
    }
}

struct MediumWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(entry.currentWeight)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(entry.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !entry.deltaText.isEmpty {
                    Text(entry.deltaText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(entry.deltaIsLoss ? Color.green : Color.red)
                }

                Text(entry.lastEntryDate)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                if !entry.targetWeight.isEmpty {
                    Text("Postęp celu")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ProgressView(value: Double(entry.goalProgressPct), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))

                    HStack {
                        Text("Cel: \(entry.targetWeight)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(entry.goalProgressPct)%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("Brak ustalonego celu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Ustaw cel wagi w ustawieniach aplikacji.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(14)
    }
}

@main
struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Balance")
        .description("Wyświetla ostatni pomiar wagi oraz postęp w realizacji celu.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
