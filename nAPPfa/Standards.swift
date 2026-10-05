//
//  Standards.swift
//  nAPPfa
//

import SwiftUI

struct NAPFAStandardRow: Identifiable {
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

private struct StandardColumn: Identifiable {
	var id: String { title }
	let title: String
	/// Natural width; all columns grow or shrink together to fit the screen.
	let width: CGFloat
	let value: (NAPFAStandardRow) -> String
	
	init(title: String, width: CGFloat, value: KeyPath<NAPFAStandardRow, String>) {
		self.title = title
		self.width = width
		self.value = { row in row[keyPath: value] }
	}
}

struct NAPFAStandardsView: View {
	enum Scope: String, CaseIterable, Identifiable {
		case mine = "My selection"
		case all = "All data"
		
		var id: String { rawValue }
	}
	
	let isMale: Bool
	let age: Int
	/// Stations ticked in Goals. My selection shows only these, or all six when none are ticked.
	let stations: [NAPFAStation]
	@Environment(\.dismiss) private var dismiss
	@State private var scope = Scope.mine
	@State private var showsMaleTable: Bool
	@State private var zoom: CGFloat = 1
	@GestureState private var pinch: CGFloat = 1
	@ScaledMetric(relativeTo: .caption) private var baseFontSize: CGFloat = 12
	
	private static let zoomRange: ClosedRange<CGFloat> = 0.6...2.5
	
	init(isMale: Bool, age: Int, stations: [NAPFAStation]) {
		self.isMale = isMale
		self.age = age
		self.stations = stations
		_showsMaleTable = State(initialValue: isMale)
	}
	
	private var tableIsMale: Bool {
		scope == .mine ? isMale : showsMaleTable
	}
	
	/// Zoom while a pinch is in progress, kept inside the allowed range.
	private var liveZoom: CGFloat {
		Self.clampedZoom(zoom * pinch)
	}
	
	/// The secondary tables cover ages 12 to 19.
	private var tableAge: Int {
		min(max(age, 12), 19)
	}
	
	private var rows: [NAPFAStandardRow] {
		let allRows = tableIsMale ? Self.maleRows : Self.femaleRows
		return scope == .mine ? rowsForAge(String(tableAge), in: allRows) : allRows
	}
	
	private var columns: [StandardColumn] {
		var columns: [StandardColumn] = []
		if scope == .all {
			columns.append(StandardColumn(title: "Age", width: 48, value: \.age))
		}
		columns.append(StandardColumn(title: "Grade", width: 56, value: \.grade))
		columns.append(StandardColumn(title: "Points", width: 56, value: \.points))
		
		// Males switch to full pull-ups at 15; females do inclined pull-ups at every age.
		// The full male table covers both, so it names both.
		let pullUpTitle: String
		if tableIsMale && scope == .all {
			pullUpTitle = "Pull-ups (15+) / Inclined (≤14) in 30 sec"
		} else if NAPFAStation.inclinedPullUps.isFullPullUp(age: tableAge, isMale: tableIsMale) {
			pullUpTitle = "Pull-ups in 30 sec"
		} else {
			pullUpTitle = "Inclined Pull-ups in 30 sec"
		}
		
		let stationColumns: [(NAPFAStation, StandardColumn)] = [
			(.sitUps, StandardColumn(title: "Sit-ups in 1 min", width: 88, value: \.sitUps)),
			(.standingBroadJump, StandardColumn(title: "Standing Broad Jump", width: 100, value: \.jump)),
			(.sitAndReach, StandardColumn(title: "Sit & Reach Distance", width: 96, value: \.reach)),
			(.inclinedPullUps, StandardColumn(title: pullUpTitle, width: 112, value: \.pullUps)),
			(.shuttleRun, StandardColumn(title: "4 x 10m Shuttle Run Time", width: 108, value: \.shuttle)),
			(.run, StandardColumn(title: "2.4 km Run-Walk Time", width: 112, value: \.run))
		]
		let shown = scope == .mine && !stations.isEmpty ? stationColumns.filter { stations.contains($0.0) } : stationColumns
		columns.append(contentsOf: shown.map(\.1))
		return columns
	}
	
	private var caption: String {
		let sex = tableIsMale ? "Males" : "Females"
		switch scope {
		case .mine:
			return "\(sex), age \(tableAge) · \(stations.isEmpty ? "all stations" : "your stations")"
		case .all:
			return "\(sex), ages 12–19 · all stations"
		}
	}
	
	var body: some View {
		GeometryReader { geometry in
			let available = max(geometry.size.width - 36, 0)
			let widths = columnWidths(fitting: available)
			let fits = widths.reduce(0, +) <= available + 1
			
			ScrollView {
				VStack(alignment: .leading, spacing: 14) {
					Picker("Show", selection: $scope) {
						ForEach(Scope.allCases) { scope in
							Text(scope.rawValue).tag(scope)
						}
					}
					.pickerStyle(.segmented)
					
					if scope == .all {
						Picker("Table", selection: $showsMaleTable) {
							Text("Male").tag(true)
							Text("Female").tag(false)
						}
						.pickerStyle(.segmented)
					}
					
					HStack(spacing: 16) {
						Text(caption)
							.font(.subheadline)
							.foregroundStyle(.secondary)
						Spacer(minLength: 0)
						Button {
							setZoom(zoom / 1.25)
						} label: {
							Image(systemName: "minus.magnifyingglass")
						}
						.disabled(zoom <= Self.zoomRange.lowerBound)
						.accessibilityLabel("Zoom out")
						Button {
							setZoom(zoom * 1.25)
						} label: {
							Image(systemName: "plus.magnifyingglass")
						}
						.disabled(zoom >= Self.zoomRange.upperBound)
						.accessibilityLabel("Zoom in")
					}
					.font(.title3)
					
					ScrollView(.horizontal, showsIndicators: !fits) {
						table(widths: widths, zoom: liveZoom)
					}
					.scrollDisabled(fits)
					// Pinch to zoom; simultaneous so one-finger scrolling still works.
					.simultaneousGesture(
						MagnifyGesture()
							.updating($pinch) { value, pinch, _ in
								pinch = value.magnification
							}
							.onEnded { value in
								zoom = Self.clampedZoom(zoom * value.magnification)
							}
					)
				}
				.padding(18)
			}
		}
		.onChange(of: scope) {
			zoom = 1
		}
		.background(Color(.systemGroupedBackground))
		.navigationTitle("NAPFA Standards")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Done") { dismiss() }
					.fontWeight(.semibold)
			}
		}
	}
	
	/// Scales every column by the same factor so the table fills the width of whatever
	/// screen it is on, then applies the zoom. Before zooming, columns never shrink below
	/// 70% of their natural width; past that the table scrolls sideways instead of
	/// squashing the text.
	private func columnWidths(fitting available: CGFloat) -> [CGFloat] {
		let natural = columns.map(\.width)
		let total = natural.reduce(0, +)
		guard total > 0, available > 0 else { return natural }
		let scale = max(available / total, 0.7) * liveZoom
		return natural.map { $0 * scale }
	}
	
	private static func clampedZoom(_ zoom: CGFloat) -> CGFloat {
		min(max(zoom, zoomRange.lowerBound), zoomRange.upperBound)
	}
	
	private func setZoom(_ newZoom: CGFloat) {
		withAnimation(.snappy(duration: 0.25)) {
			zoom = Self.clampedZoom(newZoom)
		}
	}
	
	private func table(widths: [CGFloat], zoom: CGFloat) -> some View {
		let columns = columns
		let rows = rows
		let groups = ageGroups(of: rows)
		
		return VStack(spacing: 0) {
			HStack(spacing: 0) {
				ForEach(columns.indices, id: \.self) { index in
					cell(columns[index].title, width: widths[index], zoom: zoom, isHeader: true)
				}
			}
			ForEach(rows.indices, id: \.self) { rowIndex in
				HStack(spacing: 0) {
					ForEach(columns.indices, id: \.self) { index in
						cell(columns[index].value(rows[rowIndex]), width: widths[index], zoom: zoom, isShaded: groups[rowIndex] % 2 == 1)
					}
				}
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
		.overlay {
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.stroke(Color.primary.opacity(0.25), lineWidth: 1)
		}
	}
	
	/// Which age block each row is in, so alternate ages can be shaded in the full table.
	private func ageGroups(of rows: [NAPFAStandardRow]) -> [Int] {
		var group = 0
		return rows.enumerated().map { index, row in
			if index > 0 && !row.age.isEmpty { group += 1 }
			return group
		}
	}
	
	private func cell(_ text: String, width: CGFloat, zoom: CGFloat, isHeader: Bool = false, isShaded: Bool = false) -> some View {
		Text(text)
			.font(.system(size: baseFontSize * zoom, weight: isHeader ? .bold : .regular))
			.multilineTextAlignment(.center)
			.lineLimit(3)
			.minimumScaleFactor(0.72)
			.padding(.horizontal, 4 * zoom)
			.frame(width: width)
			.frame(minHeight: (isHeader ? 58 : 30) * zoom)
			.background(isHeader || isShaded ? Color(.tertiarySystemGroupedBackground) : Color(.secondarySystemGroupedBackground))
			.border(Color.primary.opacity(0.15), width: 0.5)
	}
	
	private static func row(_ age: String, _ grade: String, _ points: String, _ sitUps: String, _ jump: String, _ reach: String, _ pullUps: String, _ shuttle: String, _ run: String) -> NAPFAStandardRow {
		NAPFAStandardRow(age: age, grade: grade, points: points, sitUps: sitUps, jump: jump, reach: reach, pullUps: pullUps, shuttle: shuttle, run: run)
	}
	
	private func rowsForAge(_ targetAge: String, in allRows: [NAPFAStandardRow]) -> [NAPFAStandardRow] {
		var matchedRows: [NAPFAStandardRow] = []
		var isCollecting = false
		
		for row in allRows {
			if !row.age.isEmpty {
				isCollecting = row.age == targetAge
			}
			if isCollecting {
				matchedRows.append(row)
			}
		}
		
		return matchedRows.isEmpty ? allRows : matchedRows
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
	NavigationStack {
		NAPFAStandardsView(isMale: true, age: 15, stations: [.sitUps, .inclinedPullUps])
	}
}
