import SwiftUI

struct Goal_Page: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var start: Bool
    @Binding var info: data
    @Binding var Sex: Bool
    @Binding var Age: Int
    @Binding var GoalSheet: Bool

    @State private var previousGrades = Array(repeating: "", count: NAPFAStation.allCases.count)
    @State private var targetGrades = Array(repeating: "", count: NAPFAStation.allCases.count)
    @State private var enabledStations = Array(repeating: false, count: NAPFAStation.allCases.count)
    @State private var goalDrafts: [GoalDraft] = []
    @State private var showClearAlert = false
    @State private var showResultHelp = false
    @State private var showAutoCalcHelp = false
    @State private var showDeleteHelp = false
    @State private var showAutoCalc = false

    private let gradeOptions = ["Not set", "A", "B", "C", "D", "E", "F", "NA"]

    var body: some View {
        Group {
            if start {
                NavigationStack {
                    OnboardingStepContainer(subtitle: "Goals") {
                        goalFormList
                    }
                }
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            standardsCard
                                .padding(.top, 8)
                            resultsCardOnboarding
                            customGoalsCardOnboarding
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 28)
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("Goal Setting")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                saveAll()
                                dismiss()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showResultHelp) {
                HelpTipSheet(
                    title: "Previous and target results",
                    message: "Previous results tell the app your starting point. Target results tell it how hard to train each station. Enable a station, then pick grades from the menus."
                )
            }
            .sheet(isPresented: $showAutoCalcHelp) {
                HelpTipSheet(
                    title: "Auto calculation",
                    message: "Auto calculation converts a raw result into a grade using your saved age and sex. Use it when you know your score but not the letter grade."
                )
            }
            .sheet(isPresented: $showDeleteHelp) {
                HelpTipSheet(
                    title: "Delete goals",
                    message: "Swipe left on a saved goal to delete it, or use Clear All to remove every custom goal at once."
                )
            }
            .alert("Clear all goals?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) {
                    goalDrafts = []
                    saveAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your custom goal list.")
            }
            .onAppear(perform: loadData)
            .onChange(of: previousGrades) {
                saveAll()
            }
            .onChange(of: targetGrades) {
                saveAll()
            }
            .onChange(of: enabledStations) {
                saveAll()
            }
            .onChange(of: goalDrafts) {
                saveAll()
            }
            .sheet(isPresented: $showAutoCalc) {
                AutoCalcView(info: $info)
            }
    }

    private var goalFormList: some View {
        VStack(spacing: 16) {
            standardsCard
            resultsCardOnboarding
            customGoalsCardOnboarding
        }
    }

    private var standardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standards")
                .font(.title3.weight(.bold))

            NavigationLink {
                NAPFAStandardsView(isMale: info.Gender)
            } label: {
                Label(info.Gender ? "Male standards table" : "Female standards table", systemImage: "tablecells")
            }

            Button {
                showAutoCalc = true
            } label: {
                HStack {
                    Label("Auto Calculation", systemImage: "function")
                    Spacer()
                    Button {
                        showAutoCalcHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var resultsCardOnboarding: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Previous and Target Results")
                    .font(.title3.weight(.bold))
                Spacer()
                Button { showResultHelp = true } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
            }
            ForEach(NAPFAStation.allCases.indices, id: \.self) { index in
                stationGoalRow(index)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var customGoalsCardOnboarding: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Goals")
                    .font(.title3.weight(.bold))
                Spacer()
                Button { showDeleteHelp = true } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
            }
            if goalDrafts.isEmpty {
                Text("Add a goal below to track it on Home.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach($goalDrafts) { $goal in
                    GoalDraftEditor(goal: $goal) {
                        if let index = goalDrafts.firstIndex(where: { $0.id == goal.id }) {
                            goalDrafts.remove(at: index)
                            saveAll()
                        }
                    }
                }
            }

            Button {
                goalDrafts.append(GoalDraft())
                saveAll()
            } label: {
                Label("Add Goal", systemImage: "plus.circle.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var standardsSection: some View {
        Section {
            Link(destination: URL(string: "https://www.napfatest.com/napfa-standards-2026")!) {
                Label("Standards calculator", systemImage: "safari")
            }

            Link(destination: URL(string: "https://www.stgabrielssec.moe.edu.sg/files/Sports%20CCA/NAPFA%20Standards.pdf")!) {
                Label("Standards PDF reference", systemImage: "doc.text")
            }

            NavigationLink {
                AutoCalcView(info: $info)
            } label: {
                HStack {
                    Label("Auto Calculation", systemImage: "function")
                    Spacer()
                    Button {
                        showAutoCalcHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Explain auto calculation")
                }
            }
        } header: {
            Text("Standards")
        }
    }

    private var resultSection: some View {
        Section {
            ForEach(NAPFAStation.allCases.indices, id: \.self) { index in
                stationGoalRow(index)
            }
        } header: {
            HStack {
                Text("Previous and Target Results")
                Spacer()
                Button {
                    showResultHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Explain previous and target results")
            }
        }
    }

    private var customGoalsSection: some View {
        Section {
            if goalDrafts.isEmpty {
                ContentUnavailableView("No custom goals", systemImage: "target")
                    .frame(maxWidth: .infinity)
            }

            ForEach($goalDrafts) { $goal in
                GoalDraftEditor(goal: $goal) {
                    if let index = goalDrafts.firstIndex(where: { $0.id == goal.id }) {
                        goalDrafts.remove(at: index)
                        saveAll()
                    }
                }
                .padding(.vertical, 6)
            }
            .onDelete(perform: deleteGoals)

            Button {
                goalDrafts.append(GoalDraft())
                saveAll()
            } label: {
                Label("Add Goal", systemImage: "plus.circle.fill")
            }

            if !goalDrafts.isEmpty {
                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
            }
        } header: {
            HStack {
                Text("My Goals")
                Spacer()
                Button {
                    showDeleteHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Explain goal deletion")
            }
        }
    }

    private func stationGoalRow(_ index: Int) -> some View {
        let station = NAPFAStation.allCases[index]

        return VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: bindingForEnabled(index)) {
                HStack(spacing: 12) {
                    Image(systemName: station.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(station.rawValue)
                            .font(.body.weight(.semibold))
                        Text(station.shortTip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if enabledStations[index] {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Previous")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Picker("Previous", selection: bindingForGrade($previousGrades, index)) {
                            ForEach(gradeOptions, id: \.self) { grade in
                                Text(grade).tag(grade)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Picker("Target", selection: bindingForGrade($targetGrades, index)) {
                            ForEach(gradeOptions, id: \.self) { grade in
                                Text(grade).tag(grade)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func bindingForEnabled(_ index: Int) -> Binding<Bool> {
        Binding {
            enabledStations.indices.contains(index) ? enabledStations[index] : false
        } set: { newValue in
            guard enabledStations.indices.contains(index) else { return }
            enabledStations[index] = newValue
            if !newValue {
                previousGrades[index] = ""
                targetGrades[index] = ""
            }
        }
    }

    private func bindingForGrade(_ grades: Binding<[String]>, _ index: Int) -> Binding<String> {
        Binding {
            guard grades.wrappedValue.indices.contains(index) else { return "Not set" }
            return displayGrade(grades.wrappedValue[index])
        } set: { newValue in
            guard grades.wrappedValue.indices.contains(index) else { return }
            grades.wrappedValue[index] = storedGrade(newValue)
        }
    }

    private func loadData() {
        let defaults = UserDefaults.standard
        previousGrades = normalizeGrades(defaults.object(forKey: AppKeys.previousGrades) as? [String] ?? info.prev)
        targetGrades = normalizeGrades(defaults.object(forKey: AppKeys.targetGrades) as? [String] ?? info.targ)

        let storedEnabled = defaults.object(forKey: AppKeys.enabledGrades) as? [Bool]
        enabledStations = normalizeEnabled(storedEnabled)

        for index in NAPFAStation.allCases.indices {
            if !previousGrades[index].isEmpty || !targetGrades[index].isEmpty {
                enabledStations[index] = true
            }
        }

        let savedGoals = defaults.object(forKey: AppKeys.goals) as? [[String]] ?? info.Goals
        goalDrafts = GoalDraft.fromSaved(savedGoals)
        saveAll()
    }

    private func saveAll() {
        previousGrades = normalizeGrades(previousGrades)
        targetGrades = normalizeGrades(targetGrades)
        enabledStations = normalizeEnabled(enabledStations)

        let savedGoals = GoalDraft.encode(goalDrafts)
        info.prev = previousGrades
        info.targ = targetGrades
        info.Goals = savedGoals

        let defaults = UserDefaults.standard
        defaults.set(previousGrades, forKey: AppKeys.previousGrades)
        defaults.set(targetGrades, forKey: AppKeys.targetGrades)
        defaults.set(enabledStations, forKey: AppKeys.enabledGrades)
        defaults.set(savedGoals, forKey: AppKeys.goals)

        let selectedDays = defaults.object(forKey: AppKeys.selectedDays) as? [Int] ?? []
        let selectedTimes = defaults.object(forKey: AppKeys.selectedTimes) as? [Date] ?? []
        AppState.persistWidgetSummary(selectedDays: selectedDays, selectedTimes: selectedTimes)
    }

    private func deleteGoals(at offsets: IndexSet) {
        goalDrafts.remove(atOffsets: offsets)
        saveAll()
    }

    private func normalizeGrades(_ values: [String]) -> [String] {
        var copy = values
        if copy.count < NAPFAStation.allCases.count {
            copy.append(contentsOf: Array(repeating: "", count: NAPFAStation.allCases.count - copy.count))
        }
        return Array(copy.prefix(NAPFAStation.allCases.count)).map { storedGrade(displayGrade($0)) }
    }

    private func normalizeEnabled(_ values: [Bool]?) -> [Bool] {
        var copy = values ?? Array(repeating: false, count: NAPFAStation.allCases.count)
        if copy.count < NAPFAStation.allCases.count {
            copy.append(contentsOf: Array(repeating: false, count: NAPFAStation.allCases.count - copy.count))
        }
        return Array(copy.prefix(NAPFAStation.allCases.count))
    }

    private func displayGrade(_ value: String) -> String {
        gradeOptions.contains(value) ? value : "Not set"
    }

    private func storedGrade(_ value: String) -> String {
        value == "Not set" || value == "false" ? "" : value
    }
}

#Preview {
    Goal_Page(
        start: .constant(false),
        info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
        Sex: .constant(true),
        Age: .constant(0),
        GoalSheet: .constant(false)
    )
}
