import SwiftUI

struct Age_Gender: View {
    @Binding var start: Bool
    @Binding var info: data
    @Binding var ageFirstTime: Bool
    @Binding var ageSheet: Bool

    @State private var sex = true
    @State private var birthdate: Date?
    @State private var hasPickedBirthdate = false
    @State private var hasPickedSex = false
    @Environment(\.dismiss) private var dismiss

    /// Snapshot of persisted values captured on appear, used to restore when Cancel is tapped.
    @State private var savedSex: Bool = true
    @State private var savedBirthdate: Date?
    @State private var savedHasPickedBirthdate = false
    @State private var savedHasPickedSex = false

    private let baseStartYear = 2005
    private let baseEndYear = 2012
    private let calendar = Calendar.current

    private var age: Int {
        guard let birthdate else { return 0 }
        return calendar.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
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
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                revertProfile()
                                dismiss()
                            }
                        }
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

            VStack(alignment: .leading, spacing: 6) {
                DatePicker(
                    "Birthdate",
                    selection: Binding(
                        get: { birthdate ?? calculatedEndDate() },
                        set: { newValue in
                            self.birthdate = newValue
                            hasPickedBirthdate = true
                            persistOnboardingProfileIfNeeded()
                        }
                    ),
                    in: calculatedStartDate()...calculatedEndDate(),
                    displayedComponents: .date
                )

                if age > 0 {
                    Text("Age: \(age)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Sex:")

                HStack(spacing: 12) {
                    GenderButton(gender: "Female", selectedGender: genderSelection)
                    GenderButton(gender: "Male", selectedGender: genderSelection)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear {
            if start {
                hasPickedBirthdate = UserDefaults.standard.bool(forKey: AppKeys.birthdateCompleted)
                hasPickedSex = UserDefaults.standard.bool(forKey: AppKeys.genderCompleted)
            }
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
        if let storedBirthdate = defaults.object(forKey: AppKeys.birthdate) as? Date {
            let startDate = calculatedStartDate()
            let endDate = calculatedEndDate()
            birthdate = min(max(storedBirthdate, startDate), endDate)
        }

        hasPickedBirthdate = defaults.bool(forKey: AppKeys.birthdateCompleted)
        hasPickedSex = defaults.bool(forKey: AppKeys.genderCompleted)

        // Snapshot for Cancel.
        savedSex = sex
        savedBirthdate = birthdate
        savedHasPickedBirthdate = hasPickedBirthdate
        savedHasPickedSex = hasPickedSex
    }

    private func saveProfile() {
        info.Gender = sex
        info.Age = age
        UserDefaults.standard.set(sex, forKey: AppKeys.sex)
        if let birthdate {
            UserDefaults.standard.set(birthdate, forKey: AppKeys.birthdate)
            UserDefaults.standard.set(age, forKey: AppKeys.age)
        }
        if hasPickedBirthdate {
            UserDefaults.standard.set(true, forKey: AppKeys.birthdateCompleted)
        }
        if hasPickedSex {
            UserDefaults.standard.set(true, forKey: AppKeys.genderCompleted)
        }
        updateProfileCompletionFlag()
    }

    private func persistOnboardingProfileIfNeeded() {
        guard start else { return }
        saveProfile()
    }

    private var genderSelection: Binding<String?> {
        Binding {
            sex ? "Male" : "Female"
        } set: { selectedGender in
            guard let selectedGender else { return }
            sex = selectedGender == "Male"
            info.Gender = sex
            hasPickedSex = true
            persistOnboardingProfileIfNeeded()
        }
    }

    /// Restore the on-screen state to the persisted snapshot, discarding in-flight edits.
    private func revertProfile() {
        sex = savedSex
        birthdate = savedBirthdate
        hasPickedBirthdate = savedHasPickedBirthdate
        hasPickedSex = savedHasPickedSex
        info.Gender = savedSex

        // Re-publish saved values to UserDefaults so anything that reacted to
        // live edits (e.g. info bindings) rolls back too.
        if let savedBirthdate {
            UserDefaults.standard.set(savedBirthdate, forKey: AppKeys.birthdate)
        }
        UserDefaults.standard.set(savedSex, forKey: AppKeys.sex)
    }

    private func updateProfileCompletionFlag() {
        UserDefaults.standard.set(hasPickedBirthdate && hasPickedSex, forKey: AppKeys.profileCompleted)
    }
}

struct GenderSelectionView: View {
    @Binding var info: data
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedGender: String? = "Male"
    @Binding var sex: Bool

    var body: some View {
        VStack {
            Text("Your sex")
                .font(.headline)
            Divider()

            HStack {
                GenderButton(gender: "Female", selectedGender: $selectedGender)
                    .onChange(of: selectedGender) {
                        if selectedGender == "Female" {
                            sex = false
                            info.Gender = false
                        } else {
                            sex = true
                            info.Gender = true
                        }
                    }

                GenderButton(gender: "Male", selectedGender: $selectedGender)
                    .onChange(of: selectedGender) {
                        if selectedGender == "Female" {
                            sex = false
                            info.Gender = false
                        } else {
                            sex = true
                            info.Gender = true
                        }
                    }
            }
            .padding(.vertical)

            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Save")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
            }
        }
        .onAppear {
            selectedGender = sex ? "Male" : "Female"
        }
    }
}

struct GenderButton: View {
    var gender: String
    @Binding var selectedGender: String?

    var isSelected: Bool {
        selectedGender == gender
    }

    var body: some View {
        Button(action: {
            withAnimation {
                selectedGender = gender
            }
        }) {
            VStack {
                Image(systemName: isSelected ? "person.fill" : "person")
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)

                Text(gender)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(isSelected ? Color.blue : Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 2)
            )
        }
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
