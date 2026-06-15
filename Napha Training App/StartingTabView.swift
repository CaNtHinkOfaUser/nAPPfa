//
//  StartingTabView.swift
//  Napha Training App
//
//  Created by Ishaan on 19/8/24.
//

import SwiftUI

struct StartingTabView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int = 0
    @Binding var info: data
    @Binding var ageFirstTime: Bool
    @Binding var ageSheet: Bool
    @Binding var Sex: Bool
    @Binding var Age: Int
    @Binding var goalSheet: Bool
    @Binding var selectedDays: [Int]
    @Binding var selectedTimes: [Date]
    @Binding var schedSheet: Bool
    @Binding var showLogin: Bool
    @State private var showRequirements = false
    
    var body: some View {
        VStack(spacing: 0) {
            progressHeader

            TabView(selection: guardedSelection) {
                Age_Gender(start: .constant(true), info: $info, ageFirstTime: $ageFirstTime, ageSheet: $ageSheet)
                    .tag(0)

                Goal_Page(start: .constant(true), info: $info, Sex: $Sex, Age: $Age, GoalSheet: $goalSheet)
                    .tag(1)

                Scheduling_(start: .constant(true), info: $info, selectedDays: $selectedDays, selectedTimes: $selectedTimes, schedSheet: $schedSheet)
                    .tag(2)

                completionPage
                    .tag(3)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemGroupedBackground))
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(selection + 1) of 4")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(stepTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(selection + 1), total: 4)
                .tint(.green)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }

    private var stepTitle: String {
        switch selection {
        case 0: return "Profile"
        case 1: return "Goals"
        case 2: return "Schedule"
        default: return "Ready"
        }
    }

    private var completionPage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 24)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)

                Text("You're set")
                    .font(.largeTitle.weight(.bold))

                Text("Your profile, goals, and schedule are saved. You can change them anytime from Home or Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if !canFinish {
                    VStack(alignment: .leading, spacing: 8) {
                        RequirementRow(text: "Birthdate selected", isMet: UserDefaults.standard.bool(forKey: AppKeys.birthdateCompleted))
                        RequirementRow(text: "Gender selected", isMet: UserDefaults.standard.bool(forKey: AppKeys.genderCompleted))
                        RequirementRow(text: "At least 1 station enabled", isMet: hasSelectedStation)
                        RequirementRow(text: "At least 3 workout days and times", isMet: AppState.isScheduleComplete(days: selectedDays, times: selectedTimes))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    finishOnboarding()
                } label: {
                    Label("Start Training", systemImage: "arrow.right.circle.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
                .disabled(!canFinish)

                Spacer(minLength: 56)
            }
            .padding(.horizontal, 28)
        }
        .scrollIndicators(.hidden)
    }

    private var guardedSelection: Binding<Int> {
        Binding {
            selection
        } set: { newValue in
            guard newValue <= selection || canNavigate(to: newValue) else {
                showRequirements = true
                return
            }
            selection = newValue
        }
    }

    private var hasSelectedStation: Bool {
        !info.prev.allSatisfy(\.isEmpty) || !info.targ.allSatisfy(\.isEmpty)
    }

    private var canFinish: Bool {
        UserDefaults.standard.bool(forKey: AppKeys.birthdateCompleted) &&
        UserDefaults.standard.bool(forKey: AppKeys.genderCompleted) &&
        hasSelectedStation &&
        AppState.isScheduleComplete(days: selectedDays, times: selectedTimes)
    }

    private func canNavigate(to step: Int) -> Bool {
        if step >= 1 && !AppState.isProfileComplete() { return false }
        if step >= 3 && !AppState.isScheduleComplete(days: selectedDays, times: selectedTimes) { return false }
        return true
    }

    private func finishOnboarding() {
        guard canFinish else { return }
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: AppKeys.firstTime)
        defaults.set(selectedDays, forKey: AppKeys.selectedDays)
        defaults.set(selectedTimes, forKey: AppKeys.selectedTimes)
        defaults.set(info.NAPFA_Date, forKey: AppKeys.napfaDate)
        NotificationCoordinator.scheduleWorkoutNotifications(selectedDays: selectedDays, selectedTimes: selectedTimes)
        AppState.persistWidgetSummary(selectedDays: selectedDays, selectedTimes: selectedTimes)
        showLogin = false
    }
}

private struct RequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        Label(text, systemImage: isMet ? "checkmark.circle.fill" : "circle")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(isMet ? .green : .secondary)
    }
}

#Preview {
    StartingTabView(info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
                    ageFirstTime: .constant(false),
                    ageSheet: .constant(false),
                    Sex: .constant(false),
                    Age: .constant(0),
                    goalSheet: .constant(false),
                    selectedDays: .constant([0]),
                    selectedTimes: .constant([]),
                    schedSheet: .constant(false),
                    showLogin: .constant(true))
}
