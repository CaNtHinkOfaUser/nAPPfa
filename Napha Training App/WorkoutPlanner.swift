//
//  WorkoutPlanner.swift
//  Napha Training App
//

import Foundation

struct WorkoutStep: Identifiable {
	let id = UUID()
	let station: NAPFAStation
	let name: String
	let detail: String
	/// The step where the user enters their baseline test result.
	var recordsBaseline = false
	
	var videoURL: URL {
		station.videoURL
	}
	
	static func extraSet(for station: NAPFAStation, age: Int? = nil, sex: Bool? = nil) -> [WorkoutStep] {
		[
			WorkoutStep(
				station: station,
				name: "Extra Set",
				detail: "One best-quality set for \(station.displayName(age: age, sex: sex))"
			)
		]
	}
}

enum WorkoutIntensity: String {
	case maintenance = "Maintenance"
	case standard = "Standard"
	case push = "Push"
	case peak = "Peak"
	
	var multiplier: Double {
		switch self {
		case .maintenance: return 0.85
		case .standard: return 1.0
		case .push: return 1.2
		case .peak: return 1.45
		}
	}
	
	/// Working sets of the main exercise.
	var sets: Int {
		switch self {
		case .maintenance: return 2
		case .standard, .push: return 3
		case .peak: return 4
		}
	}
	
	/// Reps in each working set, as a share of this week's aim.
	var setShare: Double {
		switch self {
		case .maintenance: return 0.5
		case .standard: return 0.55
		case .push: return 0.65
		case .peak: return 0.7
		}
	}
}

/// Where a session sits relative to the NAPFA test: build volume early,
/// practise the test closer in, then back off in the final week.
enum TrainingPhase: String {
	case build = "Build"
	case sharpen = "Sharpen"
	case taper = "Taper"
}

/// How a station's goal lines up against the time left before the NAPFA test.
struct TrainingAssessment {
	let station: NAPFAStation
	let usesFullPullUps: Bool
	/// True when the plan starts from a baseline test result rather than a grade.
	let hasMeasuredBaseline: Bool
	let intensity: WorkoutIntensity
	let phase: TrainingPhase
	/// Days until the test, or nil when no future test date is set.
	let daysLeft: Int?
	/// Grades between the previous and target result.
	let gradeGap: Int
	/// Typical training time for this grade gap at three sessions a week.
	let weeksNeeded: Double
	/// Weeks from when the previous grade was set to the test, or nil without a future test date.
	let planWeeks: Double?
	/// Result to reach by the end of this week to stay on schedule.
	let weeklyAim: Double?
	/// Result the target grade needs on test day.
	let targetScore: Double?
	
	/// True when the plan has much less time than this grade gap usually takes.
	var needsMoreTime: Bool {
		guard gradeGap > 0, let planWeeks else { return false }
		return weeksNeeded > planWeeks * 1.5
	}
	
	var summary: String {
		guard let daysLeft else {
			return gradeGap > 0 ? "Set a future NAPFA date to time this plan" : "Target reached · maintaining"
		}
		if daysLeft == 0 { return "Test day · warm up and give it your best" }
		
		let timeLeft: String
		if daysLeft >= 14 {
			timeLeft = "\(daysLeft / 7) weeks left"
		} else if daysLeft == 1 {
			timeLeft = "Test tomorrow"
		} else {
			timeLeft = "\(daysLeft) days left"
		}
		
		if needsMoreTime {
			return "\(timeLeft) · this jump usually takes ~\(Int(weeksNeeded.rounded())) weeks"
		}
		guard let weeklyAim else { return timeLeft }
		let aim = station.formattedScore(WorkoutPlanner.rounded(weeklyAim, for: station))
		return gradeGap > 0 ? "\(timeLeft) · aim for \(aim) this week" : "\(timeLeft) · hold \(aim)"
	}
}

enum WorkoutPlanner {
	private static let day: TimeInterval = 86_400
	private static let week: TimeInterval = 7 * day
	
	static func gradeValue(_ grade: String) -> Int {
		switch grade.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
		case "A": return 6
		case "B": return 5
		case "C": return 4
		case "D": return 3
		case "E": return 2
		// NA means no NAPFA result yet or an unsure grade, so it starts from F.
		case "F", "NA": return 1
		default: return 3
		}
	}
	
	static func grade(at index: Int, in values: [String]) -> String {
		guard values.indices.contains(index) else { return "" }
		return values[index]
	}
	
	/// Rough coaching rule of thumb for how many weeks of three sessions a week it
	/// takes to move up one grade. Power and endurance improve more slowly.
	static func weeksPerGrade(for station: NAPFAStation, fullPullUps: Bool) -> Double {
		switch station {
		case .sitUps, .sitAndReach, .shuttleRun: return 3
		case .inclinedPullUps: return fullPullUps ? 4 : 3
		case .standingBroadJump: return 4
		case .run: return 5
		}
	}
	
	// MARK: - Assessment
	
	static func assessment(for station: NAPFAStation, info: data, now: Date = Date()) -> TrainingAssessment {
		let index = NAPFAStation.allCases.firstIndex(of: station) ?? 0
		return assessment(
			for: station,
			previousGrade: grade(at: index, in: info.prev),
			targetGrade: grade(at: index, in: info.targ),
			age: info.Age,
			isMale: info.Gender,
			testDate: info.NAPFA_Date,
			baselineDate: baselineDate(for: station) ?? now,
			measuredBaseline: baselineResult(for: station, age: info.Age, isMale: info.Gender),
			now: now
		)
	}
	
	/// Plans a straight line from the starting result, on the day it was recorded, to the
	/// target grade's result. The start is the baseline test result when there is one,
	/// otherwise the previous grade. The line reaches the target at the typical rate, or by
	/// test day if that comes first, and intensity rises when the time to the test is short
	/// for the size of the jump.
	static func assessment(
		for station: NAPFAStation,
		previousGrade: String,
		targetGrade: String,
		age: Int,
		isMale: Bool,
		testDate: Date?,
		baselineDate: Date,
		measuredBaseline: Double? = nil,
		now: Date = Date()
	) -> TrainingAssessment {
		let measuredGrade = measuredBaseline.map {
			NAPFAGradeCalculator.grade(for: station, age: age, sex: isMale, value: $0)
		}
		let previous = measuredGrade ?? (previousGrade.isEmpty ? "D" : previousGrade)
		let target = targetGrade.isEmpty ? previous : targetGrade
		let gap = gradeValue(target) - gradeValue(previous)
		let fullPullUps = station.isFullPullUp(age: age, isMale: isMale)
		let weeksNeeded = Double(max(gap, 0)) * weeksPerGrade(for: station, fullPullUps: fullPullUps)
		
		let calendar = Calendar.current
		let daysLeft = testDate.flatMap { date -> Int? in
			let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? -1
			return days >= 0 ? days : nil
		}
		let start = min(baselineDate, now)
		let futureTestDate = daysLeft == nil ? nil : testDate
		let planWeeks = futureTestDate.map { max($0.timeIntervalSince(start) / week, 0.5) }
		
		let intensity: WorkoutIntensity
		if gap <= 0 {
			intensity = .maintenance
		} else if let planWeeks {
			let urgency = weeksNeeded / planWeeks
			intensity = urgency <= 0.6 ? .standard : urgency <= 1 ? .push : .peak
		} else {
			intensity = gap >= 3 ? .peak : gap == 2 ? .push : .standard
		}
		
		let phase: TrainingPhase
		switch daysLeft {
		case .some(let days) where days <= 7: phase = .taper
		case .some(let days) where days <= 21: phase = .sharpen
		default: phase = .build
		}
		
		let baselineScore = measuredBaseline ?? NAPFAGradeCalculator.score(for: previous, station: station, age: age, sex: isMale)
		let targetScore = NAPFAGradeCalculator.score(for: target, station: station, age: age, sex: isMale)
		var weeklyAim: Double?
		if let baselineScore, let targetScore {
			if gap <= 0 {
				weeklyAim = station.lowerIsBetter ? min(baselineScore, targetScore) : max(baselineScore, targetScore)
			} else {
				var aimDate = start.addingTimeInterval(weeksNeeded * week)
				if let futureTestDate { aimDate = min(aimDate, futureTestDate) }
				let span = max(aimDate.timeIntervalSince(start), day)
				let progress = min(max(now.addingTimeInterval(week).timeIntervalSince(start) / span, 0), 1)
				weeklyAim = baselineScore + (targetScore - baselineScore) * progress
			}
		}
		
		return TrainingAssessment(
			station: station,
			usesFullPullUps: fullPullUps,
			hasMeasuredBaseline: measuredBaseline != nil,
			intensity: intensity,
			phase: phase,
			daysLeft: daysLeft,
			gradeGap: gap,
			weeksNeeded: weeksNeeded,
			planWeeks: planWeeks,
			weeklyAim: weeklyAim,
			targetScore: targetScore
		)
	}
	
	// MARK: - Plan
	
	static func plan(for station: NAPFAStation, info: data, now: Date = Date()) -> [WorkoutStep] {
		plan(for: assessment(for: station, info: info, now: now))
	}
	
	static func plan(for assessment: TrainingAssessment) -> [WorkoutStep] {
		let station = assessment.station
		let phase = assessment.phase
		let taper = phase == .taper
		let sets = taper ? max(2, assessment.intensity.sets - 1) : assessment.intensity.sets
		let share = taper ? 0.5 : min(assessment.intensity.setShare + (phase == .sharpen ? 0.1 : 0), 0.75)
		let aim = assessment.weeklyAim
		
		func step(_ name: String, _ detail: String) -> WorkoutStep {
			WorkoutStep(station: station, name: name, detail: detail)
		}
		
		func reps(minimum: Int, fallback: Int) -> Int {
			guard let aim else { return fallback }
			return max(minimum, Int((aim * share).rounded()))
		}
		
		func testDetail(_ effort: String) -> String {
			taper ? "Smooth practice at about 80% · save your max for test day" : "\(effort) · \(aimText(assessment))"
		}
		
		if assessment.daysLeft == 0 {
			let warmUpText = warmUp(for: station, fullPullUps: assessment.usesFullPullUps)
			return [step("NAPFA Test Today", "No training today. Warm up (\(warmUpText)), then rest and save your energy for the test.")]
		}
		
		switch station {
		case .sitUps:
			return [
				step("Crunches", "\(taper ? 10 : 15) controlled reps"),
				step("Sit-up Sets", "\(sets) × \(reps(minimum: 5, fallback: 15)) reps at test pace · 30 s rest between sets"),
				step("Leg Lifts", "\(taper ? 8 : 12) slow reps"),
				step("Timed Minute", testDetail("Max sit-ups in 1 min"))
			]
		case .standingBroadJump:
			let jumps = taper ? "3 smooth jumps at about 90%" : "Best of \(sets + 1) jumps · \(aimText(assessment))"
			return [
				step("Arm Swing Practice", "8 coordinated swings, then 2 easy jumps"),
				step("Squat Jumps", "\(sets) × 5 explosive reps · full rest between sets"),
				step("Broad Jump Attempts", jumps)
			]
		case .sitAndReach:
			let hold = taper ? 20 : 30
			return [
				step("Hamstring Stretch", "\(hold)s each side"),
				step("Seated Reach Holds", "\(sets) holds of \(hold)s, reaching a little further each time"),
				step("Test Reach", testDetail("Best of 3 reaches"))
			]
		case .inclinedPullUps where assessment.usesFullPullUps:
			let hang = taper ? 15 : 15 + 5 * sets
			// Sets of pull-ups need a few clean reps first; until then, slow
			// negatives build the strength without sloppy partial reps.
			if (aim ?? 0) < 3 {
				return [
					step("Dead Hang", "\(hang)s hold, shoulders pulled down"),
					step("Negative Pull-ups", "\(sets) × 3 slow lowers (5 s down) · 90 s rest between sets"),
					step("Inclined Pull-ups", "2 × 8 controlled reps"),
					step("Timed 30 s", testDetail("Max pull-ups in 30 s"))
				]
			}
			return [
				step("Dead Hang", "\(hang)s hold, shoulders pulled down"),
				step("Pull-up Sets", "\(sets) × \(reps(minimum: 1, fallback: 2)) reps, chin over the bar · 90 s rest between sets"),
				step("Negative Pull-ups", "3 slow lowers (5 s down)"),
				step("Timed 30 s", testDetail("Max pull-ups in 30 s"))
			]
		case .inclinedPullUps:
			return [
				step("Scapular Pulls", "\(taper ? 6 : 8) clean reps"),
				step("Inclined Pull-up Sets", "\(sets) × \(reps(minimum: 3, fallback: 8)) reps, chest to the bar · 60 s rest between sets"),
				step("Negative Rows", "5 slow lowers (3 s down)"),
				step("Timed 30 s", testDetail("Max inclined pull-ups in 30 s"))
			]
		case .shuttleRun:
			return [
				step("Acceleration Starts", "4 × 10 m starts"),
				step("Turn Practice", "6 low turns, touching past the line"),
				step("Shuttle Efforts", "\(sets) × 4×10 m at 90% · walk back to recover"),
				step("Timed Shuttle", testDetail("1 all-out shuttle"))
			]
		case .run:
			let raceTime = aim ?? assessment.targetScore
			let main: WorkoutStep
			switch phase {
			case .build:
				main = step("400 m Repeats", "\(sets + 1) × 400 m in \(split(raceTime, legs: 6)) · walk 90 s between")
			case .sharpen:
				main = step("800 m Repeats", "\(max(2, sets - 1)) × 800 m in \(split(raceTime, legs: 3)) · walk 2 min between")
			case .taper:
				main = step("Race-pace 400s", "2 × 400 m in \(split(raceTime, legs: 6)), relaxed")
			}
			return [
				step("Warm-up Jog", "\(taper ? 5 : 8) minutes easy"),
				main,
				step("Cool Down", "5 minutes easy jog, then walk")
			]
		}
	}
	
	/// Day-one session: do the station's NAPFA test once and record the result, so the
	/// plan starts from what the user can actually do instead of an old grade.
	static func baselineTest(for station: NAPFAStation, age: Int, isMale: Bool) -> [WorkoutStep] {
		let fullPullUps = station.isFullPullUp(age: age, isMale: isMale)
		let test: String
		switch station {
		case .sitUps:
			test = "As many sit-ups as you can in 1 minute, knees bent and feet held down. Count only full reps."
		case .standingBroadJump:
			test = "Jump forward from a standing start with both feet. Measure from the take-off line to the back of your nearest heel. Enter your best of 3 jumps in cm."
		case .sitAndReach:
			test = "Sit with your legs straight and soles flat against a sit-and-reach box. Reach forward slowly with both hands and hold for 2 seconds. Enter your best of 2 reaches in cm."
		case .inclinedPullUps where fullPullUps:
			test = "Hang from the bar with straight arms. Pull your chin over the bar as many times as you can in 30 seconds, lowering all the way each time."
		case .inclinedPullUps:
			test = "Hang under a low bar with your body straight and heels on the ground. Pull your chest to the bar as many times as you can in 30 seconds."
		case .shuttleRun:
			test = "Run the 4 × 10 m shuttle as fast as you can, touching past each line. Enter your time in seconds, e.g. 11.3."
		case .run:
			test = "Run 2.4 km (6 laps of a 400 m track) at your best steady pace. Enter your time."
		}
		let warmUpText = warmUp(for: station, fullPullUps: fullPullUps)
		return [
			WorkoutStep(station: station, name: "Warm-up", detail: warmUpText.prefix(1).uppercased() + warmUpText.dropFirst()),
			WorkoutStep(station: station, name: "Baseline Test", detail: test, recordsBaseline: true)
		]
	}
	
	private static func warmUp(for station: NAPFAStation, fullPullUps: Bool) -> String {
		switch station {
		case .sitUps: return "5 minutes of light jogging, then 5 easy sit-ups"
		case .standingBroadJump: return "5 minutes of light jogging, leg swings, then 2 easy jumps"
		case .sitAndReach: return "5 minutes of light jogging, then gentle hamstring stretches"
		case .inclinedPullUps: return fullPullUps ? "arm circles, a 10 s hang, then 2 easy pull-ups" : "arm circles, then 3 easy inclined pull-ups"
		case .shuttleRun: return "5 minutes of light jogging, then 2 easy runs through the turns"
		case .run: return "5 minutes of easy jogging and a few short strides"
		}
	}
	
	// MARK: - Formatting
	
	/// Rounds a result the way it is recorded: whole reps or cm, tenths of a second for
	/// the shuttle run, and 5 s steps for the 2.4 km run.
	static func rounded(_ value: Double, for station: NAPFAStation) -> Double {
		switch station {
		case .shuttleRun: return (value * 10).rounded() / 10
		case .run: return (value / 5).rounded() * 5
		default: return value.rounded()
		}
	}
	
	private static func aimText(_ assessment: TrainingAssessment) -> String {
		let station = assessment.station
		guard let weeklyAim = assessment.weeklyAim else { return "go for your best" }
		let aim = station.formattedScore(rounded(weeklyAim, for: station))
		guard assessment.gradeGap > 0, let targetScore = assessment.targetScore else { return "hold \(aim)" }
		let target = station.formattedScore(rounded(targetScore, for: station))
		return aim == target ? "aim for \(target)" : "aim for \(aim) this week, \(target) on test day"
	}
	
	/// Time for one leg of the 2.4 km run at the given finishing time.
	private static func split(_ raceTime: Double?, legs: Double) -> String {
		guard let raceTime else { return "target pace" }
		let seconds = Int((raceTime / legs).rounded())
		return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
	}
	
	// MARK: - Baseline
	
	/// When the station's starting point was set; its plan starts from that result on that day.
	static func baselineDate(for station: NAPFAStation) -> Date? {
		let dates = UserDefaults.standard.object(forKey: AppKeys.baselineDates) as? [String: Date]
		return dates?[station.rawValue]
	}
	
	/// The latest baseline test result for the version of the test the user does now.
	static func baselineResult(for station: NAPFAStation, age: Int, isMale: Bool) -> Double? {
		let results = UserDefaults.standard.object(forKey: AppKeys.baselineResults) as? [String: Double]
		return results?[resultKey(for: station, fullPullUps: station.isFullPullUp(age: age, isMale: isMale))]
	}
	
	/// Saves a baseline test result and makes its grade the station's previous grade, so every
	/// screen shows where the user is starting from. A target below that grade is raised to it.
	static func recordBaselineResult(_ value: Double, for station: NAPFAStation, info: inout data, now: Date = Date()) {
		let defaults = UserDefaults.standard
		let fullPullUps = station.isFullPullUp(age: info.Age, isMale: info.Gender)
		var results = defaults.object(forKey: AppKeys.baselineResults) as? [String: Double] ?? [:]
		results[resultKey(for: station, fullPullUps: fullPullUps)] = value
		defaults.set(results, forKey: AppKeys.baselineResults)
		
		var dates = defaults.object(forKey: AppKeys.baselineDates) as? [String: Date] ?? [:]
		dates[station.rawValue] = now
		defaults.set(dates, forKey: AppKeys.baselineDates)
		
		guard let index = NAPFAStation.allCases.firstIndex(of: station) else { return }
		let measured = NAPFAGradeCalculator.grade(for: station, age: info.Age, sex: info.Gender, value: value)
		var previous = padded(info.prev)
		var targets = padded(info.targ)
		previous[index] = measured
		if !targets[index].isEmpty, gradeValue(targets[index]) < gradeValue(measured) {
			targets[index] = measured
		}
		info.prev = previous
		info.targ = targets
		defaults.set(previous, forKey: AppKeys.previousGrades)
		defaults.set(targets, forKey: AppKeys.targetGrades)
		if fullPullUps {
			defaults.set(true, forKey: AppKeys.pullUpGradesReviewed)
		}
	}
	
	/// Restarts a station's plan when its previous grade changes, and gives stations that
	/// have a grade but no start date one starting now. A grade picked by hand replaces any
	/// baseline test result for that station.
	static func updateBaselineDates(previous: [String], changedFrom old: [String]? = nil, now: Date = Date()) {
		let defaults = UserDefaults.standard
		var dates = defaults.object(forKey: AppKeys.baselineDates) as? [String: Date] ?? [:]
		var results = defaults.object(forKey: AppKeys.baselineResults) as? [String: Double] ?? [:]
		for (index, station) in NAPFAStation.allCases.enumerated() {
			let current = grade(at: index, in: previous)
			let changed = old.map { grade(at: index, in: $0) != current } == true
			if current.isEmpty {
				dates[station.rawValue] = nil
			} else if dates[station.rawValue] == nil || changed {
				dates[station.rawValue] = now
			}
			if current.isEmpty || changed {
				results[resultKey(for: station, fullPullUps: false)] = nil
				results[resultKey(for: station, fullPullUps: true)] = nil
			}
		}
		defaults.set(dates, forKey: AppKeys.baselineDates)
		defaults.set(results, forKey: AppKeys.baselineResults)
	}
	
	/// Inclined and full pull-up results are kept apart, so an inclined result is never
	/// read as a full pull-up result after a boy turns 15.
	private static func resultKey(for station: NAPFAStation, fullPullUps: Bool) -> String {
		fullPullUps ? "\(station.rawValue) (full)" : station.rawValue
	}
	
	private static func padded(_ grades: [String]) -> [String] {
		grades + Array(repeating: "", count: max(0, NAPFAStation.allCases.count - grades.count))
	}
}

/// What the user types in for a baseline test result.
struct BaselineEntry: Equatable {
	/// Reps, cm or seconds, or the minutes of a 2.4 km time.
	var amount = ""
	/// The seconds of a 2.4 km time.
	var seconds = ""
	
	/// The result in the units the grade tables use, or nil until it's a believable result.
	func value(for station: NAPFAStation) -> Double? {
		let text = amount.trimmingCharacters(in: .whitespaces)
		switch station {
		case .run:
			let secondsText = seconds.trimmingCharacters(in: .whitespaces)
			guard let minutes = Int(text), let secs = secondsText.isEmpty ? 0 : Int(secondsText), (0..<60).contains(secs) else {
				return nil
			}
			let total = Double(minutes * 60 + secs)
			return (240...3_600).contains(total) ? total : nil
		case .shuttleRun:
			guard let time = Double(text.replacingOccurrences(of: ",", with: ".")), (5...30).contains(time) else { return nil }
			return time
		case .sitUps, .inclinedPullUps:
			guard let reps = Int(text), (0...100).contains(reps) else { return nil }
			return Double(reps)
		case .standingBroadJump, .sitAndReach:
			guard let cm = Int(text), (0...400).contains(cm) else { return nil }
			return Double(cm)
		}
	}
}
