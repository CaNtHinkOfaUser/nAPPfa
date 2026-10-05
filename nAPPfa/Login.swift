import SwiftUI

struct StartingPage: View {
    
    @Binding var info: data
    @Binding var ageFirstTime: Bool
    @Binding var ageSheet: Bool
    @Binding var Sex: Bool
    @Binding var Age: Int
    @Binding var goalSheet: Bool
    @Binding var schedSheet: Bool
    @Binding var selectedDays: [Int]
    @Binding var selectedTimes: [Date]
    @Binding var showLogin : Bool

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: max(20, proxy.size.height * 0.08))

                        Image("nAPPfa_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: min(132, proxy.size.width * 0.34),
                                height: min(132, proxy.size.width * 0.34)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                        VStack(spacing: 10) {
                            Text("nAPPfa")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Text("Train for all 6 NAPFA stations with nAPPfa — goals, reminders, and streaks.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }

                        NavigationLink {
                            StartingTabView(
                                info: $info,
                                ageFirstTime: $ageFirstTime,
                                ageSheet: $ageSheet,
                                Sex: $Sex,
                                Age: $Age,
                                goalSheet: $goalSheet,
                                selectedDays: $selectedDays,
                                selectedTimes: $selectedTimes,
                                schedSheet: $schedSheet,
                                showLogin: $showLogin
                            )
                        } label: {
                            Label("Get Started", systemImage: "arrow.right.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 8)

                        Spacer(minLength: 24)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollIndicators(.hidden)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
struct StartingPage_Previews: PreviewProvider {
    static var previews: some View {
        StartingPage(info:.constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])), ageFirstTime: .constant(false), ageSheet: .constant(false), Sex: .constant(false), Age: .constant(0), goalSheet: .constant(false), schedSheet: .constant(false), selectedDays: .constant([0]), selectedTimes: .constant([]), showLogin: .constant(false) )
    }
}   
