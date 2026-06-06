import SwiftUI

struct Age_Gender: View {
    @Binding var start: Bool
    @Binding var info: data
    @Binding var ageFirstTime: Bool
    @Binding var ageSheet: Bool

    @State private var sex = true
    @State private var birthdate = Date()
    @State private var hasPickedBirthdate = false
    @State private var hasPickedSex = false
    @Environment(\.dismiss) private var dismiss

    private let baseStartYear = 2005
    private let baseEndYear = 2012
    private let calendar = Calendar.current

    private var age: Int {
        calendar.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
    }

    var body: some View {
        Group {
            if start {
                OnboardingStepContainer(subtitle: "Profile") {
                    profileForm
                }
            } else {
                NavigationStack {
                    Form {
                        Section {
                            AppLogoHeader(subtitle: "Profile")
                        }
                        .listRowBackground(Color.clear)

                        Section {
                            profileFields
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                saveProfile()
                                dismiss()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadProfile)
    }

    private var profileForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            profileFields
        }
        .frame(maxWidth: .infinity, minHeight: 520, alignment: .center)
    }

    @ViewBuilder
    private var profileFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("About Me")
                .font(.title3.weight(.bold))

            DatePicker(
                "Birthdate",
                selection: $birthdate,
                in: calculatedStartDate()...calculatedEndDate(),
                displayedComponents: .date
            )
            .onChange(of: birthdate) {
                hasPickedBirthdate = true
                saveProfile()
            }

            Picker("Sex", selection: sexBinding) {
                Text("Female").tag(false)
                Text("Male").tag(true)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Age")
                Spacer()
                Text("\(age)")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear {
            if start {
                hasPickedBirthdate = UserDefaults.standard.bool(forKey: AppKeys.birthdateCompleted)
                hasPickedSex = UserDefaults.standard.bool(forKey: AppKeys.genderCompleted)
            }
        }
    }

    private var sexBinding: Binding<Bool> {
        Binding {
            sex
        } set: { newValue in
            sex = newValue
            hasPickedSex = true
            info.Gender = newValue
            UserDefaults.standard.set(newValue, forKey: AppKeys.sex)
            UserDefaults.standard.set(true, forKey: AppKeys.genderCompleted)
            updateProfileCompletionFlag()
        }
    }

    private func calculatedStartDate() -> Date {
        let currentYear = calendar.component(.year, from: Date())
        let shift = currentYear - 2024
        return calendar.date(from: DateComponents(year: baseStartYear + shift, month: 1, day: 1)) ?? Date()
    }

    private func calculatedEndDate() -> Date {
        let currentYear = calendar.component(.year, from: Date())
        let shift = currentYear - 2024
        return calendar.date(from: DateComponents(year: baseEndYear + shift, month: 12, day: 31)) ?? Date()
    }

    private func loadProfile() {
        let defaults = UserDefaults.standard
        sex = defaults.object(forKey: AppKeys.sex) as? Bool ?? info.Gender
        let startDate = calculatedStartDate()
        let endDate = calculatedEndDate()
        let storedBirthdate = defaults.object(forKey: AppKeys.birthdate) as? Date ?? startDate
        birthdate = min(max(storedBirthdate, startDate), endDate)
        hasPickedBirthdate = defaults.bool(forKey: AppKeys.birthdateCompleted)
        hasPickedSex = defaults.bool(forKey: AppKeys.genderCompleted)
        saveProfile()
    }

    private func saveProfile() {
        info.Gender = sex
        info.Age = age
        UserDefaults.standard.set(sex, forKey: AppKeys.sex)
        UserDefaults.standard.set(birthdate, forKey: AppKeys.birthdate)
        UserDefaults.standard.set(age, forKey: AppKeys.age)
        if hasPickedBirthdate {
            UserDefaults.standard.set(true, forKey: AppKeys.birthdateCompleted)
        }
        if hasPickedSex {
            UserDefaults.standard.set(true, forKey: AppKeys.genderCompleted)
        }
        updateProfileCompletionFlag()
    }

    private func updateProfileCompletionFlag() {
        UserDefaults.standard.set(hasPickedBirthdate && hasPickedSex, forKey: AppKeys.profileCompleted)
    }
}

struct Age_Gender_Previews: PreviewProvider {
    static var previews: some View {
        Age_Gender(
            start: .constant(false),
            info: .constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])),
            ageFirstTime: .constant(false),
            ageSheet: .constant(false)
        )
    }
}
