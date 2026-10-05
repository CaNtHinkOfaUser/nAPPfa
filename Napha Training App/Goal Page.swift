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
	@State private var showDeleteHelp = false
	@State private var validationError: String = ""
	@State private var showValidationAlert = false
	
	//Snapshot captured on appear; restored by Cancel to discard in-flight edits.
	@State private var snapshotPrev: [String] = []
	@State private var snapshotTarg: [String] = []
	@State private var snapshotEnabled: [Bool] = []
	@State private var snapshotGoals: [[String]] = []
	
	private let gradeOptions = ["Not set", "A", "B", "C", "D", "E", "F", "NA"]
	
	private func stationDisplayName(for station: NAPFAStation) -> String {
		station.displayName(age: Age, sex: Sex)
	}
	
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
								revertChanges()
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
				message: """
				Previous results tell the app your starting point. Target results tell it how hard to train each station. Enable a station, then pick grades from the menus.
				
				Haven't taken NAPFA yet, or not sure of your grade? Pick NA. NA is treated as an F until you do a baseline test in the Workout tab, which replaces it with your real result.
				
				Pull-ups: NAPFA switches boys aged 15 and above from inclined pull-ups to full pull-ups. Girls do inclined pull-ups at every age.
				"""
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
				saveIfOnboarding()
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
			saveIfOnboarding()
		}
		.onChange(of: targetGrades) {
			saveIfOnboarding()
		}
		.onChange(of: enabledStations) { oldValue, newValue in
			// Switching a station off clears its grades.
			for index in newValue.indices where oldValue.indices.contains(index) && oldValue[index] && !newValue[index] {
				previousGrades[index] = ""
				targetGrades[index] = ""
			}
			saveIfOnboarding()
		}
		.onChange(of: goalDrafts) {
			saveIfOnboarding()
		}
	}
	
	private var goalFormList: some View {
		VStack(spacing: 16) {
			resultsCardOnboarding
			customGoalsCardOnboarding
		}
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
		.background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
		.popUpCard()
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
					GoalDraftEditor(goal: $goal, age: Age, sex: Sex) {
						if let index = goalDrafts.firstIndex(where: { $0.id == goal.id }) {
							goalDrafts.remove(at: index)
							saveIfOnboarding()
						}
					}
				}
			}
			
			Button {
				goalDrafts.append(GoalDraft())
				saveIfOnboarding()
			} label: {
				Label("Add Goal", systemImage: "plus.circle.fill")
			}
		}
		.padding(18)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
		.popUpCard()
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
				GoalDraftEditor(goal: $goal, age: Age, sex: Sex) {
					if let index = goalDrafts.firstIndex(where: { $0.id == goal.id }) {
						goalDrafts.remove(at: index)
						saveIfOnboarding()
					}
				}
				.padding(.vertical, 6)
			}
			.onDelete(perform: deleteGoals)
			
			Button {
				goalDrafts.append(GoalDraft())
				saveIfOnboarding()
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
			HStack(spacing: 12) {
				Image(systemName: station.icon)
					.font(.system(size: 30, weight: .semibold))
					.frame(width: 42, height: 42)
					.foregroundStyle(.blue)
					
				VStack(alignment: .leading, spacing: 2) {
					Text(stationDisplayName(for: station))
						.font(.body.weight(.semibold))
					Text(station.shortTip)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				
				Spacer(minLength: 8)
				
				Toggle(stationDisplayName(for: station), isOn: $enabledStations[index])
					.toggleStyle(TapSwitchToggleStyle())
			}
			
			if enabledStations[index] {
				HStack(spacing: 12) {
					VStack(alignment: .leading, spacing: 4) {
						Text("Previous")
							.font(.caption.weight(.semibold))
							.foregroundStyle(.secondary)
						Picker("Previous", selection: bindingForGrade($previousGrades, index, isPrevious: true)) {
							ForEach(gradeOptions, id: \.self) { grade in
								Text(grade).tag(grade)
							}
						}
						.pickerStyle(.menu)
						.frame(maxWidth: .infinity)
						.padding(.horizontal, 10)
						.padding(.vertical, 8)
						.background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
					}
					.frame(maxWidth: .infinity)
					
					VStack(alignment: .leading, spacing: 4) {
						Text("Target")
							.font(.caption.weight(.semibold))
							.foregroundStyle(.secondary)
						Picker("Target", selection: bindingForGrade($targetGrades, index, isPrevious: false)) {
							ForEach(targetGradeOptions(for: previousGrades[index]), id: \.self) { grade in
								Text(grade).tag(grade)
							}
						}
						.pickerStyle(.menu)
						.frame(maxWidth: .infinity)
						.padding(.horizontal, 10)
						.padding(.vertical, 8)
						.background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
					}
					.frame(maxWidth: .infinity)
				}
			}
		}
		.padding(.vertical, 6)
	}
	
	private func bindingForGrade(_ grades: Binding<[String]>, _ index: Int, isPrevious: Bool) -> Binding<String> {
		Binding {
			guard grades.wrappedValue.indices.contains(index) else { return "Not set" }
			return displayGrade(grades.wrappedValue[index])
		} set: { newValue in
			guard grades.wrappedValue.indices.contains(index) else { return }
			grades.wrappedValue[index] = storedGrade(newValue)
			if isPrevious,
			   targetGrades.indices.contains(index),
			   !targetGradeOptions(for: grades.wrappedValue[index]).contains(displayGrade(targetGrades[index])) {
				targetGrades[index] = storedGrade(displayGrade(grades.wrappedValue[index]))
			}
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
		
		// Capture the persisted state so Cancel can fully restore it.
		snapshotPrev = previousGrades
		snapshotTarg = targetGrades
		snapshotEnabled = enabledStations
		snapshotGoals = GoalDraft.encode(goalDrafts)
		
		saveIfOnboarding()
	}
	
	/// Restore on-screen state and UserDefaults to the snapshot captured on appear.
	private func revertChanges() {
		previousGrades = normalizeGrades(snapshotPrev)
		targetGrades = normalizeGrades(snapshotTarg)
		enabledStations = normalizeEnabled(snapshotEnabled)
		goalDrafts = GoalDraft.fromSaved(snapshotGoals)
		
		info.prev = previousGrades
		info.targ = targetGrades
		info.Goals = snapshotGoals
		
		let defaults = UserDefaults.standard
		defaults.set(previousGrades, forKey: AppKeys.previousGrades)
		defaults.set(targetGrades, forKey: AppKeys.targetGrades)
		defaults.set(enabledStations, forKey: AppKeys.enabledGrades)
		defaults.set(snapshotGoals, forKey: AppKeys.goals)
		
		let selectedDays = defaults.object(forKey: AppKeys.selectedDays) as? [Int] ?? []
		let selectedTimes = defaults.object(forKey: AppKeys.selectedTimes) as? [Date] ?? []
		AppState.persistWidgetSummary(selectedDays: selectedDays, selectedTimes: selectedTimes)
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
		WorkoutPlanner.updateBaselineDates(previous: previousGrades, changedFrom: snapshotPrev)
		if NAPFAStation.inclinedPullUps.isFullPullUp(age: Age, isMale: Sex) {
			// Grades were saved while full pull-ups apply, so they no longer describe inclined pull-ups.
			defaults.set(true, forKey: AppKeys.pullUpGradesReviewed)
		}
		
		let selectedDays = defaults.object(forKey: AppKeys.selectedDays) as? [Int] ?? []
		let selectedTimes = defaults.object(forKey: AppKeys.selectedTimes) as? [Date] ?? []
		AppState.persistWidgetSummary(selectedDays: selectedDays, selectedTimes: selectedTimes)
	}
	
	private func deleteGoals(at offsets: IndexSet) {
		goalDrafts.remove(atOffsets: offsets)
		saveIfOnboarding()
	}
	
	private func validateAll() -> Bool {
		for index in NAPFAStation.allCases.indices {
			if enabledStations[index] {
				let previousGrade = previousGrades[index]
				let targetGrade = targetGrades[index]
				let isPreviousSet = previousGrade != "" && previousGrade != "Not set"
				let isTargetSet = targetGrade != "" && targetGrade != "Not set"
				
				if !isPreviousSet {
					validationError = "Please set a previous grade for \(stationDisplayName(for: NAPFAStation.allCases[index]))"
					showValidationAlert = true
					return false
				}
				if !isTargetSet {
					validationError = "Please set a target grade for \(stationDisplayName(for: NAPFAStation.allCases[index]))"
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
	
	private func saveIfOnboarding() {
		guard start else { return }
		saveAll()
	}
	
	private func targetGradeOptions(for previousGrade: String) -> [String] {
		let previous = displayGrade(previousGrade)
		guard previous != "Not set" else { return gradeOptions }
		return gradeOptions.filter { grade in
			grade == "Not set" || gradeRank(grade) >= gradeRank(previous)
		}
	}
	
	private func gradeRank(_ grade: String) -> Int {
		switch grade {
		case "A": return 7
		case "B": return 6
		case "C": return 5
		case "D": return 4
		case "E": return 3
		case "F": return 2
		case "NA": return 1
		default: return 0
		}
	}
}

/// A switch drawn in SwiftUI that flips on a normal tap. The system switch on this page
/// only flipped on a press-and-hold (a quick tap turned it on and straight back off),
/// while buttons here respond normally, so the switch is a button underneath.
private struct TapSwitchToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		Button {
			withAnimation(.snappy(duration: 0.2)) {
				configuration.isOn.toggle()
			}
		} label: {
			Capsule()
				.fill(configuration.isOn ? Color.green : Color(.systemFill))
				.frame(width: 51, height: 31)
				.overlay(alignment: configuration.isOn ? .trailing : .leading) {
					Circle()
						.fill(.white)
						.shadow(color: .black.opacity(0.2), radius: 2, y: 1)
						.padding(2)
				}
		}
		.buttonStyle(.plain)
		.accessibilityRepresentation {
			Toggle(isOn: configuration.$isOn) {
				configuration.label
			}
		}
	}
}

private struct GoalDraftEditor: View {
	@Binding var goal: GoalDraft
	let age: Int
	let sex: Bool
	var onDelete: () -> Void
	
	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			TextField("Goal", text: $goal.text, prompt: Text("Example: 45 sit-ups"))
				.textInputAutocapitalization(.sentences)
				.padding(12)
				.background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
			
			HStack {
				Label("Station", systemImage: NAPFAStation(rawValue: goal.station)?.icon ?? "target")
					.font(.caption.weight(.bold))
					.foregroundStyle(.secondary)
				
				Spacer()
				
				Picker("Station", selection: $goal.station) {
					ForEach(NAPFAStation.allCases) { station in
						Text(station.displayName(age: age, sex: sex)).tag(station.rawValue)
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

#Preview {
	Goal_Page(
		start: .constant(false),
		info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
		Sex: .constant(true),
		Age: .constant(0),
		GoalSheet: .constant(false)
	)
}
