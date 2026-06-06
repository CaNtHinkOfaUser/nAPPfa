//
//  Scheduling .swift
//  Napha Training App
//
//  Created by Ishaan on 2/8/24.
//

import SwiftUI

struct Scheduling_: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var start: Bool
    @Binding var info: data
    @Binding var selectedDays: [Int]
    @Binding var selectedTimes: [Date]
    @Binding var schedSheet: Bool

    @State private var times: [Date] = Array(repeating: Date(), count: 7)
    @State private var NAPFA_Date: Date = Date.now
    @State private var savedStatus = "Saved"
    @State private var remindersEnabled = true
    @State private var reminderOneHour = true
    @State private var reminderTenMinutes = true
    @State private var reminderNow = true

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        Group {
            if start {
                OnboardingStepContainer(subtitle: "Schedule") {
                    VStack(alignment: .leading, spacing: 20) {
                        dateSection
                        daySection
                        timeSection
                        reminderSection
                    }
                }
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            dateSection
                                .padding(.top, 8)
                            daySection
                            timeSection
                            reminderSection
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 28)
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("Scheduling")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                persistSchedule()
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .disabled(!AppState.isScheduleComplete(days: selectedDays, times: selectedTimes))
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadSchedule)
        .onChange(of: selectedDays) {
            persistSchedule()
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("NAPFA Date", systemImage: "calendar.badge.clock")
                .font(.title3.weight(.bold))

            DatePicker("Test date", selection: $NAPFA_Date, in: Date.now..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .onChange(of: NAPFA_Date) {
                    info.NAPFA_Date = NAPFA_Date
                    UserDefaults.standard.set(NAPFA_Date, forKey: AppKeys.napfaDate)
                    markSaved()
                }

            Label(savedStatus, systemImage: "checkmark.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var daySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Workout Days", systemImage: "calendar")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(selectedDays.count)/3")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(selectedDays.count >= 3 ? .green : .red)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(AppState.dayNames.indices, id: \.self) { day in
                    Button {
                        toggleDay(day)
                    } label: {
                        VStack(spacing: 4) {
                            Text(String(AppState.dayName(day).prefix(1)))
                                .font(.title3.weight(.black))
                            Text(AppState.shortDayName(day))
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                        .background(selectedDays.contains(day) ? Color.blue : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppState.dayName(day))
                }
            }

            if selectedDays.count < 3 {
                Label("Choose at least three workout days", systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Workout Timing", systemImage: "clock")
                .font(.title3.weight(.bold))

            let sortedDays = selectedDays.sorted()
            if sortedDays.isEmpty {
                ContentUnavailableView("No days selected", systemImage: "clock.badge.questionmark")
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedDays, id: \.self) { day in
                        HStack {
                            Text(AppState.dayName(day))
                                .font(.body.weight(.semibold))
                            Spacer()
                            DatePicker("", selection: bindingForTime(day), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reminders", systemImage: "bell.badge")
                .font(.title3.weight(.bold))

            Toggle("Workout reminders", isOn: $remindersEnabled)
                .font(.subheadline.weight(.semibold))
                .onChange(of: remindersEnabled) {
                    persistReminders()
                }

            HStack(spacing: 10) {
                ReminderTogglePill(text: "1h", isOn: $reminderOneHour, isEnabled: remindersEnabled)
                ReminderTogglePill(text: "10m", isOn: $reminderTenMinutes, isEnabled: remindersEnabled)
                ReminderTogglePill(text: "Now", isOn: $reminderNow, isEnabled: remindersEnabled)
            }
            .onChange(of: reminderOneHour) { persistReminders() }
            .onChange(of: reminderTenMinutes) { persistReminders() }
            .onChange(of: reminderNow) { persistReminders() }

            Text("If today's workout is already complete, reminders are skipped.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func bindingForTime(_ day: Int) -> Binding<Date> {
        Binding {
            times.indices.contains(day) ? times[day] : Date()
        } set: { newValue in
            guard times.indices.contains(day) else { return }
            times[day] = newValue
            persistSchedule()
        }
    }

    private func toggleDay(_ day: Int) {
        withAnimation(.easeInOut(duration: 0.18)) {
            if selectedDays.contains(day) {
                selectedDays.removeAll { $0 == day }
            } else {
                selectedDays.append(day)
            }
            persistSchedule()
        }
    }

    private func loadSchedule() {
        let defaults = UserDefaults.standard

        if let storedNAPFA_Date = defaults.object(forKey: AppKeys.napfaDate) as? Date {
            NAPFA_Date = storedNAPFA_Date
            info.NAPFA_Date = storedNAPFA_Date
        }

        selectedDays = defaults.object(forKey: AppKeys.selectedDays) as? [Int] ?? selectedDays
        selectedTimes = defaults.object(forKey: AppKeys.selectedTimes) as? [Date] ?? selectedTimes

        if let storedTimes = defaults.object(forKey: AppKeys.scheduleTimes) as? [Date], storedTimes.count == 7 {
            times = storedTimes
        }

        if defaults.object(forKey: AppKeys.remindersEnabled) == nil {
            defaults.set(true, forKey: AppKeys.remindersEnabled)
            defaults.set(true, forKey: AppKeys.reminderOneHour)
            defaults.set(true, forKey: AppKeys.reminderTenMinutes)
            defaults.set(true, forKey: AppKeys.reminderNow)
        }
        remindersEnabled = defaults.bool(forKey: AppKeys.remindersEnabled)
        reminderOneHour = defaults.bool(forKey: AppKeys.reminderOneHour)
        reminderTenMinutes = defaults.bool(forKey: AppKeys.reminderTenMinutes)
        reminderNow = defaults.bool(forKey: AppKeys.reminderNow)

        for (day, time) in zip(selectedDays, selectedTimes) where times.indices.contains(day) {
            times[day] = time
        }

        persistSchedule()
    }

    private func persistSchedule() {
        let sortedDays = selectedDays.sorted()
        selectedDays = sortedDays
        selectedTimes = sortedDays.compactMap { day in
            times.indices.contains(day) ? times[day] : nil
        }

        let defaults = UserDefaults.standard
        defaults.set(selectedDays, forKey: AppKeys.selectedDays)
        defaults.set(selectedTimes, forKey: AppKeys.selectedTimes)
        defaults.set(times, forKey: AppKeys.scheduleTimes)
        defaults.set(NAPFA_Date, forKey: AppKeys.napfaDate)
        info.NAPFA_Date = NAPFA_Date

        _ = AppState.currentStreak(selectedDays: selectedDays, selectedTimes: selectedTimes)
        NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: selectedDays, selectedTimes: selectedTimes)
        markSaved()
    }

    private func persistReminders() {
        let defaults = UserDefaults.standard
        defaults.set(remindersEnabled, forKey: AppKeys.remindersEnabled)
        defaults.set(reminderOneHour, forKey: AppKeys.reminderOneHour)
        defaults.set(reminderTenMinutes, forKey: AppKeys.reminderTenMinutes)
        defaults.set(reminderNow, forKey: AppKeys.reminderNow)
        NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: selectedDays, selectedTimes: selectedTimes)
        markSaved()
    }

    private func markSaved() {
        savedStatus = "Saved \(Date().formatted(date: .omitted, time: .shortened))"
    }
}

private struct ReminderTogglePill: View {
    let text: String
    @Binding var isOn: Bool
    let isEnabled: Bool

    var body: some View {
        Button {
            guard isEnabled else { return }
            isOn.toggle()
        } label: {
            Text(text)
                .font(.subheadline.weight(.bold))
                .frame(width: 56, height: 36)
                .background(isOn && isEnabled ? .blue.opacity(0.14) : Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(isOn && isEnabled ? .blue : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    Scheduling_(
        start: .constant(false),
        info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
        selectedDays: .constant([]),
        selectedTimes: .constant([]),
        schedSheet: .constant(false)
    )
}
