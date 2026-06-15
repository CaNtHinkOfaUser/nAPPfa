import SwiftUI

struct AutoCalcView: View {
    @Binding var info: data
    @State private var selectedStation: NAPFAStation = .sitUps
    @State private var values: [NAPFAStation: Double] = [:]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Station") {
                    Picker("Station", selection: $selectedStation) {
                        ForEach(NAPFAStation.allCases) { station in
                            Label(station.rawValue, systemImage: station.icon)
                                .tag(station)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Result") {
                    Slider(
                        value: activeValue,
                        in: selectedStation.sliderRange,
                        step: selectedStation.sliderStep
                    )

                    LabeledContent("Value", value: valueText)
                    LabeledContent("Grade", value: gradeText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }

                Section("Based On") {
                    LabeledContent("Age", value: "\(NAPFAGradeCalculator.normalizedAge(info.Age))")
                    LabeledContent("Sex", value: info.Gender ? "Male" : "Female")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Auto Calculation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var activeValue: Binding<Double> {
        Binding {
            values[selectedStation] ?? selectedStation.defaultScore
        } set: { newValue in
            values[selectedStation] = newValue
        }
    }

    private var valueText: String {
        selectedStation.formattedScore(activeValue.wrappedValue)
    }

    private var gradeText: String {
        NAPFAGradeCalculator.grade(
            for: selectedStation,
            age: info.Age,
            sex: info.Gender,
            value: activeValue.wrappedValue
        )
    }
}

private enum NAPFAGradeCalculator {
    private static let gradeLetters = ["A", "B", "C", "D", "E"]

    private static let thresholds: [NAPFAStation: [Bool: [Int: [Double]]]] = [
        .sitUps: [
            true: [
                9: [36, 30, 25, 20, 15],
                10: [37, 31, 26, 21, 17],
                11: [40, 34, 30, 25, 20],
                12: [42, 36, 32, 27, 22],
                13: [43, 38, 34, 29, 25],
                14: [43, 40, 37, 33, 29],
                15: [43, 40, 37, 34, 30],
                16: [43, 40, 37, 34, 31],
                17: [43, 40, 37, 34, 31],
                18: [43, 40, 37, 34, 31],
                19: [43, 40, 37, 34, 31],
                20: [40, 37, 34, 31, 28]
            ],
            false: [
                9: [27, 22, 18, 14, 10],
                10: [28, 23, 19, 15, 11],
                11: [29, 24, 20, 16, 12],
                12: [30, 25, 21, 17, 13],
                13: [31, 26, 22, 18, 14],
                14: [31, 28, 24, 20, 16],
                15: [31, 29, 25, 21, 17],
                16: [31, 29, 26, 22, 18],
                17: [31, 29, 27, 23, 19],
                18: [31, 29, 27, 24, 20],
                19: [31, 29, 27, 24, 21],
                20: [29, 27, 25, 23, 21]
            ]
        ],
        .standingBroadJump: [
            true: [
                9: [169, 159, 149, 139, 130],
                10: [175, 165, 156, 146, 137],
                11: [189, 177, 166, 155, 144],
                12: [203, 189, 176, 163, 150],
                13: [215, 202, 189, 176, 164],
                14: [226, 216, 206, 196, 186],
                15: [238, 228, 218, 208, 198],
                16: [246, 236, 226, 216, 206],
                17: [250, 240, 230, 220, 210],
                18: [252, 242, 232, 222, 212],
                19: [252, 242, 232, 222, 212],
                20: [243, 234, 225, 216, 207]
            ],
            false: [
                9: [159, 148, 139, 129, 119],
                10: [162, 152, 143, 134, 125],
                11: [165, 156, 147, 138, 129],
                12: [168, 159, 150, 141, 132],
                13: [171, 162, 153, 144, 135],
                14: [178, 169, 160, 151, 142],
                15: [183, 174, 165, 156, 147],
                16: [187, 178, 169, 160, 151],
                17: [190, 181, 172, 163, 154],
                18: [193, 183, 174, 165, 156],
                19: [196, 185, 174, 165, 156],
                20: [198, 186, 174, 162, 150]
            ]
        ],
        .sitAndReach: [
            true: [
                9: [34, 30, 26, 21, 16],
                10: [36, 32, 28, 23, 18],
                11: [38, 34, 30, 25, 20],
                12: [40, 36, 32, 28, 23],
                13: [42, 38, 34, 30, 25],
                14: [44, 40, 36, 32, 27],
                15: [46, 42, 38, 34, 29],
                16: [48, 44, 40, 36, 31],
                17: [49, 45, 41, 37, 32],
                18: [49, 45, 41, 37, 32],
                19: [49, 45, 41, 37, 32],
                20: [48, 44, 40, 36, 32]
            ],
            false: [
                9: [34, 31, 28, 24, 19],
                10: [36, 33, 30, 26, 21],
                11: [38, 35, 32, 28, 23],
                12: [40, 37, 34, 30, 25],
                13: [42, 39, 36, 32, 27],
                14: [44, 41, 38, 34, 29],
                15: [46, 43, 39, 35, 30],
                16: [47, 44, 40, 36, 31],
                17: [47, 44, 40, 36, 32],
                18: [47, 44, 40, 36, 32],
                19: [46, 43, 39, 36, 32],
                20: [44, 41, 38, 35, 31]
            ]
        ],
        .inclinedPullUps: [
            true: [
                9: [22, 18, 13, 9, 3],
                10: [23, 19, 14, 9, 3],
                11: [24, 20, 15, 10, 4],
                12: [25, 21, 16, 11, 5],
                13: [26, 22, 17, 12, 7],
                14: [27, 23, 18, 13, 8],
                15: [8, 6, 5, 3, 1],
                16: [9, 7, 5, 3, 1],
                17: [10, 8, 6, 4, 2],
                18: [11, 9, 7, 5, 3],
                19: [11, 9, 7, 5, 3],
                20: [11, 9, 7, 5, 3]
            ],
            false: [
                9: [15, 12, 9, 6, 2],
                10: [15, 12, 9, 6, 3],
                11: [16, 13, 10, 7, 3],
                12: [16, 13, 10, 7, 3],
                13: [17, 13, 10, 7, 3],
                14: [17, 14, 10, 7, 3],
                15: [17, 14, 10, 7, 3],
                16: [18, 14, 11, 7, 3],
                17: [18, 14, 11, 7, 3],
                18: [18, 15, 11, 8, 4],
                19: [18, 15, 11, 8, 5],
                20: [18, 15, 11, 8, 5]
            ]
        ],
        .shuttleRun: [
            true: [
                9: [11.2, 11.8, 12.2, 12.7, 13.1],
                10: [11.0, 11.6, 12.0, 12.4, 12.9],
                11: [10.6, 11.2, 11.6, 12.0, 12.5],
                12: [10.3, 10.9, 11.3, 11.7, 12.2],
                13: [10.2, 10.7, 11.1, 11.5, 11.9],
                14: [10.1, 10.4, 10.8, 11.2, 11.6],
                15: [10.1, 10.3, 10.5, 10.9, 11.3],
                16: [10.1, 10.3, 10.5, 10.7, 11.1],
                17: [10.1, 10.3, 10.5, 10.7, 10.9],
                18: [10.1, 10.3, 10.5, 10.7, 10.9],
                19: [10.1, 10.3, 10.5, 10.7, 10.9],
                20: [10.3, 10.5, 10.7, 10.9, 11.1]
            ],
            false: [
                9: [11.7, 12.3, 12.8, 13.3, 13.8],
                10: [11.6, 12.2, 12.7, 13.2, 13.7],
                11: [11.5, 12.1, 12.5, 12.9, 13.4],
                12: [11.4, 11.9, 12.3, 12.7, 13.2],
                13: [11.2, 11.7, 12.2, 12.7, 13.2],
                14: [11.4, 11.8, 12.2, 12.6, 13.0],
                15: [11.2, 11.6, 12.0, 12.4, 12.8],
                16: [11.2, 11.5, 11.8, 12.2, 12.6],
                17: [11.2, 11.5, 11.8, 12.1, 12.5],
                18: [11.2, 11.5, 11.8, 12.1, 12.4],
                19: [11.2, 11.5, 11.8, 12.1, 12.4],
                20: [11.5, 11.8, 12.1, 12.4, 12.7]
            ]
        ],
        .run: [
            true: [
                12: [720, 790, 860, 930, 1010],
                13: [690, 750, 820, 890, 960],
                14: [660, 720, 780, 850, 920],
                15: [640, 700, 760, 820, 880],
                16: [630, 690, 740, 800, 850],
                17: [620, 670, 720, 770, 820],
                18: [620, 670, 710, 760, 810],
                19: [620, 660, 700, 750, 800],
                20: [620, 660, 700, 740, 780]
            ],
            false: [
                12: [880, 940, 1000, 1060, 1120],
                13: [870, 930, 990, 1050, 1110],
                14: [860, 920, 980, 1040, 1100],
                15: [850, 910, 970, 1030, 1090],
                16: [840, 900, 960, 1020, 1070],
                17: [840, 890, 950, 1000, 1050],
                18: [840, 890, 940, 990, 1040],
                19: [860, 890, 930, 980, 1030],
                20: [900, 930, 960, 990, 1020]
            ]
        ]
    ]

    static func normalizedAge(_ age: Int) -> Int {
        if age >= 20 { return 20 }
        if age <= 9 { return 9 }
        return age
    }

    static func grade(for station: NAPFAStation, age: Int, sex: Bool, value: Double) -> String {
        let ageKey = station == .run ? max(normalizedAge(age), 12) : normalizedAge(age)
        guard let row = thresholds[station]?[sex]?[ageKey] else { return "N/A" }

        for (letter, threshold) in zip(gradeLetters, row) {
            if station.lowerIsBetter {
                if value <= threshold { return letter }
            } else if value >= threshold {
                return letter
            }
        }

        return "F"
    }
}

private extension NAPFAStation {
    var sliderRange: ClosedRange<Double> {
        switch self {
        case .sitUps:
            return 0...60
        case .standingBroadJump:
            return 100...280
        case .sitAndReach:
            return 0...60
        case .inclinedPullUps:
            return 0...35
        case .shuttleRun:
            return 9...15
        case .run:
            return 480...1_500
        }
    }

    var sliderStep: Double {
        self == .shuttleRun ? 0.1 : 1
    }

    var defaultScore: Double {
        switch self {
        case .sitUps:
            return 30
        case .standingBroadJump:
            return 170
        case .sitAndReach:
            return 30
        case .inclinedPullUps:
            return 8
        case .shuttleRun:
            return 12
        case .run:
            return 900
        }
    }

    var lowerIsBetter: Bool {
        self == .shuttleRun || self == .run
    }

    func formattedScore(_ value: Double) -> String {
        switch self {
        case .sitUps, .inclinedPullUps:
            return String(format: "%.0f reps", value)
        case .standingBroadJump, .sitAndReach:
            return String(format: "%.0f cm", value)
        case .shuttleRun:
            return String(format: "%.1f sec", value)
        case .run:
            return timeString(Int(value.rounded()))
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = max(seconds, 0) / 60
        let seconds = max(seconds, 0) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    AutoCalcView(info: .constant(data(Age: 12, Gender: true, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])))
}
