//  Settings.swift
//  Napha Training App

import SwiftUI

struct Settings: View {
	@Binding var info: data
	@Binding var GoalSheet: Bool
	@Binding var AgeSheet: Bool
	@Binding var SchedSheet: Bool
	@Binding var selectedTimedSettings: [Date]
	@Binding var selectedDaysSettings: [Int]
	@Binding var Sex: Bool
	@Binding var age: Int
	@Binding var ftSettings: Bool
	
	@State private var goalSheetSettings = false
	@State private var ageSheetSettings = false
	@State private var autoCalcSettings = false
	@State private var appeared = false
	@AppStorage(AppKeys.darkModeEnabled) private var darkModeEnabled = false
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 14) {
					settingsHero
					
					settingsGroup(title: "Training") {
						SettingsRow(title: "Goal setting", subtitle: "Grades & custom goals", icon: "target", color: .blue) {
							goalSheetSettings = true
						}
						SettingsRow(title: "Auto calculation", subtitle: "Raw score to grade", icon: "candybarphone", color: .blue) {
							autoCalcSettings = true
						}
						SettingsRow(title: "Scheduling", subtitle: "Days, times, reminders", icon: "calendar.badge.clock", color: .green) {
							SchedSheet = true
						}
					}
					
					settingsGroup(title: "Profile") {
						SettingsRow(title: "Age and sex", subtitle: "Used for grade tables", icon: "person.crop.circle", color: .orange) {
							ageSheetSettings = true
						}
					}
					
					settingsGroup(title: "Appearance") {
						SettingsToggleRow(
							title: "Dark mode",
							subtitle: "Use a darker app appearance",
							icon: "moon.fill",
							color: .indigo,
							isOn: $darkModeEnabled
						)
					}
				}
				.padding(.horizontal, 18)
				.padding(.bottom, 110)
				.opacity(appeared ? 1 : 0)
				.offset(y: appeared ? 0 : 12)
			}
			.background(Color(.systemGroupedBackground))
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.large)
			.onAppear {
				withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
					appeared = true
				}
			}
			.fullScreenCover(isPresented: $goalSheetSettings) {
				Goal_Page(start: .constant(false), info: $info, Sex: $Sex, Age: $age, GoalSheet: $GoalSheet)
			}
			.fullScreenCover(isPresented: $autoCalcSettings) {
				AutoCalcView(info: $info)
			}
			.fullScreenCover(isPresented: $ageSheetSettings) {
				Age_Gender(start: .constant(false), info: $info, ageFirstTime: $ftSettings, ageSheet: $AgeSheet)
			}
			.fullScreenCover(isPresented: $SchedSheet) {
				Scheduling_(
					start: .constant(false),
					info: $info,
					selectedDays: $selectedDaysSettings,
					selectedTimes: $selectedTimedSettings,
					schedSheet: $SchedSheet
				)
			}
		}
	}
	
	private var settingsHero: some View {
		VStack(spacing: 14) {
			HStack(spacing: 14) {
				ZStack {
					Circle()
						.fill(
							AngularGradient(
								colors: [.orange, .pink, .purple, .blue, .orange],
								center: .center
							)
						)
					Image(systemName: "person.crop.circle.fill")
						.font(.system(size: 50))
						.foregroundStyle(.white, .gray.opacity(0.35))
						.background(Circle().fill(Color(.systemBackground)))
						.padding(3)
				}
				.frame(width: 64, height: 64)
				
				VStack(alignment: .leading, spacing: 4) {
					Text(profileName)
						.font(.title2.weight(.bold))
					Text(heroSubtitle)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				Spacer()
			}
			
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 10) {
					ForEach(profileBadges) { badge in
						badge
					}
				}
				.padding(.horizontal, 2)
			}
		}
		.padding(16)
		.background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
		.modifier(PopUpCard())
	}
	
	private var profileName: String {
		"Your Profile"
	}
	
	private var heroSubtitle: String {
		let sex = info.Gender ? "Male" : "Female"
		let ageText = info.Age > 0 ? " · Age \(info.Age)" : ""
		return "\(sex)\(ageText)"
	}
	
	private var profileBadges: [ProfileBadge] {
		let streak = AppState.currentStreak(
			selectedDays: selectedDaysSettings,
			selectedTimes: selectedTimedSettings
		)
		let workouts = AppState.workoutHistory().count
		let intensity = dominantIntensityLabel
		let goalReached = goalsReachedCount
		
		return [
			ProfileBadge(
				id: "streak",
				icon: "flame.fill",
				text: "\(streak) day streak",
				tint: .orange
			),
			ProfileBadge(
				id: "workouts",
				icon: "figure.strengthtraining.traditional",
				text: "\(workouts) workouts",
				tint: .blue
			),
			ProfileBadge(
				id: "intensity",
				icon: "bolt.fill",
				text: intensity,
				tint: .purple
			),
			ProfileBadge(
				id: "goal",
				icon: "checkmark.seal.fill",
				text: goalReached > 0 ? "\(goalReached) goal met" : "Goal pending",
				tint: goalReached > 0 ? .green : .gray
			)
		]
	}
	
	/// The intensity label that best reflects the user's current targets.
	private var dominantIntensityLabel: String {
		let levels = NAPFAStation.allCases.indices.compactMap { index -> WorkoutIntensity? in
			let prev = WorkoutPlanner.grade(at: index, in: info.prev)
			let targ = WorkoutPlanner.grade(at: index, in: info.targ)
			guard !prev.isEmpty, !targ.isEmpty else { return nil }
			return WorkoutPlanner.intensity(previous: prev, target: targ)
		}
		guard let top = levels.max(by: { $0.multiplier < $1.multiplier }) else {
			return "Not set"
		}
		return top.rawValue
	}
	
	/// Number of stations where the previous grade already meets/exceeds the target.
	private var goalsReachedCount: Int {
		NAPFAStation.allCases.indices.reduce(0) { count, index in
			let prev = WorkoutPlanner.grade(at: index, in: info.prev)
			let targ = WorkoutPlanner.grade(at: index, in: info.targ)
			guard !prev.isEmpty, !targ.isEmpty else { return count }
			let reached = WorkoutPlanner.gradeValue(prev) >= WorkoutPlanner.gradeValue(targ)
			return reached ? count + 1 : count
		}
	}
	
	private func settingsGroup(title: String, @ViewBuilder rows: () -> some View) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(title)
				.font(.headline)
				.padding(.leading, 4)
			VStack(spacing: 0) {
				rows()
			}
			.background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
			.popUpCard()
		}
	}
}

private struct SettingsRow: View {
	let title: String
	var subtitle: String = ""
	let icon: String
	let color: Color
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 14) {
				Image(systemName: icon)
					.font(.title3.weight(.semibold))
					.foregroundStyle(color)
					.frame(width: 40, height: 40)
					.background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
				
				VStack(alignment: .leading, spacing: 2) {
					Text(title)
						.font(.body.weight(.semibold))
						.foregroundStyle(.primary)
					if !subtitle.isEmpty {
						Text(subtitle)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
				
				Spacer()
				
				Image(systemName: "chevron.right")
					.font(.caption.weight(.bold))
					.foregroundStyle(.tertiary)
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 12)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}

private struct SettingsToggleRow: View {
	let title: String
	var subtitle: String = ""
	let icon: String
	let color: Color
	@Binding var isOn: Bool
	
	var body: some View {
		HStack(spacing: 14) {
			Image(systemName: icon)
				.font(.title3.weight(.semibold))
				.foregroundStyle(color)
				.frame(width: 40, height: 40)
				.background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.body.weight(.semibold))
				if !subtitle.isEmpty {
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
			Toggle(title, isOn: $isOn)
				.labelsHidden()
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 12)
	}
}

private struct ProfileBadge: View, Identifiable {
	let id: String
	let icon: String
	let text: String
	let tint: Color
	
	var body: some View {
		HStack(spacing: 6) {
			Image(systemName: icon)
				.font(.caption.weight(.bold))
			Text(text)
				.font(.caption.weight(.semibold))
		}
		.foregroundStyle(tint)
		.padding(.horizontal, 10)
		.padding(.vertical, 6)
		.background(tint.opacity(0.14), in: Capsule())
	}
}

struct Settings_Previews: PreviewProvider {
	static var previews: some View {
		Settings(
			info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
			GoalSheet: .constant(false),
			AgeSheet: .constant(false),
			SchedSheet: .constant(false),
			selectedTimedSettings: .constant([]),
			selectedDaysSettings: .constant([]),
			Sex: .constant(true),
			age: .constant(0),
			ftSettings: .constant(true)
		)
	}
}
