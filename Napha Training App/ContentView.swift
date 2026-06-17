import SwiftUI
import AVFoundation
import AudioToolbox
import UserNotifications
#if canImport(WidgetKit)
import WidgetKit
#endif

final class SoundManager {
    static let instance = SoundManager()

    private var player: AVAudioPlayer?
    private var toneEngine: AVAudioEngine?
    private var tonePlayer: AVAudioPlayerNode?

    func playSound() {
        let extensions = ["caf", "wav", "mp3", "m4a"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: "Alarm", withExtension: ext) {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)
                    player = try AVAudioPlayer(contentsOf: url)
                    player?.volume = 1.0
                    player?.prepareToPlay()
                    player?.play()
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    return
                } catch {
                    print("Error playing bundled alarm.\(ext): \(error.localizedDescription)")
                }
            }
        }

        playGeneratedTone()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func playGeneratedTone() {
        let sampleRate = 44100.0
        let duration = 0.55
        let frequency = 880.0
        let frameCount = Int(sampleRate * duration)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        guard let channel = buffer.floatChannelData?[0] else {
            AudioServicesPlayAlertSound(SystemSoundID(1322))
            return
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        for index in 0..<frameCount {
            let time = Double(index) / sampleRate
            let envelope = Float(1.0 - (time / duration))
            let sample = Float(sin(2.0 * Double.pi * frequency * time))
            channel[index] = sample * envelope
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let engine = AVAudioPlayerNode()
            let audioEngine = AVAudioEngine()
            toneEngine = audioEngine
            tonePlayer = engine
            audioEngine.attach(engine)
            audioEngine.connect(engine, to: audioEngine.mainMixerNode, format: format)
            try audioEngine.start()
            engine.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            engine.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
                audioEngine.stop()
                if self.toneEngine === audioEngine {
                    self.toneEngine = nil
                    self.tonePlayer = nil
                }
            }
        } catch {
            AudioServicesPlayAlertSound(SystemSoundID(1322))
        }
    }
}

struct data {
    var Age: Int
    var Gender: Bool
    var prev: [String]
    var targ: [String]
    var schedule: [String]
    var NAPFA_Date: Date
    var Goals: [[String]]

    init(Age: Int, Gender: Bool, prev: [String], targ: [String], schedule: [String], NAPFA_Date: Date, Goals: [[String]]) {
        self.Age = Age
        self.Gender = Gender
        self.prev = prev
        self.targ = targ
        self.schedule = schedule
        self.NAPFA_Date = NAPFA_Date
        self.Goals = Goals

        UITabBar.appearance().isHidden = true
    }
}

enum AppKeys {
    static let firstTime = "fT"
    static let selectedDays = "SD"
    static let selectedTimes = "ST"
    static let scheduleTimes = "times"
    static let napfaDate = "NAPFA_Date"
    static let sex = "sex"
    static let age = "age"
    static let birthdate = "birthdate"
    static let profileCompleted = "profileCompleted"
    static let birthdateCompleted = "birthdateCompleted"
    static let genderCompleted = "genderCompleted"
    static let previousGrades = "prev"
    static let targetGrades = "targ"
    static let enabledGrades = "Lin"
    static let goals = "sGoals"
    static let remindersEnabled = "remindersEnabled"
    static let reminderOneHour = "reminderOneHour"
    static let reminderTenMinutes = "reminderTenMinutes"
    static let reminderNow = "reminderNow"
    static let downloadDate = "DOWNLOADDATE"
    static let lastWorkoutDate = "lastWorkoutDate"
    static let workoutHistory = "workoutHistory"
    static let currentStreak = "currentStreak"
    static let previousWorkout = "prevWorkout"
    static let openWorkoutFromNotification = "openWorkoutFromNotification"
    static let openScheduleFromNotification = "openScheduleFromNotification"
    static let showNotificationChoiceAlert = "showNotificationChoiceAlert"
    static let rescheduledWorkoutDay = "rescheduledWorkoutDay"
    static let widgetSuiteName = "group.k.Napha-Training-App"
    static let widgetNextWorkout = "widgetNextWorkout"
    static let widgetStreak = "widgetStreak"
    static let widgetGoal = "widgetGoal"
}

enum NAPFAStation: String, CaseIterable, Identifiable {
    case sitUps = "Sit Ups"
    case standingBroadJump = "Standing Broad Jump"
    case sitAndReach = "Sit & Reach"
    case inclinedPullUps = "Inclined Pull Ups"
    case shuttleRun = "Shuttle Run"
    case run = "2.4km Run"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sitUps: return "figure.core.training"
        case .standingBroadJump: return "figure.jumprope"
        case .sitAndReach: return "figure.flexibility"
        case .inclinedPullUps: return "figure.strengthtraining.traditional"
        case .shuttleRun: return "figure.run"
        case .run: return "figure.run.circle"
        }
    }

    var unit: String {
        switch self {
        case .sitUps, .inclinedPullUps: return "reps"
        case .standingBroadJump, .sitAndReach: return "cm"
        case .shuttleRun, .run: return "time"
        }
    }

    var videoURL: URL {
        URL(string: tutorialVideoLink)!
    }

    private var tutorialVideoLink: String {
        switch self {
        case .sitUps:
            return "https://www.youtube.com/watch?v=ILSg8_BlgIM"
        case .standingBroadJump:
            return "https://www.youtube.com/watch?v=hSunks_4wIE"
        case .sitAndReach:
            return "https://www.youtube.com/watch?v=Br6be7YEmKM"
        case .inclinedPullUps:
            return "https://www.youtube.com/watch?v=eGo4IYlbE5g"
        case .shuttleRun:
            return "https://www.youtube.com/watch?v=eQw7jWxH8dE"
        case .run:
            return "https://www.youtube.com/watch?v=brFHyOtTwH4"
        }
    }

    var shortTip: String {
        switch self {
        case .sitUps: return "Core endurance and pacing"
        case .standingBroadJump: return "Power, landing, and arm swing"
        case .sitAndReach: return "Hamstring and hip mobility"
        case .inclinedPullUps: return "Back strength and full range"
        case .shuttleRun: return "Acceleration and clean turns"
        case .run: return "Aerobic base and pace control"
        }
    }
}

struct GoalDraft: Identifiable, Equatable {
    var id = UUID()
    var text: String
    var station: String

    init(text: String = "", station: String = NAPFAStation.sitUps.rawValue) {
        self.text = text
        self.station = station
    }

    static func fromSaved(_ saved: [[String]]) -> [GoalDraft] {
        saved.map { goal in
            GoalDraft(
                text: goal.indices.contains(0) ? goal[0] : "",
                station: goal.indices.contains(1) ? goal[1] : NAPFAStation.sitUps.rawValue
            )
        }
    }

    static func encode(_ drafts: [GoalDraft]) -> [[String]] {
        drafts
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { [$0.text, $0.station] }
    }
}

enum AppState {
    static let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    static let shortDayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    static func mondayIndex(for date: Date) -> Int {
        (Calendar.current.component(.weekday, from: date) + 5) % 7
    }

    static func dayName(_ index: Int) -> String {
        guard dayNames.indices.contains(index) else { return "Day" }
        return dayNames[index]
    }

    static func shortDayName(_ index: Int) -> String {
        guard shortDayNames.indices.contains(index) else { return "Day" }
        return shortDayNames[index]
    }

    static func formattedTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func formattedDateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func normalizedSchedule(days: [Int], times: [Date]) -> [(day: Int, time: Date)] {
        Array(zip(days, times))
            .filter { 0..<7 ~= $0.0 }
            .sorted {
                if $0.0 == $1.0 {
                    let lhs = Calendar.current.dateComponents([.hour, .minute], from: $0.1)
                    let rhs = Calendar.current.dateComponents([.hour, .minute], from: $1.1)
                    return (lhs.hour ?? 0, lhs.minute ?? 0) < (rhs.hour ?? 0, rhs.minute ?? 0)
                }
                return $0.0 < $1.0
            }
    }

    static func date(on day: Date, matching time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? day
    }

    static func nextWorkoutDate(days: [Int], times: [Date], now: Date = Date(), skipTodayIfCompleted: Bool = true) -> Date? {
        upcomingWorkoutDates(days: days, times: times, now: now, horizonDays: 14, skipTodayIfCompleted: skipTodayIfCompleted).first
    }

    static func upcomingWorkoutDates(days: [Int], times: [Date], now: Date = Date(), horizonDays: Int = 14, skipTodayIfCompleted: Bool = true) -> [Date] {
        let schedule = normalizedSchedule(days: days, times: times)
        guard !schedule.isEmpty else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let didWorkoutToday = skipTodayIfCompleted && hasWorkedOutToday(now: now)
        var candidates: [Date] = []

        for offset in 0..<max(horizonDays, 1) {
            guard let candidateDay = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let dayIndex = mondayIndex(for: candidateDay)

            for item in schedule where item.day == dayIndex {
                let candidate = date(on: candidateDay, matching: item.time)
                if isWithinRescheduleGrace(for: candidateDay, now: now) {
                    continue
                }
                if didWorkoutToday && calendar.isDate(candidate, inSameDayAs: now) {
                    continue
                }
                if candidate > now {
                    candidates.append(candidate)
                }
            }
        }

        return candidates.sorted()
    }

    static func relativeWorkoutText(for date: Date?, now: Date = Date()) -> String {
        guard let date else { return "Not set" }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        let dayCount = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if dayCount <= 0 {
            return date <= now ? "Now" : "Today"
        } else if dayCount == 1 {
            return "Tomorrow"
        } else {
            return "\(dayCount) days"
        }
    }

    static func examCountdownText(to date: Date, now: Date = Date()) -> String {
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: date)).day ?? 0)
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }

    static func markWorkoutRescheduled(for day: Date = Date()) {
        let calendar = Calendar.current
        UserDefaults.standard.set(calendar.startOfDay(for: day), forKey: AppKeys.rescheduledWorkoutDay)
    }

    static func clearRescheduleGrace() {
        UserDefaults.standard.removeObject(forKey: AppKeys.rescheduledWorkoutDay)
    }

    static func isWithinRescheduleGrace(for scheduledDay: Date, now: Date = Date()) -> Bool {
        guard let rescheduledDay = UserDefaults.standard.object(forKey: AppKeys.rescheduledWorkoutDay) as? Date else {
            return false
        }

        let calendar = Calendar.current
        guard calendar.isDate(scheduledDay, inSameDayAs: rescheduledDay) else { return false }
        guard let graceEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: rescheduledDay)) else {
            return false
        }
        return now < graceEnd
    }

    static func hasWorkedOutToday(now: Date = Date()) -> Bool {
        guard let lastWorkout = UserDefaults.standard.object(forKey: AppKeys.lastWorkoutDate) as? Date else {
            return false
        }
        return Calendar.current.isDate(lastWorkout, inSameDayAs: now)
    }

    static func workoutHistory() -> [Date] {
        UserDefaults.standard.object(forKey: AppKeys.workoutHistory) as? [Date] ?? []
    }

    static func workoutsInLast(days: Int, now: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -days, to: now) else { return 0 }
        return workoutHistory().filter { $0 >= start && $0 <= now }.count
    }

    static func currentStreak(selectedDays: [Int], selectedTimes: [Date], now: Date = Date()) -> Int {
        let defaults = UserDefaults.standard
        guard let lastWorkout = defaults.object(forKey: AppKeys.lastWorkoutDate) as? Date else {
            defaults.set(0, forKey: AppKeys.currentStreak)
            return 0
        }

        if Calendar.current.isDate(lastWorkout, inSameDayAs: now) {
            return max(defaults.integer(forKey: AppKeys.currentStreak), 1)
        }

        if missedScheduledDayBetween(lastWorkout, and: now, selectedDays: selectedDays) {
            defaults.set(0, forKey: AppKeys.currentStreak)
            persistWidgetSummary(selectedDays: selectedDays, selectedTimes: selectedTimes)
            return 0
        }

        return defaults.integer(forKey: AppKeys.currentStreak)
    }

    static func recordWorkoutCompleted(station: String, now: Date = Date()) {
        let defaults = UserDefaults.standard
        let selectedDays = defaults.object(forKey: AppKeys.selectedDays) as? [Int] ?? []
        let selectedTimes = defaults.object(forKey: AppKeys.selectedTimes) as? [Date] ?? []

        guard !hasWorkedOutToday(now: now) else {
            defaults.set(station, forKey: AppKeys.previousWorkout)
            NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: selectedDays, selectedTimes: selectedTimes)
            return
        }

        let previousWorkout = defaults.object(forKey: AppKeys.lastWorkoutDate) as? Date
        let oldStreak = currentStreak(selectedDays: selectedDays, selectedTimes: selectedTimes, now: now)
        let newStreak: Int

        if let previousWorkout, !missedScheduledDayBetween(previousWorkout, and: now, selectedDays: selectedDays) {
            newStreak = max(oldStreak, 0) + 1
        } else {
            newStreak = 1
        }

        var history = workoutHistory()
        history.append(now)

        defaults.set(now, forKey: AppKeys.lastWorkoutDate)
        defaults.set(history, forKey: AppKeys.workoutHistory)
        defaults.set(newStreak, forKey: AppKeys.currentStreak)
        defaults.set(station, forKey: AppKeys.previousWorkout)
        clearRescheduleGrace()

        NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: selectedDays, selectedTimes: selectedTimes)
    }

    static func birthdayMessage(now: Date = Date()) -> String? {
        guard let birthdate = UserDefaults.standard.object(forKey: AppKeys.birthdate) as? Date else {
            return nil
        }

        let calendar = Calendar.current
        let birthday = calendar.dateComponents([.month, .day], from: birthdate)
        let today = calendar.dateComponents([.month, .day], from: now)

        return birthday.month == today.month && birthday.day == today.day ? "Happy birthday!" : nil
    }

    static func isProfileComplete() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: AppKeys.profileCompleted)
            && defaults.bool(forKey: AppKeys.birthdateCompleted)
            && defaults.bool(forKey: AppKeys.genderCompleted)
    }

    static func isScheduleComplete(days: [Int], times: [Date]) -> Bool {
        days.count >= 3 && times.count == days.count
    }

    static func enabledGoalStations(from info: data) -> [NAPFAStation] {
        let saved = UserDefaults.standard.object(forKey: AppKeys.enabledGrades) as? [Bool] ?? []
        return NAPFAStation.allCases.enumerated().compactMap { index, station in
            let enabled = saved.indices.contains(index) ? saved[index] : false
            let hasSavedGrade = (info.prev.indices.contains(index) && !info.prev[index].isEmpty)
                || (info.targ.indices.contains(index) && !info.targ[index].isEmpty)
            return enabled || hasSavedGrade ? station : nil
        }
    }

    static func persistWidgetSummary(selectedDays: [Int], selectedTimes: [Date]) {
        let defaults = UserDefaults.standard
        let nextWorkout = nextWorkoutDate(days: selectedDays, times: selectedTimes)
        let goal = (defaults.object(forKey: AppKeys.goals) as? [[String]])?.first?.first ?? "Set a NAPFA goal"
        let stores = [defaults, UserDefaults(suiteName: AppKeys.widgetSuiteName)].compactMap { $0 }

        for store in stores {
            store.set(nextWorkout, forKey: AppKeys.widgetNextWorkout)
            store.set(defaults.integer(forKey: AppKeys.currentStreak), forKey: AppKeys.widgetStreak)
            store.set(goal, forKey: AppKeys.widgetGoal)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private static func missedScheduledDayBetween(_ previousWorkout: Date, and now: Date, selectedDays: [Int]) -> Bool {
        guard !selectedDays.isEmpty else { return false }

        let calendar = Calendar.current
        var cursor = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: previousWorkout)) ?? now
        let today = calendar.startOfDay(for: now)

        while cursor < today {
            if selectedDays.contains(mondayIndex(for: cursor)) {
                if isWithinRescheduleGrace(for: cursor, now: now) {
                    cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today
                    continue
                }
                return true
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today
        }

        return false
    }
}

enum NotificationCoordinator {
    static let categoryIdentifier = "NAPFA_WORKOUT_REMINDER"
    static let workoutActionIdentifier = "WORKOUT_NOW"
    static let rescheduleActionIdentifier = "RESCHEDULE_WORKOUT"

    private static let legacyIdentifiers = [
        "napfa.workout.oneHour",
        "napfa.workout.tenMinutes",
        "napfa.workout.now"
    ]
    private static let horizonDays = 14

    static func configureCategories() {
        let workout = UNNotificationAction(
            identifier: workoutActionIdentifier,
            title: "Workout Now",
            options: [.foreground]
        )
        let reschedule = UNNotificationAction(
            identifier: rescheduleActionIdentifier,
            title: "Reschedule",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [workout, reschedule],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func cancelPendingWorkoutNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allNotificationIdentifiers)
    }

    static func scheduleWorkoutNotifications(selectedDays: [Int], selectedTimes: [Date]) {
        let workouts = AppState.upcomingWorkoutDates(days: selectedDays, times: selectedTimes, horizonDays: horizonDays)
        scheduleWorkoutNotifications(for: workouts)
        AppState.persistWidgetSummary(selectedDays: selectedDays, selectedTimes: selectedTimes)
    }

    static func scheduleWorkoutNotifications(for workouts: [Date]) {
        cancelPendingWorkoutNotifications()

        let upcoming = workouts.filter { workout in
            !AppState.hasWorkedOutToday() || !Calendar.current.isDate(workout, inSameDayAs: Date())
        }
        guard !upcoming.isEmpty else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            guard granted else { return }

            let defaults = UserDefaults.standard
            if defaults.object(forKey: AppKeys.remindersEnabled) == nil {
                defaults.set(true, forKey: AppKeys.remindersEnabled)
                defaults.set(true, forKey: AppKeys.reminderOneHour)
                defaults.set(true, forKey: AppKeys.reminderTenMinutes)
                defaults.set(true, forKey: AppKeys.reminderNow)
            }
            guard defaults.bool(forKey: AppKeys.remindersEnabled) else { return }

            let reminders: [(key: String, offset: TimeInterval, title: String, enabled: Bool)] = [
                ("oneHour", 3600, "Workout in 1 hour", defaults.bool(forKey: AppKeys.reminderOneHour)),
                ("tenMinutes", 600, "Workout in 10 minutes", defaults.bool(forKey: AppKeys.reminderTenMinutes)),
                ("now", 0, "Workout time", defaults.bool(forKey: AppKeys.reminderNow))
            ].filter { $0.enabled }

            for (workoutIndex, workout) in upcoming.prefix(horizonDays).enumerated() {
                for reminder in reminders {
                    let fireDate = workout.addingTimeInterval(-reminder.offset)
                    guard fireDate > Date() else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = reminder.title
                    content.body = "Open nAPPfa to work out now or reschedule."
                    content.sound = .default
                    content.categoryIdentifier = categoryIdentifier

                    let trigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: max(1, fireDate.timeIntervalSinceNow),
                        repeats: false
                    )
                    let id = identifier(for: workoutIndex, reminder: reminder.key)
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }

    static func handle(response: UNNotificationResponse) {
        let defaults = UserDefaults.standard
        guard response.notification.request.content.categoryIdentifier == categoryIdentifier else { return }
        defaults.set(true, forKey: AppKeys.showNotificationChoiceAlert)
    }

    private static var allNotificationIdentifiers: [String] {
        legacyIdentifiers + (0..<horizonDays).flatMap { index in
            [
                identifier(for: index, reminder: "oneHour"),
                identifier(for: index, reminder: "tenMinutes"),
                identifier(for: index, reminder: "now")
            ]
        }
    }

    private static func identifier(for workoutIndex: Int, reminder: String) -> String {
        "napfa.workout.\(workoutIndex).\(reminder)"
    }
}

struct ContentView: View {
    @State var info = data(
        Age: 12,
        Gender: false,
        prev: ["", "", "", "", "", ""],
        targ: ["", "", "", "", "", ""],
        schedule: [],
        NAPFA_Date: Date.now,
        Goals: []
    )
    @State var selectedTimesCV: [Date] = []
    @State var selectedDaysCV: [Int] = []
    @State var Sex: Bool = true
    @State var age: Int = 12
    @State var prevWorkout = ""
    @State var firstTime = true
    @State var GoalSheetCV = false
    @State var AgeSheetCV = false
    @State var SchedSheetCV = false
    @State var showLogin = false
    @State var selectedTab: Tab = .house
    @StateObject private var workoutSession = WorkoutSessionState()
    @State private var showNotificationChoice = false

    var body: some View {
        ZStack(alignment: .bottom) {
            activeTab
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(workoutSession)

            if !workoutSession.locksTabBar {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showLogin) {
            StartingPage(
                info: $info,
                ageFirstTime: $firstTime,
                ageSheet: $AgeSheetCV,
                Sex: $Sex,
                Age: $age,
                goalSheet: $GoalSheetCV,
                schedSheet: $SchedSheetCV,
                selectedDays: $selectedDaysCV,
                selectedTimes: $selectedTimesCV,
                showLogin: $showLogin
            )
        }
        .onAppear {
            NotificationCoordinator.configureCategories()
            loadStoredData()
            routeFromNotificationFlags()
            refreshScheduleNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            routeFromNotificationFlags()
            refreshScheduleNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutNotificationTapped)) { _ in
            showNotificationChoice = true
        }
        .onChange(of: showLogin) {
            if showLogin == false {
                firstTime = false
                UserDefaults.standard.set(false, forKey: AppKeys.firstTime)
                loadStoredData()
                refreshScheduleNotifications()
            }
        }
        .onChange(of: selectedDaysCV) {
            refreshScheduleNotifications()
        }
        .onChange(of: selectedTimesCV) {
            refreshScheduleNotifications()
        }
        .alert("Workout reminder", isPresented: $showNotificationChoice) {
            Button("Workout now") {
                selectedTab = .dumbbell
            }
            Button("Reschedule") {
                AppState.markWorkoutRescheduled()
                NotificationCoordinator.cancelPendingWorkoutNotifications()
                selectedTab = .house
                SchedSheetCV = true
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Would you like to start your session now or reschedule it?")
        }
    }

    @ViewBuilder
    private var activeTab: some View {
        switch selectedTab {
        case .house:
            Home(
                info: $info,
                prevWorkout: prevWorkout,
                homeSelectedTimed: $selectedTimesCV,
                homeSelectedDays: $selectedDaysCV,
                schedSheet: $SchedSheetCV,
                onWorkoutNow: {
                    selectedTab = .dumbbell
                }
            )
        case .dumbbell:
            Workout(info: $info)
        case .gearshape:
            Settings(
                info: $info,
                GoalSheet: $GoalSheetCV,
                AgeSheet: $AgeSheetCV,
                SchedSheet: $SchedSheetCV,
                selectedTimedSettings: $selectedTimesCV,
                selectedDaysSettings: $selectedDaysCV,
                Sex: $Sex,
                age: $age,
                ftSettings: $firstTime
            )
        case .progression:
            Statistics(info: $info, selectedDays: $selectedDaysCV, selectedTimes: $selectedTimesCV)
        }
    }

    private func loadStoredData() {
        let defaults = UserDefaults.standard

        firstTime = defaults.object(forKey: AppKeys.firstTime) as? Bool ?? true
        if firstTime {
            showLogin = true
            if defaults.object(forKey: AppKeys.downloadDate) == nil {
                defaults.set(Date.now, forKey: AppKeys.downloadDate)
            }
        }

        selectedTimesCV = defaults.object(forKey: AppKeys.selectedTimes) as? [Date] ?? selectedTimesCV
        selectedDaysCV = defaults.object(forKey: AppKeys.selectedDays) as? [Int] ?? selectedDaysCV
        Sex = defaults.object(forKey: AppKeys.sex) as? Bool ?? Sex
        age = defaults.object(forKey: AppKeys.age) as? Int ?? age
        prevWorkout = defaults.string(forKey: AppKeys.previousWorkout) ?? prevWorkout

        info.Gender = Sex
        info.Age = age
        info.NAPFA_Date = defaults.object(forKey: AppKeys.napfaDate) as? Date ?? info.NAPFA_Date
        info.prev = defaults.object(forKey: AppKeys.previousGrades) as? [String] ?? info.prev
        info.targ = defaults.object(forKey: AppKeys.targetGrades) as? [String] ?? info.targ
        info.Goals = defaults.object(forKey: AppKeys.goals) as? [[String]] ?? info.Goals

        _ = AppState.currentStreak(selectedDays: selectedDaysCV, selectedTimes: selectedTimesCV)
        AppState.persistWidgetSummary(selectedDays: selectedDaysCV, selectedTimes: selectedTimesCV)
    }

    private func refreshScheduleNotifications() {
        _ = AppState.currentStreak(selectedDays: selectedDaysCV, selectedTimes: selectedTimesCV)
        NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: selectedDaysCV, selectedTimes: selectedTimesCV)
    }

    private func routeFromNotificationFlags() {
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: AppKeys.showNotificationChoiceAlert) {
            defaults.set(false, forKey: AppKeys.showNotificationChoiceAlert)
            showNotificationChoice = true
        }
    }
}

#Preview {
    ContentView()
}
