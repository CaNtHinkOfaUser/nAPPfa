//
//  CustomTabBar.swift
//  Napha Training App
//
//  Created by Alvarez Marco Lorenzo Tanzon on 19/8/24.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case house = "house"
    case dumbbell = "dumbbell"
    case progression = "chart.line.uptrend.xyaxis"
    case gearshape = "gearshape"

    var title: String {
        switch self {
        case .house: return "Home"
        case .dumbbell: return "Workout"
        case .progression: return "Progress"
        case .gearshape: return "Settings"
        }
    }

    var selectedSymbol: String {
        switch self {
        case .house: return "house.fill"
        case .dumbbell: return "dumbbell.fill"
        case .progression: return "chart.line.uptrend.xyaxis"
        case .gearshape: return "gearshape.fill"
        }
    }

    var tint: Color {
        switch self {
        case .house: return .blue
        case .dumbbell: return .red
        case .progression: return .green
        case .gearshape: return .gray
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

	var body: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.selectedSymbol : tab.rawValue)
                            .font(.system(size: tab == .dumbbell ? 26 : 22, weight: .semibold))
                            .frame(width: 44, height: 32)
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundColor(selectedTab == tab ? tab.tint : .secondary)
                    .contentShape(Rectangle())
                    .accessibilityLabel(tab.title)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
		.symbolEffect(.drawOn)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.house))
}
