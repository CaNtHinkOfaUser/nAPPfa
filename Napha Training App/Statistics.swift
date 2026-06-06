//
//  Statistics.swift
//  Napha Training App
//
//  Created by Alvarez Marco Lorenzo Tanzon on 9/9/24.
//

import SwiftUI

struct Statistics: View {
    @Binding var info: data
    @Binding var selectedDays: [Int]
    @Binding var selectedTimes: [Date]

    @State private var showGoalSheet = false

    private var goals: [GoalDraft] {
        GoalDraft.fromSaved(info.Goals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    streakSummary
                        .padding(.top, 8)
                    workoutSummary
                    gradeProgress
                    goalSummary
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 110)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit Goals") {
                        showGoalSheet = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showGoalSheet) {
                Goal_Page(
                    start: .constant(false),
                    info: $info,
                    Sex: .constant(info.Gender),
                    Age: .constant(info.Age),
                    GoalSheet: $showGoalSheet
                )
            }
        }
    }

    private var streakSummary: some View {
        let streak = AppState.currentStreak(selectedDays: selectedDays, selectedTimes: selectedTimes)

        return HStack(spacing: 14) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.orange)

            VStack(alignment: .center, spacing: 4) {
                Text("Current streak")
                    .font(.headline)
                Text("\(streak) \(streak == 1 ? "day" : "days")")
                    .font(.system(size: 34, weight: .black, design: .rounded))
            }

            Spacer()
        }
        .padding(18)
        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .foregroundStyle(.black)
    }

    private var workoutSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Workout History", systemImage: "chart.bar.fill")
                .font(.title3.weight(.bold))

            HStack(spacing: 12) {
                StatTile(title: "7 days", value: "\(AppState.workoutsInLast(days: 7))")
                StatTile(title: "30 days", value: "\(AppState.workoutsInLast(days: 30))")
                StatTile(title: "Total", value: "\(AppState.workoutHistory().count)")
            }

            WeeklyBars()
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var gradeProgress: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Targets", systemImage: "target")
                .font(.title3.weight(.bold))

            ForEach(NAPFAStation.allCases.indices, id: \.self) { index in
                let previous = grade(at: index, in: info.prev)
                let target = grade(at: index, in: info.targ)

                if previous != "Not set" || target != "Not set" {
                    HStack {
                        Image(systemName: NAPFAStation.allCases[index].icon)
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 30)

                        Text(NAPFAStation.allCases[index].rawValue)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Text("\(previous) -> \(target)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if info.prev.allSatisfy({ $0.isEmpty }) && info.targ.allSatisfy({ $0.isEmpty }) {
                ContentUnavailableView("No target grades", systemImage: "target")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var goalSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("My Goals", systemImage: "list.bullet.clipboard")
                .font(.title3.weight(.bold))

            if goals.isEmpty {
                ContentUnavailableView("No saved goals", systemImage: "target")
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(goals) { goal in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: NAPFAStation(rawValue: goal.station)?.icon ?? "target")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(goal.text)
                                .font(.body.weight(.semibold))
                            Text(goal.station)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func grade(at index: Int, in values: [String]) -> String {
        guard values.indices.contains(index), !values[index].isEmpty else {
            return "Not set"
        }
        return values[index]
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WeeklyBars: View {
    private var counts: [Int] {
        let calendar = Calendar.current
        let history = AppState.workoutHistory()

        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: Date()) else { return 0 }
            return history.filter { calendar.isDate($0, inSameDayAs: date) }.count
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(counts.indices, id: \.self) { index in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(counts[index] > 0 ? Color.green : Color(.tertiarySystemFill))
                        .frame(height: counts[index] > 0 ? 44 : 12)
                    Text(dayLabel(index))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 78)
    }

    private func dayLabel(_ index: Int) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: -6 + index, to: Date()) else { return "" }
        return String(calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(1))
    }
}

#Preview {
    Statistics(
        info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
        selectedDays: .constant([]),
        selectedTimes: .constant([])
    )
}
