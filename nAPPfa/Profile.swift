//import SwiftUI
//
//struct Profile: View {
//    @Binding var start: Bool
//    @Binding var info: data
//    @State var Sex = true // Default to Male
//    @State var birthdate = Date() // Default to today's date
//    @Binding var ageFirstTime: Bool
//    @Binding var ageSheet: Bool
//    @State var GenderSheet = false
//    @State private var selectedDate = Date()
//
//    @State private var userName: String = "" // Name input
//    @State private var profileImage: UIImage? // Profile picture
//    @State private var showImagePicker = false
//    
//    let baseStartYear = 2005
//    let baseEndYear = 2012
//    let calendar = Calendar.current
//    @Environment(\.dismiss) private var dismiss
//
//    func calculatedStartDate() -> Date {
//        let currentYear = calendar.component(.year, from: Date())
//        let shift = currentYear - 2024 // Calculate the difference between current year and 2024 (base year)
//        return calendar.date(from: DateComponents(year: baseStartYear + shift, month: 1, day: 1)) ?? Date()
//    }
//
//    func calculatedEndDate() -> Date {
//        let currentYear = calendar.component(.year, from: Date())
//        let shift = currentYear - 2024 // Calculate the difference between current year and 2024
//        return calendar.date(from: DateComponents(year: baseEndYear + shift, month: 12, day: 31)) ?? Date()
//    }
//
//    var dateFormatter: DateFormatter = {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .medium
//        return dateFormatter
//    }()
//    
//    var age: Int {
//        let calendar = Calendar.current
//        let now = Date()
//        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: now)
//        return ageComponents.year ?? 0
//    }
//
//    var body: some View {
//        VStack(alignment: .leading) {
//
//            Text("Profile")
//                .font(.title)
//                .bold()
//                .padding(.bottom)
//                .offset(x: 20)
//                .offset(x: 10)
//
//            // Profile Image and Name Section
//            VStack {
//                // Profile picture picker
//                Button(action: {
//                    showImagePicker.toggle()
//                }) {
//                    if let image = profileImage {
//                        Image(uiImage: image)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 100, height: 100)
//                            .clipShape(Circle())
//                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
//                            .padding(.bottom)
//                    } else {
//                        Image(systemName: "person.crop.circle.fill")
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 100, height: 100)
//                            .foregroundColor(.blue)
//                            .padding(.bottom)
//                    }
//                }
//                .sheet(isPresented: $showImagePicker) {
//                    ImagePicker(image: $profileImage)
//                }
//                
//                // Name input field
//                TextField("Enter your name", text: $userName)
//                    .padding()
//                    .background(Color.gray.opacity(0.2))
//                    .cornerRadius(8)
//                    .padding(.horizontal)
//            }
//            .padding(.bottom)
//            
//            Form {
//                // Birthdate picker
//                DatePicker("Birthdate", selection: $birthdate, in: calculatedStartDate()...calculatedEndDate(), displayedComponents: .date)
//                    .onChange(of: birthdate) { _ in
//                        let calculatedAge = age
//                        UserDefaults.standard.setValue(birthdate, forKey: "birthdate")
//                        UserDefaults.standard.setValue(calculatedAge, forKey: "age")
//                    }
//                    .onAppear {
//                        selectedDate = calculatedStartDate()
//                    }
//
//                // Gender selection
//                HStack {
//                    Text("Sex:")
//                    Spacer()
//                    Button(action: {
//                        GenderSheet.toggle()
//                    }) {
//                        Text(info.Gender ? "Male" : "Female")
//                            .foregroundColor(.black)
//                    }
//                    .sheet(isPresented: $GenderSheet) {
//                        GenderSelectionView(info: $info, sex: $Sex)
//                            .presentationDetents([.fraction(0.45)])
//                            .presentationDragIndicator(.visible)
//                    }
//                    .labelsHidden()
//                    .tint(.black)
//                    .offset(x: -10)
//                }
//
//                // Save button
//                if (!start) {
//                    Button {
//                        dismiss()
//                    } label: {
//                        Text("Save")
//                            .foregroundStyle(.blue)
//                    }
//                }
//            }
//            .onAppear {
//                // Load stored data if it exists
//                if let storedSex = UserDefaults.standard.object(forKey: "sex") as? Bool {
//                    Sex = storedSex
//                }
//                if let storedBirthdate = UserDefaults.standard.object(forKey: "birthdate") as? Date {
//                    birthdate = storedBirthdate
//                }
//                if let storedName = UserDefaults.standard.string(forKey: "name") {
//                    userName = storedName
//                }
//                if let savedImage = loadProfileImage() {
//                    profileImage = savedImage
//                }
//                
//                // Store birthdate and sex on appear
//                UserDefaults.standard.setValue(birthdate, forKey: "birthdate")
//                UserDefaults.standard.setValue(Sex, forKey: "sex")
//                UserDefaults.standard.setValue(userName, forKey: "name")
//                
//                let calculatedAge = age
//                UserDefaults.standard.setValue(calculatedAge, forKey: "age")
//            }
//        }
//    }
//
//    // Function to save and load the profile image from UserDefaults
//    func loadProfileImage() -> UIImage? {
//        if let imageData = UserDefaults.standard.data(forKey: "profileImage") {
//            return UIImage(data: imageData)
//        }
//        return nil
//    }
//
//    func saveProfileImage(_ image: UIImage) {
//        if let imageData = image.jpegData(compressionQuality: 1.0) {
//            UserDefaults.standard.setValue(imageData, forKey: "profileImage")
//        }
//    }
//}
//
//// Image Picker for Profile Picture
//struct ImagePicker: UIViewControllerRepresentable {
//    @Binding var image: UIImage?
//
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let parent: ImagePicker
//
//        init(parent: ImagePicker) {
//            self.parent = parent
//        }
//
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            if let uiImage = info[.originalImage] as? UIImage {
//                parent.image = uiImage
//                parent.saveProfileImage(uiImage) // Save selected image
//            }
//            picker.dismiss(animated: true)
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//
//    // Helper function to save the profile image from here
//    func saveProfileImage(_ image: UIImage) {
//        if let imageData = image.jpegData(compressionQuality: 1.0) {
//            UserDefaults.standard.setValue(imageData, forKey: "profileImage")
//        }
//    }
//}
//
//// The existing Gender Selection view remains the same
//struct GenderSelectionView: View {
//    @Binding var info: data
//    @Environment(\.presentationMode) var presentationMode
//    @State private var selectedGender: String? = "Male"
//    @Binding var sex: Bool
//
//    var body: some View {
//        VStack {
//            Text("Your sex")
//                .font(.headline)
//            Divider()
//
//            HStack {
//                GenderButton(gender: "Female", selectedGender: $selectedGender)
//                    .onChange(of: selectedGender) {
//                        if selectedGender == "Female" {
//                            sex = false
//                            info.Gender = false
//                        } else {
//                            sex = true
//                            info.Gender = true
//                        }
//                    }
//
//                GenderButton(gender: "Male", selectedGender: $selectedGender)
//                    .onChange(of: selectedGender) {
//                        if selectedGender == "Female" {
//                            sex = false
//                            info.Gender = false
//                        } else {
//                            sex = true
//                            info.Gender = true
//                        }
//                    }
//            }
//            .padding(.vertical)
//
//            Button {
//                if selectedGender == "Male" {
//                    info.Gender = true
//                    sex = true
//                } else if selectedGender == "Female" {
//                    info.Gender = false
//                    sex = false
//                }
//            } label: {
//            }
//            Button {
//                presentationMode.wrappedValue.dismiss()
//            } label: {
//                Text("Save")
//                    .foregroundStyle(.white)
//                    .font(.headline)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(20)
//                    .padding(.horizontal)
//                    .padding(.bottom)
//                    .background(Color.white)
//                    .cornerRadius(20)
//                    .padding(.horizontal)
//            }
//        }
//    }
//}
//
//
//struct GenderButton: View {
//    var gender: String
//    @Binding var selectedGender: String?
//    
//    var isSelected: Bool {
//        selectedGender == gender
//    }
//    
//    var body: some View {
//        Button(action: {
//            withAnimation {
//                selectedGender = gender
//            }
//        }) {
//            VStack {
//                Image(systemName: isSelected ? "person.fill" : "person")
//                    .font(.system(size: 40))
//                    .foregroundColor(isSelected ? .white : .
//blue)
//                Text(gender)
//                    .font(.headline)
//                    .foregroundStyle(isSelected ? .white : .blue)
//            }
//            .padding()
//            .frame(width: 155, height: 100)
//            .background(isSelected ? Color.blue : Color.white)
//            .cornerRadius(10)
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(Color.blue, lineWidth: 2)
//            )
//        }
//    }
//}
//
//struct Profile_Preview: PreviewProvider {
//    static var previews: some View {
//
//
//        Age_Gender(start: .constant(false), info:.constant(data(Age: 0, Gender: false, prev: [], targ: [], schedule: [], NAPFA_Date: Date.now, Goals: [])), ageFirstTime: .constant(false), ageSheet: .constant(false))
//
//    }
//}
//
