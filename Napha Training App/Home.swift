//
//  Home.swift
//  Napha Training App
//

import SwiftUI

extension Notification.Name {
    static let workoutNotificationTapped = Notification.Name("workoutNotificationTapped")
}

struct HelpTipSheet: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct OnboardingStepContainer<Content: View>: View {
    let subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.title2.weight(.bold))
                        .padding(.top, 4)
                }
                content()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
    }
}

struct AppLogoHeader: View {
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            Image("naapfa_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("nAPPfa")
                    .font(.title2.weight(.bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

struct Home: View {
    @Binding var info: data
    @State var prevWorkout = UserDefaults.standard.string(forKey: AppKeys.previousWorkout) ?? ""
    @Binding var homeSelectedTimed: [Date]
    @Binding var homeSelectedDays: [Int]
    @Binding var schedSheet: Bool
    var onWorkoutNow: () -> Void = {}

    @State private var showGoalSheet = false
    @State private var streak = 0
    @State private var nextWorkout: Date?

    private var goals: [GoalDraft] {
        GoalDraft.fromSaved(info.Goals)
    }

    private var schedule: [(day: Int, time: Date)] {
        AppState.normalizedSchedule(days: homeSelectedDays, times: homeSelectedTimed)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 10) {
                    headerRow

                    if let birthday = AppState.birthdayMessage() {
                        Label(birthday, systemImage: "gift.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.pink)
                            .lineLimit(2)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.pink.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    HStack(spacing: 10) {
                        examTile
                        streakTile
                    }
                    .frame(height: proxy.size.height * 0.2)

                    nextWorkoutTile
                        .frame(height: proxy.size.height * 0.22)

                    HStack(spacing: 10) {
                        scheduleTile
                        goalsTile
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
                .overlay(alignment: .top) {
                    if AppState.birthdayMessage() != nil {
                        ConfettiBurst()
                            .allowsHitTesting(false)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $schedSheet) {
                Scheduling_(
                    start: .constant(false),
                    info: $info,
                    selectedDays: $homeSelectedDays,
                    selectedTimes: $homeSelectedTimed,
                    schedSheet: $schedSheet
                )
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
            .onAppear(perform: refresh)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refresh()
            }
            .onChange(of: homeSelectedDays) { refresh() }
            .onChange(of: homeSelectedTimed) { refresh() }
            .onChange(of: info.Goals) { refresh() }
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("nAPPfa")
                    .font(.title.weight(.bold))
                Text("Dashboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showGoalSheet = true
            } label: {
                Image(systemName: "target")
                    .font(.title3.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(.background, in: Circle())
            }
            .accessibilityLabel("Edit goals")
        }
    }

    private var examTile: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("NAPFA test", systemImage: "calendar")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(AppState.examCountdownText(to: info.NAPFA_Date))
                .font(.system(size: 28, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(info.NAPFA_Date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var streakTile: some View {
        VStack(alignment: .center, spacing: 2) {
            Label("Streak", systemImage: "flame.fill")
                .font(.caption.weight(.bold))
            Text("\(streak)")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(streak == 1 ? "day" : "days")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.black)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var nextWorkoutTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Next workout", systemImage: "clock.fill")
                    .font(.subheadline.weight(.bold))
                Spacer()
                if !prevWorkout.isEmpty {
                    Text("Last: \(prevWorkout)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(AppState.relativeWorkoutText(for: nextWorkout))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .minimumScaleFactor(0.75)

            Text(nextWorkout.map(AppState.formattedDateTime) ?? "Set your schedule")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button(action: onWorkoutNow) {
                    Label("Workout now", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(AppState.hasWorkedOutToday())

                Button {
                    AppState.markWorkoutRescheduled()
                    NotificationCoordinator.cancelPendingWorkoutNotifications()
                    schedSheet = true
                } label: {
                    Image(systemName: "calendar.badge.clock")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(AppState.hasWorkedOutToday())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var scheduleTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Schedule")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button("Edit") { schedSheet = true }
                    .font(.caption.weight(.semibold))
            }

            if schedule.isEmpty {
                Text("Pick 3+ days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(schedule, id: \.day) { item in
                        HStack {
                            Text(AppState.shortDayName(item.day))
                                .font(.caption.weight(.black))
                                .frame(width: 36, height: 28)
                                .background(.blue.opacity(0.12), in: Capsule())
                            Spacer()
                            Text(AppState.formattedTime(item.time))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var goalsTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Goals")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button("Edit") { showGoalSheet = true }
                    .font(.caption.weight(.semibold))
            }

            if goals.isEmpty {
                Text("Set targets to adapt workouts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(goals) { goal in
                        HStack(spacing: 8) {
                            let station = NAPFAStation(rawValue: goal.station)
                            Image(systemName: station?.icon ?? "target")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(goal.text)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(targetText(for: station))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func refresh() {
        streak = AppState.currentStreak(selectedDays: homeSelectedDays, selectedTimes: homeSelectedTimed)
        nextWorkout = AppState.nextWorkoutDate(days: homeSelectedDays, times: homeSelectedTimed)
        prevWorkout = UserDefaults.standard.string(forKey: AppKeys.previousWorkout) ?? prevWorkout
        NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: homeSelectedDays, selectedTimes: homeSelectedTimed)
    }

    private func targetText(for station: NAPFAStation?) -> String {
        guard let station, let index = NAPFAStation.allCases.firstIndex(of: station) else {
            return "No grades set"
        }

        let hasPrev = info.prev.indices.contains(index) && !info.prev[index].isEmpty
        let hasTarg = info.targ.indices.contains(index) && !info.targ[index].isEmpty

        let prevGrade = hasPrev ? info.prev[index] : "Not set"
        let targGrade = hasTarg ? info.targ[index] : "Not set"

        return "\(prevGrade) → \(targGrade)"
    }
}

private struct ConfettiBurst: View {
    private let colors: [Color] = [.pink, .yellow, .green, .blue, .purple, .orange]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let tick = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<42 {
                    let x = size.width * CGFloat((Double((index * 37) % 100) / 100.0))
                    let speed = 22 + Double(index % 7) * 8
                    let y = CGFloat((tick * speed + Double(index * 19)).truncatingRemainder(dividingBy: 210)) - 30
                    let rect = CGRect(x: x, y: y, width: 6, height: 10)
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(colors[index % colors.count]))
                }
            }
        }
        .frame(height: 210)
    }
}

#Preview {
    Home(
        info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
        homeSelectedTimed: .constant([]),
        homeSelectedDays: .constant([]),
        schedSheet: .constant(false)
    )
}
