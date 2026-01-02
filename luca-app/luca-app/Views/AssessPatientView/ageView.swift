import SwiftUI

struct ageView: View {
    let selectedUnit: String
    @State private var age = ""
    @State private var selectedGestationalWeeks = ""
    @State private var navigateToVital = false

    let gestationalOptions = ["24.0 - 29.9 weeks", "30.0 - 35.9 weeks", "36.0+ weeks"]
    let ageRanges = ["0-1 years", "1-3 years", "3-12 years", "12-18 years", "18-65 years", "65+ years"]
    
    var isNICU: Bool { selectedUnit == "NICU" }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: isNICU ? "figure.and.child.holdinghands" : "person.fill")
                    .font(.system(size: 55))
                    .foregroundColor(Color(hex: "D9B53E"))
                
                Text(isNICU ? "Current Gestational Age" : "Patient Age")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Selection grid
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    if isNICU {
                        ForEach(gestationalOptions, id: \.self) { option in
                            AgeCard(ageText: option, isSelected: selectedGestationalWeeks == option) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedGestationalWeeks = option
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        navigateToVital = true
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(ageRanges, id: \.self) { range in
                            AgeCard(ageText: range, isSelected: age == range) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    age = range
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        navigateToVital = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            Spacer()
        }
        .background(Color(hex: "F5E8C7").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        // Use a hidden NavigationLink (isActive) to push while keeping the TabView visible
        .background(
            NavigationLink(
                destination: VitalView(selectedUnit: selectedUnit, age: isNICU ? selectedGestationalWeeks : age),
                isActive: $navigateToVital
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
}

struct AgeCard: View {
    let ageText: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 38))
                    .foregroundColor(isSelected ? Color(hex: "D9B53E") : .gray.opacity(0.6))
                Text(ageText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: "D9B53E"))
                        .transition(.scale)
                }
            }
            .frame(maxWidth: 160)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color(hex: "D9B53E").opacity(0.15) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color(hex: "D9B53E") : Color.gray.opacity(0.25), lineWidth: isSelected ? 2.5 : 1.5)
            )
            .shadow(color: isSelected ? Color(hex: "D9B53E").opacity(0.25) : .black.opacity(0.05), radius: isSelected ? 10 : 4, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
