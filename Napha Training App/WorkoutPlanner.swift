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

    var videoURL: URL {
        station.videoURL
    }

    static func extraSet(for station: NAPFAStation) -> [WorkoutStep] {
        [
            WorkoutStep(
                station: station,
                name: "Extra Set",
                detail: "One best-quality set for \(station.rawValue)"
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
}

enum WorkoutPlanner {
    static func gradeValue(_ grade: String) -> Int {
        switch grade.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "A": return 6
        case "B": return 5
        case "C": return 4
        case "D": return 3
        case "E": return 2
        case "F": return 1
        default: return 3
        }
    }

    static func intensity(previous: String, target: String) -> WorkoutIntensity {
        let gap = gradeValue(target) - gradeValue(previous)
        if gap >= 3 { return .peak }
        if gap >= 2 { return .push }
        if gap >= 1 { return .standard }
        return .maintenance
    }

    static func grade(at index: Int, in values: [String]) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index]
    }

    static func plan(for station: NAPFAStation, info: data) -> [WorkoutStep] {
        let index = NAPFAStation.allCases.firstIndex(of: station) ?? 0
        let previous = grade(at: index, in: info.prev)
        let target = grade(at: index, in: info.targ)
        return plan(for: station, previousGrade: previous, targetGrade: target)
    }

    static func plan(for station: NAPFAStation, previousGrade: String, targetGrade: String) -> [WorkoutStep] {
        let level = intensity(previous: previousGrade, target: targetGrade)
        let m = level.multiplier

        switch station {
        case .sitUps:
            return [
                WorkoutStep(
                    station: station,
                    name: "Crunches",
                    detail: "\(scaled(10, m)) controlled reps · \(level.rawValue) block"
                ),
                WorkoutStep(
                    station: station,
                    name: "Leg Lifts",
                    detail: "\(scaled(8, m)) slow reps"
                ),
                WorkoutStep(
                    station: station,
                    name: "Sit-ups",
                    detail: "\(scaled(15, m))–\(scaled(25, m)) quality reps"
                )
            ]
        case .standingBroadJump:
            return [
                WorkoutStep(station: station, name: "Squat Jumps", detail: "\(scaled(6, m)) explosive reps"),
                WorkoutStep(station: station, name: "Arm Swing Practice", detail: "\(scaled(8, m)) coordinated swings"),
                WorkoutStep(
                    station: station,
                    name: "Broad Jump Attempts",
                    detail: "\(scaled(4, m)) measured jumps"
                )
            ]
        case .sitAndReach:
            let hold = max(8, scaled(10, m))
            return [
                WorkoutStep(station: station, name: "Hamstring Stretch", detail: "\(hold)s each side"),
                WorkoutStep(station: station, name: "Seated Reach Holds", detail: "\(scaled(4, m)) holds of \(hold)s"),
                WorkoutStep(station: station, name: "Reach & Hold", detail: "Progress flexibility gradually")
            ]
        case .inclinedPullUps:
            return [
                WorkoutStep(station: station, name: "Scapular Pulls", detail: "\(scaled(6, m)) clean reps"),
                WorkoutStep(station: station, name: "Negative Rows", detail: "\(scaled(5, m)) slow negatives"),
                WorkoutStep(
                    station: station,
                    name: "Inclined Pull-ups",
                    detail: "\(scaled(6, m))–\(scaled(12, m)) reps · \(level.rawValue)"
                )
            ]
        case .shuttleRun:
            return [
                WorkoutStep(station: station, name: "Acceleration Starts", detail: "\(scaled(4, m)) starts"),
                WorkoutStep(station: station, name: "Turn Practice", detail: "\(scaled(6, m)) low turns"),
                WorkoutStep(station: station, name: "Shuttle Efforts", detail: "\(scaled(2, m)) timed runs + 1 max effort")
            ]
        case .run:
            let warm = max(3, scaled(4, m))
            let intervals = scaled(3, m)
            return [
                WorkoutStep(station: station, name: "Warm-up Jog", detail: "\(warm) minutes easy"),
                WorkoutStep(station: station, name: "Interval Pace", detail: "\(intervals) × 2 min at target pace"),
                WorkoutStep(station: station, name: "Cool Down", detail: "\(max(2, warm - 1)) minutes walk")
            ]
        }
    }

    private static func scaled(_ base: Int, _ multiplier: Double) -> Int {
        max(1, Int((Double(base) * multiplier).rounded()))
    }

    private static func display(_ grade: String) -> String {
        grade.isEmpty ? "not set" : grade
    }
}
