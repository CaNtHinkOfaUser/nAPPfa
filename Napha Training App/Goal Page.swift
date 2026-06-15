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
    @State private var validationError: String = ""
    @State private var showValidationAlert = false

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
                            resultsCardOnboarding
                            customGoalsCardOnboarding
                            standardsCard
                                .padding(.top, 8)
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
                                if validateAll() {
                                    saveAll()
                                    dismiss()
                                }
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
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationError)
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
            resultsCardOnboarding
            customGoalsCardOnboarding
            standardsCard
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

    private func validateAll() -> Bool {
        for index in NAPFAStation.allCases.indices {
            if enabledStations[index] {
                let previousGrade = previousGrades[index]
                let targetGrade = targetGrades[index]
                let isPreviousSet = previousGrade != "" && previousGrade != "Not set"
                let isTargetSet = targetGrade != "" && targetGrade != "Not set"

                if !isPreviousSet {
                    validationError = "Please set a previous grade for \(NAPFAStation.allCases[index].rawValue)"
                    showValidationAlert = true
                    return false
                }
                if !isTargetSet {
                    validationError = "Please set a target grade for \(NAPFAStation.allCases[index].rawValue)"
                    showValidationAlert = true
                    return false
                }
            }
        }

        for goal in goalDrafts {
            let trimmedText = goal.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText.isEmpty {
                validationError = "Please fill in the goal text or delete empty goals"
                showValidationAlert = true
                return false
            }
        }

        return true
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

private struct GoalDraftEditor: View {
    @Binding var goal: GoalDraft
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Goal", text: $goal.text, prompt: Text("Example: 45 sit-ups"))
                .textInputAutocapitalization(.sentences)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack {
                Label("Station", systemImage: NAPFAStation(rawValue: goal.station)?.icon ?? "target")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Station", selection: $goal.station) {
                    ForEach(NAPFAStation.allCases) { station in
                        Text(station.rawValue).tag(station.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete goal")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct NAPFAStandardRow: Identifiable {
    let id = UUID()
    let age: String
    let grade: String
    let points: String
    let sitUps: String
    let jump: String
    let reach: String
    let pullUps: String
    let shuttle: String
    let run: String
}

private struct NAPFAStandardsView: View {
    let isMale: Bool
    @State private var selectedAge: String = ""

    private var rows: [NAPFAStandardRow] {
        let allRows = isMale ? Self.maleRows : Self.femaleRows
        guard !selectedAge.isEmpty else { return allRows }
        return allRows.filter { $0.age == selectedAge }
    }

    private var ageGroups: [String] {
        let allRows = isMale ? Self.maleRows : Self.femaleRows
        let ages = allRows.map { $0.age }.filter { !$0.isEmpty }
        return Array(Set(ages)).sorted()
    }

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 14) {
                    Text("NAPFA Standards (Secondary)")
                        .font(.title2.weight(.black))
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(isMale ? "Standards for Males" : "Standards for Females")
                        .font(.headline.weight(.bold))
                        .italic()

                    Picker("Age Group", selection: $selectedAge) {
                        Text("All ages").tag("")
                        ForEach(ageGroups, id: \.self) { age in
                            Text("Age \(age)").tag(age)
                        }
                    }
                    .pickerStyle(.segmented)

                    LazyVStack(spacing: 0) {
                        standardsHeader(screenWidth: geometry.size.width)
                        ForEach(rows) { row in
                            standardsRow(row, screenWidth: geometry.size.width)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(0.35), lineWidth: 1)
                    }
                }
                .padding(18)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isMale ? "Male Standards" : "Female Standards")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func standardsHeader(screenWidth: CGFloat) -> some View {
        let scaleFactor = min(1.0, (screenWidth - 36) / 920)
        return HStack(spacing: 0) {
            tableCell("Age group", width: 72 * scaleFactor, isHeader: true)
            tableCell("Performance grade", width: 112 * scaleFactor, isHeader: true)
            tableCell("Points", width: 58 * scaleFactor, isHeader: true)
            tableCell("Sit-ups in 1 min", width: 92 * scaleFactor, isHeader: true)
            tableCell("Standing Broad Jump", width: 112 * scaleFactor, isHeader: true)
            tableCell("Sit & Reach Distance", width: 104 * scaleFactor, isHeader: true)
            tableCell(isMale ? "Pull-ups / Inclined" : "Inclined Pull-ups in 30 sec", width: 118 * scaleFactor, isHeader: true)
            tableCell("4 x 10m Shuttle Run Time", width: 120 * scaleFactor, isHeader: true)
            tableCell("2.4 km Run-Walk time", width: 130 * scaleFactor, isHeader: true)
        }
    }

    private func standardsRow(_ row: NAPFAStandardRow, screenWidth: CGFloat) -> some View {
        let scaleFactor = min(1.0, (screenWidth - 36) / 920)
        return HStack(spacing: 0) {
            tableCell(row.age, width: 72 * scaleFactor)
            tableCell(row.grade, width: 112 * scaleFactor)
            tableCell(row.points, width: 58 * scaleFactor)
            tableCell(row.sitUps, width: 92 * scaleFactor)
            tableCell(row.jump, width: 112 * scaleFactor)
            tableCell(row.reach, width: 104 * scaleFactor)
            tableCell(row.pullUps, width: 118 * scaleFactor)
            tableCell(row.shuttle, width: 120 * scaleFactor)
            tableCell(row.run, width: 130 * scaleFactor)
        }
    }

    private func tableCell(_ text: String, width: CGFloat, isHeader: Bool = false) -> some View {
        Text(text)
            .font(isHeader ? .caption.weight(.bold) : .caption)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.72)
            .frame(width: width)
            .frame(minHeight: isHeader ? 58 : 28)
            .padding(.horizontal, 4)
            .background(isHeader ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground))
            .border(Color.primary.opacity(0.35), width: 0.5)
    }

    private static func row(_ age: String, _ grade: String, _ points: String, _ sitUps: String, _ jump: String, _ reach: String, _ pullUps: String, _ shuttle: String, _ run: String) -> NAPFAStandardRow {
        NAPFAStandardRow(age: age, grade: grade, points: points, sitUps: sitUps, jump: jump, reach: reach, pullUps: pullUps, shuttle: shuttle, run: run)
    }

    private static let femaleRows: [NAPFAStandardRow] = [
        row("12", "A", "5", ">29", ">167cm", ">39cm", ">15", "<11.5 sec", "<14:41"),
        row("", "B", "4", "25-29", "159-167", "37-39", "13-15", "11.5-11.9", "14:41-15:40"),
        row("", "C", "3", "21-24", "150-158", "34-36", "10-12", "12.0-12.3", "15:41-16:40"),
        row("", "D", "2", "17-20", "141-149", "30-33", "7-9", "12.4-12.7", "16:41-17:40"),
        row("", "E", "1", "13-16", "132-140", "25-29", "3-6", "12.8-13.2", "17:41-18:40"),
        row("13", "A", "5", ">30", ">170cm", ">41cm", ">16", "<11.3 sec", "<14:31"),
        row("", "B", "4", "26-30", "162-170", "39-41", "13-16", "11.3-11.7", "14:31-15:30"),
        row("", "C", "3", "22-25", "153-161", "36-38", "10-12", "11.8-12.2", "15:31-16:30"),
        row("", "D", "2", "18-21", "144-152", "32-35", "7-9", "12.3-12.7", "16:31-17:30"),
        row("", "E", "1", "14-17", "135-143", "27-31", "3-6", "12.8-13.2", "17:31-18:30"),
        row("14", "A", "5", ">30", ">177cm", ">43cm", ">16", "<11.5 sec", "<14:21"),
        row("", "B", "4", "28-30", "169-177", "41-43", "14-16", "11.5-11.8", "14:21-15:20"),
        row("", "C", "3", "24-27", "160-168", "38-40", "10-13", "11.9-12.2", "15:21-16:20"),
        row("", "D", "2", "20-23", "151-159", "34-37", "7-9", "12.3-12.6", "16:21-17:20"),
        row("", "E", "1", "16-19", "142-150", "29-33", "3-6", "12.7-13.0", "17:21-18:20"),
        row("15", "A", "5", ">30", ">182cm", ">45cm", ">16", "<11.3 sec", "<14:11"),
        row("", "B", "4", "29-30", "174-182", "43-45", "14-16", "11.3-11.6", "14:11-15:10"),
        row("", "C", "3", "25-28", "165-173", "39-42", "10-13", "11.7-12.0", "15:11-16:10"),
        row("", "D", "2", "21-24", "156-164", "35-38", "7-9", "12.1-12.4", "16:11-17:10"),
        row("", "E", "1", "17-20", "147-155", "30-34", "3-6", "12.5-12.8", "17:11-18:10"),
        row("16", "A", "5", ">30", ">186cm", ">46cm", ">17", "<11.3 sec", "<14:01"),
        row("", "B", "4", "29-30", "178-186", "44-46", "14-17", "11.3-11.5", "14:01-15:00"),
        row("", "C", "3", "26-28", "169-177", "40-43", "11-13", "11.6-11.8", "15:01-16:00"),
        row("", "D", "2", "22-25", "160-168", "36-39", "7-10", "11.9-12.2", "16:01-17:00"),
        row("", "E", "1", "18-21", "151-159", "31-35", "3-6", "12.3-12.6", "17:01-17:50"),
        row("17", "A", "5", ">30", ">189cm", ">46cm", ">17", "<11.3 sec", "<14:01"),
        row("", "B", "4", "29-30", "181-189", "44-46", "14-17", "11.3-11.5", "14:01-14:50"),
        row("", "C", "3", "27-28", "172-180", "40-43", "11-13", "11.6-11.8", "14:51-15:50"),
        row("", "D", "2", "23-26", "163-171", "36-39", "7-10", "11.9-12.1", "15:51-16:40"),
        row("", "E", "1", "19-22", "154-162", "32-35", "3-6", "12.2-12.5", "16:41-17:30"),
        row("18", "A", "5", ">30", ">192cm", ">46cm", ">17", "<11.3 sec", "<14:01"),
        row("", "B", "4", "29-30", "183-192", "44-46", "15-17", "11.3-11.5", "14:01-14:50"),
        row("", "C", "3", "27-28", "174-182", "40-43", "11-14", "11.6-11.8", "14:51-15:40"),
        row("", "D", "2", "24-26", "165-173", "36-39", "8-10", "11.9-12.1", "15:41-16:30"),
        row("", "E", "1", "20-23", "156-164", "32-35", "4-7", "12.2-12.4", "16:31-17:20"),
        row("19", "A", "5", ">30", ">195cm", ">45cm", ">17", "<11.3 sec", "<14:21"),
        row("", "B", "4", "29-30", "185-195", "43-45", "15-17", "11.3-11.5", "14:21-14:50"),
        row("", "C", "3", "27-28", "174-184", "39-42", "11-14", "11.6-11.8", "14:51-15:30"),
        row("", "D", "2", "24-26", "165-173", "36-38", "8-10", "11.9-12.1", "15:31-16:20"),
        row("", "E", "1", "21-23", "156-164", "32-35", "5-7", "12.2-12.4", "16:21-17:10")
    ]

    private static let maleRows: [NAPFAStandardRow] = [
        row("12", "A", "5", ">41", ">202cm", ">39cm", ">24", "<10.4 sec", "<12:01"),
        row("", "B", "4", "36-41", "189-202", "36-39", "21-24", "10.4-10.9", "12:01-13:10"),
        row("", "C", "3", "32-35", "176-188", "32-35", "16-20", "11.0-11.3", "13:11-14:20"),
        row("", "D", "2", "27-31", "163-175", "28-31", "11-15", "11.4-11.7", "14:21-15:30"),
        row("", "E", "1", "22-26", "150-162", "23-27", "5-10", "11.8-12.2", "15:31-16:50"),
        row("13", "A", "5", ">42", ">214cm", ">41cm", ">25", "<10.3 sec", "<11:31"),
        row("", "B", "4", "38-42", "202-214", "38-41", "22-25", "10.3-10.7", "11:31-12:30"),
        row("", "C", "3", "34-37", "189-201", "34-37", "17-21", "10.8-11.1", "12:31-13:40"),
        row("", "D", "2", "29-33", "176-188", "30-33", "12-16", "11.2-11.5", "13:41-14:50"),
        row("", "E", "1", "25-28", "164-175", "25-29", "7-11", "11.6-11.9", "14:51-16:00"),
        row("14", "A", "5", ">42", ">225cm", ">43cm", ">26", "<10.2 sec", "<11:01"),
        row("", "B", "4", "40-42", "216-225", "40-43", "23-26", "10.2-10.4", "11:01-12:00"),
        row("", "C", "3", "37-39", "206-215", "36-39", "18-22", "10.5-10.8", "12:01-13:00"),
        row("", "D", "2", "33-36", "196-205", "32-35", "13-17", "10.9-11.2", "13:01-14:10"),
        row("", "E", "1", "29-32", "186-195", "27-31", "8-12", "11.3-11.6", "14:11-15:20"),
        row("15", "A", "5", ">42", ">237cm", ">45cm", ">7", "<10.2 sec", "<10:41"),
        row("", "B", "4", "40-42", "228-237", "42-45", "6-7", "10.2-10.3", "10:41-11:40"),
        row("", "C", "3", "37-39", "218-227", "38-41", "5", "10.4-10.5", "11:41-12:40"),
        row("", "D", "2", "34-36", "208-217", "34-37", "3-4", "10.6-10.9", "12:41-13:40"),
        row("", "E", "1", "30-33", "198-207", "29-33", "1-2", "11.0-11.3", "13:41-14:40"),
        row("16", "A", "5", ">42", ">245cm", ">47cm", ">8", "<10.2 sec", "<10:31"),
        row("", "B", "4", "40-42", "236-245", "44-47", "7-8", "10.2-10.3", "10:31-11:30"),
        row("", "C", "3", "37-39", "226-235", "40-43", "5-6", "10.4-10.5", "11:31-12:20"),
        row("", "D", "2", "34-36", "216-225", "36-39", "3-4", "10.6-10.7", "12:21-13:20"),
        row("", "E", "1", "31-33", "206-215", "31-35", "1-2", "10.8-11.1", "13:21-14:10"),
        row("17", "A", "5", ">42", ">249cm", ">48cm", ">9", "<10.2 sec", "<10:21"),
        row("", "B", "4", "40-42", "240-249", "45-48", "8-9", "10.2-10.3", "10:21-11:10"),
        row("", "C", "3", "37-39", "230-239", "41-44", "6-7", "10.4-10.5", "11:11-12:00"),
        row("", "D", "2", "34-36", "220-229", "37-40", "4-5", "10.6-10.7", "12:01-12:50"),
        row("", "E", "1", "31-33", "210-219", "32-36", "2-3", "10.8-10.9", "12:51-13:40"),
        row("18", "A", "5", ">42", ">251cm", ">48cm", ">10", "<10.2 sec", "<10:21"),
        row("", "B", "4", "40-42", "242-251", "45-48", "9-10", "10.2-10.3", "10:21-11:10"),
        row("", "C", "3", "37-39", "232-241", "41-44", "7-8", "10.4-10.5", "11:11-11:50"),
        row("", "D", "2", "34-36", "222-231", "37-40", "5-6", "10.6-10.7", "11:51-12:40"),
        row("", "E", "1", "31-33", "212-221", "32-36", "3-4", "10.8-10.9", "12:41-13:30"),
        row("19", "A", "5", ">42", ">251cm", ">48cm", ">10", "<10.2 sec", "<10:21"),
        row("", "B", "4", "40-42", "242-251", "45-48", "9-10", "10.2-10.3", "10:21-11:00"),
        row("", "C", "3", "37-39", "232-241", "41-44", "7-8", "10.4-10.5", "11:01-11:40"),
        row("", "D", "2", "34-36", "222-231", "37-40", "5-6", "10.6-10.7", "11:41-12:30"),
        row("", "E", "1", "31-33", "212-221", "32-36", "3-4", "10.8-10.9", "12:31-13:20")
    ]
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
