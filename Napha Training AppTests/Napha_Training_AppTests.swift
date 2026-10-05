//
//  Napha_Training_AppTests.swift
//  Napha Training AppTests
//
//  Created by Kui Jun on 24/5/24.
//

import XCTest
@testable import Napha_Training_App

final class Napha_Training_AppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

final class PullUpRuleTests: XCTestCase {

    func testOnlyMalesSwitchToFullPullUpsAt15() {
        XCTAssertEqual(NAPFAStation.inclinedPullUps.displayName(age: 14, sex: true), "Inclined Pull Ups")
        XCTAssertEqual(NAPFAStation.inclinedPullUps.displayName(age: 15, sex: true), "Pull-ups")
        XCTAssertEqual(NAPFAStation.inclinedPullUps.displayName(age: 18, sex: true), "Pull-ups")
        XCTAssertEqual(NAPFAStation.inclinedPullUps.displayName(age: 15, sex: false), "Inclined Pull Ups")
        XCTAssertEqual(NAPFAStation.inclinedPullUps.displayName(age: 18, sex: false), "Inclined Pull Ups")
        XCTAssertEqual(NAPFAStation.inclinedPullUps.displayName(), "Inclined Pull Ups")
        XCTAssertEqual(NAPFAStation.sitUps.displayName(age: 15, sex: true), "Sit Ups")
    }

    func testAgeTicksOverAtTheStartOfTheBirthday() {
        let birthdate = date(2011, 10, 3, hour: 15)
        XCTAssertEqual(AppState.age(from: birthdate, now: date(2026, 10, 2, hour: 23)), 14)
        XCTAssertEqual(AppState.age(from: birthdate, now: date(2026, 10, 3, hour: 0)), 15)
    }

    func testPullUpStandardsFollowTheSwitch() {
        XCTAssertEqual(NAPFAGradeCalculator.score(for: "A", station: .inclinedPullUps, age: 14, sex: true), 27)
        XCTAssertEqual(NAPFAGradeCalculator.score(for: "A", station: .inclinedPullUps, age: 15, sex: true), 8)
        XCTAssertEqual(NAPFAGradeCalculator.score(for: "A", station: .inclinedPullUps, age: 15, sex: false), 17)
        XCTAssertEqual(NAPFAGradeCalculator.grade(for: .inclinedPullUps, age: 15, sex: true, value: 8), "A")
    }
}

final class WorkoutPlannerTests: XCTestCase {
    private let start = date(2026, 1, 5, hour: 9)

    private func assess(
        _ previous: String,
        _ target: String,
        station: NAPFAStation = .sitUps,
        age: Int = 14,
        isMale: Bool = true,
        testInDays: Int?,
        daysIn: Int = 0
    ) -> TrainingAssessment {
        WorkoutPlanner.assessment(
            for: station,
            previousGrade: previous,
            targetGrade: target,
            age: age,
            isMale: isMale,
            testDate: testInDays.map { start.addingTimeInterval(Double($0) * 86_400) },
            baselineDate: start,
            now: start.addingTimeInterval(Double(daysIn) * 86_400)
        )
    }

    func testLessTimeForTheSameJumpRaisesIntensity() {
        // D → A on sit-ups is three grades, about 9 weeks at the typical rate.
        XCTAssertEqual(assess("D", "A", testInDays: 140).intensity, .standard)
        XCTAssertEqual(assess("D", "A", testInDays: 84).intensity, .push)

        let rushed = assess("D", "A", testInDays: 28)
        XCTAssertEqual(rushed.intensity, .peak)
        XCTAssertTrue(rushed.needsMoreTime)
        XCTAssertFalse(assess("D", "A", testInDays: 84).needsMoreTime)
    }

    func testIntensityDoesNotDriftUpAsAnOnTrackPlanProgresses() {
        let early = assess("D", "A", testInDays: 84)
        let later = assess("D", "A", testInDays: 84, daysIn: 56)
        XCTAssertEqual(early.intensity, later.intensity)
    }

    func testWeeklyAimClimbsFromPreviousToTargetByTestDay() throws {
        // Male 15 pull-ups: C needs 5, A needs 8; two grades is about 8 weeks.
        let firstWeek = assess("C", "A", station: .inclinedPullUps, age: 15, testInDays: 56)
        XCTAssertEqual(try XCTUnwrap(firstWeek.weeklyAim), 5 + 3.0 / 8, accuracy: 0.001)
        XCTAssertEqual(firstWeek.targetScore, 8)

        let halfway = assess("C", "A", station: .inclinedPullUps, age: 15, testInDays: 56, daysIn: 28)
        XCTAssertEqual(try XCTUnwrap(halfway.weeklyAim), 5 + 3 * 5.0 / 8, accuracy: 0.001)

        let finalWeek = assess("C", "A", station: .inclinedPullUps, age: 15, testInDays: 56, daysIn: 52)
        XCTAssertEqual(finalWeek.weeklyAim, 8)
    }

    func testPlentyOfTimeReachesTargetAtTheTypicalRateThenHolds() {
        let reached = assess("C", "A", station: .inclinedPullUps, age: 15, testInDays: 140, daysIn: 56)
        XCTAssertEqual(reached.weeklyAim, 8)
    }

    func testFasterTimesAreTheAimForTimedStations() throws {
        // Male 14 2.4 km: D is 14:10 (850 s), C is 13:00 (780 s).
        let assessment = assess("D", "C", station: .run, testInDays: 35)
        let aim = try XCTUnwrap(assessment.weeklyAim)
        XCTAssertLessThan(aim, 850)
        XCTAssertGreaterThanOrEqual(aim, 780)
    }

    func testPhaseFollowsTheDaysLeft() {
        XCTAssertEqual(assess("C", "B", testInDays: 30).phase, .build)
        XCTAssertEqual(assess("C", "B", testInDays: 14).phase, .sharpen)
        XCTAssertEqual(assess("C", "B", testInDays: 5).phase, .taper)

        let testDay = WorkoutPlanner.plan(for: assess("C", "B", testInDays: 0))
        XCTAssertEqual(testDay.map(\.name), ["NAPFA Test Today"])
    }

    func testReachedTargetMaintainsTheBetterResult() {
        let assessment = assess("B", "C", testInDays: 30)
        XCTAssertEqual(assessment.intensity, .maintenance)
        XCTAssertEqual(assessment.weeklyAim, 40) // Male 14 sit-ups B
    }

    func testPastTestDateStillPlansAtTheTypicalRate() {
        let assessment = assess("D", "B", testInDays: -3)
        XCTAssertNil(assessment.daysLeft)
        XCTAssertEqual(assessment.phase, .build)
        XCTAssertEqual(assessment.intensity, .push)
        XCTAssertNotNil(assessment.weeklyAim)
    }

    func testNotAttainedCountsAsF() {
        XCTAssertEqual(WorkoutPlanner.gradeValue("NA"), WorkoutPlanner.gradeValue("F"))
        XCTAssertEqual(assess("NA", "E", testInDays: 60).gradeGap, 1)
    }

    func testMeasuredBaselineReplacesThePreviousGrade() throws {
        // Male 15: 4 pull-ups is a D (3+), so C → A becomes a three-grade climb from 4.
        let assessment = WorkoutPlanner.assessment(
            for: .inclinedPullUps,
            previousGrade: "C",
            targetGrade: "A",
            age: 15,
            isMale: true,
            testDate: start.addingTimeInterval(84 * 86_400),
            baselineDate: start,
            measuredBaseline: 4,
            now: start
        )
        XCTAssertTrue(assessment.hasMeasuredBaseline)
        XCTAssertEqual(assessment.gradeGap, 3)
        XCTAssertEqual(try XCTUnwrap(assessment.weeklyAim), 4 + 4.0 / 12, accuracy: 0.001)
        XCTAssertFalse(assess("C", "A", testInDays: 84).hasMeasuredBaseline)
    }

    func testBaselineEntryReadsEachUnit() {
        XCTAssertEqual(BaselineEntry(amount: "13", seconds: "5").value(for: .run), 785)
        XCTAssertEqual(BaselineEntry(amount: "11,3").value(for: .shuttleRun), 11.3)
        XCTAssertEqual(BaselineEntry(amount: "0").value(for: .inclinedPullUps), 0)
        XCTAssertEqual(BaselineEntry(amount: "205").value(for: .standingBroadJump), 205)
        XCTAssertNil(BaselineEntry(amount: "").value(for: .sitUps))
        XCTAssertNil(BaselineEntry(amount: "13", seconds: "75").value(for: .run))
    }

    func testBaselineTestMatchesThePullUpVersion() throws {
        let full = try XCTUnwrap(WorkoutPlanner.baselineTest(for: .inclinedPullUps, age: 15, isMale: true).last)
        XCTAssertTrue(full.recordsBaseline)
        XCTAssertTrue(full.detail.contains("chin over the bar"))

        let inclined = try XCTUnwrap(WorkoutPlanner.baselineTest(for: .inclinedPullUps, age: 15, isMale: false).last)
        XCTAssertTrue(inclined.detail.contains("chest to the bar"))
    }

    func testDefaultTestDateIsTwelveWeeksAway() {
        let days = Calendar.current.dateComponents([.day], from: start, to: AppState.defaultNAPFADate(from: start)).day
        XCTAssertEqual(days, 84)
    }

    func testFullPullUpPlanForMales15AndUp() throws {
        let plan = WorkoutPlanner.plan(for: assess("C", "A", station: .inclinedPullUps, age: 15, testInDays: 56))
        XCTAssertTrue(plan.contains { $0.name == "Pull-up Sets" })
        let testSet = try XCTUnwrap(plan.last)
        XCTAssertTrue(testSet.detail.contains("Max pull-ups in 30 s"))
        XCTAssertTrue(testSet.detail.contains("8 reps on test day"))

        let beginner = WorkoutPlanner.plan(for: assess("F", "D", station: .inclinedPullUps, age: 15, testInDays: 56))
        XCTAssertEqual(beginner[1].name, "Negative Pull-ups")
    }

    func testFemalesKeepTheInclinedPullUpPlan() {
        let plan = WorkoutPlanner.plan(for: assess("C", "A", station: .inclinedPullUps, age: 15, isMale: false, testInDays: 56))
        XCTAssertTrue(plan.contains { $0.name == "Inclined Pull-up Sets" })
        XCTAssertFalse(plan.contains { $0.name.contains("Dead Hang") })
    }
}

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}
