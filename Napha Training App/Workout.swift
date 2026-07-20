//
//  Workout.swift
//  Napha Training App
//

import SwiftUI

final class WorkoutSessionState: ObservableObject {
	@Published var locksTabBar = false
}

struct Workout: View {
	@EnvironmentObject private var workoutSession: WorkoutSessionState
	@Binding var info: data
	
	@State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	@State private var selectedStation: NAPFAStation?
	@State private var sessionSteps: [WorkoutStep] = []
	@State private var currentIndex = 0
	@State private var isWorkingOut = false
	@State private var isBreak = false
	@State private var breakRemaining = 45
	@State private var breakTotal = 45
	@State private var breakSoundPlayed = false
	@State private var alarmSoundLoopCount = 0
	@State private var elapsed = 0
	@State private var sessionCompleted = false
	@State private var completionRecorded = false
	@State private var isExtraSet = false
	@State private var showExtraSetPrompt = false
	@State private var intensityLabel = ""
	
	private var currentStep: WorkoutStep? {
		sessionSteps.indices.contains(currentIndex) ? sessionSteps[currentIndex] : nil
	}
	
	private var breakProgress: Double {
		guard breakTotal > 0 else { return 0 }
		return Double(max(0, breakTotal - breakRemaining)) / Double(breakTotal)
	}
	
	var body: some View {
		NavigationStack {
			Group {
				if AppState.isDailyWorkoutComplete(info: info), !isExtraSet, !isWorkingOut, !sessionCompleted {
					alreadyDoneView
				} else if sessionCompleted {
					resultsView
				} else if isWorkingOut {
					sessionView
				} else {
					stationPicker
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color(.systemGroupedBackground))
			.navigationTitle("Workout")
			.navigationBarTitleDisplayMode(.inline)
			.onReceive(timer) { _ in
				guard isWorkingOut else { return }
				elapsed += 1
				
				if isBreak, breakRemaining > 0 {
					breakRemaining -= 1
				}
				
				if isBreak, breakRemaining == 0 {
					if alarmSoundLoopCount % 3 == 0 {
						SoundManager.instance.playSound()
					}
					alarmSoundLoopCount += 1
				}
			}
			.onChange(of: isWorkingOut) { _, working in
				workoutSession.locksTabBar = working || sessionCompleted
			}
			.onChange(of: sessionCompleted) { _, completed in
				workoutSession.locksTabBar = isWorkingOut || completed
			}
			.onDisappear {
				if !isWorkingOut && !sessionCompleted {
					workoutSession.locksTabBar = false
				}
			}
		}
	}
	
	@ViewBuilder
	private var stationPicker: some View {
		let allEnabled = AppState.enabledGoalStations(from: info)
		let completed = AppState.completedStationsForToday()
		let stations = allEnabled.filter { !completed.contains($0.rawValue) }
		
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				Text("Choose a station")
					.font(.largeTitle.weight(.bold))
					.padding(.top, 8)
				
				Text("Sets adapt to your previous and target grades.")
					.font(.subheadline)
					.foregroundStyle(.secondary)
				
				if stations.isEmpty {
					ContentUnavailableView("No stations selected", systemImage: "target", description: Text("Tick stations in Goals to show them here."))
						.frame(maxWidth: .infinity, minHeight: 280)
				} else {
					ForEach(stations) { station in
						stationCard(station)
					}
				}
			}
			.padding(.horizontal, 18)
			.padding(.bottom, workoutSession.locksTabBar ? 24 : 110)
		}
	}
	
	private func stationCard(_ station: NAPFAStation) -> some View {
		let index = NAPFAStation.allCases.firstIndex(of: station) ?? 0
		let prev = WorkoutPlanner.grade(at: index, in: info.prev)
		let targ = WorkoutPlanner.grade(at: index, in: info.targ)
		let level = WorkoutPlanner.intensity(previous: prev, target: targ)
		
		return VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 12) {
				Image(systemName: station.icon)
					.font(.system(size: 36, weight: .semibold))
					.foregroundStyle(.blue)
					.frame(width: 48)
				
				VStack(alignment: .leading, spacing: 4) {
					Text(station.displayName(age: info.Age, sex: info.Gender))
						.font(.headline)
					Text("\(level.rawValue) · \(display(prev)) → \(display(targ))")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.secondary)
				}
				Spacer()
			}
			
			Button {
				startWorkout(station)
			} label: {
				Label("Start", systemImage: "play.fill")
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.borderedProminent)
		}
		.padding(16)
		.background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
		.popUpCard()
	}
	
	private var sessionView: some View {
		VStack(spacing: 16) {
			if isBreak {
				breakView
			} else if let currentStep {
				exerciseView(currentStep)
			}
		}
		.padding(.horizontal, 18)
	}
	
	private func exerciseView(_ step: WorkoutStep) -> some View {
		VStack(spacing: 14) {
			HStack {
				Text(intensityLabel)
					.font(.caption.weight(.bold))
					.padding(.horizontal, 10)
					.padding(.vertical, 4)
					.background(.blue.opacity(0.12), in: Capsule())
				Spacer()
				Text("Set \(currentIndex + 1) of \(sessionSteps.count)")
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.secondary)
			}
			
			Text("\(currentIndex + 1)")
				.font(.system(size: currentIndex == 0 ? 80 : 56, weight: .black, design: .rounded))
				.contentTransition(.numericText())
			
			Image(systemName: step.station.icon)
				.font(.system(size: 72, weight: .semibold))
				.foregroundStyle(.blue)
				.symbolEffect(.pulse, options: .repeating.speed(0.35))
			
			Text(step.name)
				.font(.title.weight(.bold))
				.multilineTextAlignment(.center)
			
			Text(step.detail)
				.font(.body.weight(.medium))
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 8)
			
			Spacer(minLength: 8)
			
			HStack(spacing: 12) {
				Button {
					startBreak()
				} label: {
					Label("45s Rest", systemImage: "timer")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
				.disabled(currentIndex >= sessionSteps.count - 1)
				
				Button {
					moveToNextExercise()
				} label: {
					Label(currentIndex >= sessionSteps.count - 1 ? "Finish" : "Next Set", systemImage: "forward.fill")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
			}
			.padding(.bottom, 16)
		}
	}
	
	private var breakView: some View {
		VStack(spacing: 20) {
			Spacer()
			
			Text("Rest")
				.font(.title2.weight(.bold))
				.foregroundStyle(.secondary)
			
			ZStack {
				Circle()
					.stroke(Color(.tertiarySystemFill), lineWidth: 14)
				Circle()
					.trim(from: 0, to: breakProgress)
					.stroke(
						breakRemaining == 0 ? Color.green : Color.blue,
						style: StrokeStyle(lineWidth: 14, lineCap: .round)
					)
					.rotationEffect(.degrees(-90))
					.animation(.linear(duration: 1), value: breakRemaining)
				
				VStack(spacing: 4) {
					Text(timeString(breakRemaining))
						.font(.system(size: 48, weight: .black, design: .rounded))
						.monospacedDigit()
						.contentTransition(.numericText())
					Text("seconds left")
						.font(.caption.weight(.semibold))
						.foregroundStyle(.secondary)
				}
			}
			.frame(width: 200, height: 200)
			
			Button {
				stopBreak()
			} label: {
				Label(breakRemaining == 0 ? "Continue" : "Skip Rest", systemImage: "forward.fill")
					.frame(maxWidth: .infinity)
					.padding(.vertical, 14)
			}
			.buttonStyle(.borderedProminent)
			.padding(.bottom, 16)
			
			Spacer()
		}
	}
	
	private var resultsView: some View {
		VStack(spacing: 18) {
			Spacer()
			
			Image(systemName: "checkmark.seal.fill")
				.font(.system(size: 82))
				.foregroundStyle(.green)
				.symbolEffect(.bounce, value: sessionCompleted)
			
			Text("Workout complete")
				.font(.largeTitle.weight(.bold))
			
			Text(timeString(elapsed))
				.font(.system(size: 44, weight: .black, design: .rounded))
				.monospacedDigit()
			
			if let selectedStation {
				Text(selectedStation.displayName(age: info.Age, sex: info.Gender))
					.font(.title3.weight(.semibold))
					.foregroundStyle(.secondary)
			}
			
			Spacer()
			
			VStack(spacing: 12) {
				Button {
					addExtraSet()
				} label: {
					Label("Add extra set", systemImage: "plus.circle.fill")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
				
				Button {
					finishWorkout()
				} label: {
					Label("Done", systemImage: "checkmark")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
			}
			.padding(.horizontal, 18)
			.padding(.bottom, 24)
		}
		.onAppear {
			recordCompletionIfNeeded()
			if !isExtraSet {
				showExtraSetPrompt = true
			}
		}
		.confirmationDialog(
			"Add an extra set?",
			isPresented: $showExtraSetPrompt,
			titleVisibility: .visible
		) {
			Button("Add extra set") { addExtraSet() }
			Button("No thanks", role: .cancel) {}
		} message: {
			Text("Optional bonus set for the same station.")
		}
	}
	
	private var alreadyDoneView: some View {
		VStack(spacing: 18) {
			Spacer()
			Image(systemName: "checkmark.circle.fill")
				.font(.system(size: 82))
				.foregroundStyle(.green)
			Text("Workout done today")
				.font(.largeTitle.weight(.bold))
				.multilineTextAlignment(.center)
			Text("Come back on your next scheduled session.")
				.font(.title3)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 24)
			Spacer()
		}
		.padding(.horizontal, 18)
	}
	
	private func startWorkout(_ station: NAPFAStation) {
		selectedStation = station
		let index = NAPFAStation.allCases.firstIndex(of: station) ?? 0
		let prev = WorkoutPlanner.grade(at: index, in: info.prev)
		let targ = WorkoutPlanner.grade(at: index, in: info.targ)
		intensityLabel = WorkoutPlanner.intensity(previous: prev, target: targ).rawValue
		sessionSteps = WorkoutPlanner.plan(for: station, info: info)
		currentIndex = 0
		elapsed = 0
		breakRemaining = 45
		breakTotal = 45
		breakSoundPlayed = false
		alarmSoundLoopCount = 0
		completionRecorded = false
		isExtraSet = false
		sessionCompleted = false
		isBreak = false
		isWorkingOut = true
		workoutSession.locksTabBar = true
	}
	
	private func startBreak() {
		guard currentIndex < sessionSteps.count - 1 else { return }
		breakRemaining = 45
		breakTotal = 45
		breakSoundPlayed = false
		alarmSoundLoopCount = 0
		isBreak = true
	}
	
	private func stopBreak() {
		isBreak = false
		moveToNextExercise()
	}
	
	private func moveToNextExercise() {
		guard currentIndex < sessionSteps.count - 1 else {
			completeSession()
			return
		}
		currentIndex += 1
		breakRemaining = 45
		breakTotal = 45
		breakSoundPlayed = false
		alarmSoundLoopCount = 0
		isBreak = false
	}
	
	private func completeSession() {
		isWorkingOut = false
		isBreak = false
		sessionCompleted = true
		workoutSession.locksTabBar = true
	}
	
	private func finishWorkout() {
		resetToPicker()
		workoutSession.locksTabBar = false
	}
	
	private func recordCompletionIfNeeded() {
		guard !completionRecorded, !isExtraSet else { return }
		completionRecorded = true
		AppState.recordWorkoutCompleted(station: selectedStation?.rawValue ?? "Workout")
	}
	
	private func addExtraSet() {
		guard let selectedStation else { return }
		sessionSteps = WorkoutStep.extraSet(for: selectedStation, age: info.Age, sex: info.Gender)
		currentIndex = 0
		breakRemaining = 45
		breakTotal = 45
		breakSoundPlayed = false
		alarmSoundLoopCount = 0
		sessionCompleted = false
		isBreak = false
		isWorkingOut = true
		isExtraSet = true
		workoutSession.locksTabBar = true
	}
	
	private func resetToPicker() {
		isWorkingOut = false
		isBreak = false
		sessionCompleted = false
		isExtraSet = false
		sessionSteps = []
		selectedStation = nil
	}
	
	private func display(_ grade: String) -> String {
		grade.isEmpty ? "—" : grade
	}
	
	private func timeString(_ seconds: Int) -> String {
		let minutes = max(seconds, 0) / 60
		let seconds = max(seconds, 0) % 60
		return "\(minutes):\(String(format: "%02d", seconds))"
	}
}

#Preview {
	Workout(info: .constant(data(Age: 0, Gender: false, prev: ["B", "", "", "", "", ""], targ: ["A", "", "", "", "", ""], schedule: [], NAPFA_Date: Date.now, Goals: [])))
		.environmentObject(WorkoutSessionState())
}
