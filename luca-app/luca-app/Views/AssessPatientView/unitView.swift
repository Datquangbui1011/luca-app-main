import SwiftUI

struct unitView: View {
    @State private var selectedUnit = ""
    
    let units = ["NICU", "ICU", "Emergency", "Surgery", "Pediatrics", "Cardiac"]
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

// MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "D9B53E"))
                    
                    Text("Select Unit")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(units, id: \.self) { unit in
                        // Only NICU is functional for now
                        if unit == "NICU" {
                            NavigationLink(destination: ageView(selectedUnit: unit)) {
                                UnitCardContent(unitName: unit, isSelected: selectedUnit == unit)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedUnit = unit
                                }
                            }
                            )
                        } else {
                            UnitCardContent(unitName: unit, isSelected: selectedUnit == unit)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedUnit = unit
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                Spacer().frame(height: 40)
            }
        }
        .background(Color(hex: "F5E8C7").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

}

// MARK: - Unit Card Content
struct UnitCardContent: View {
    let unitName: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconForUnit(unitName))
                .font(.system(size: 38))
                .foregroundColor(
                    unitName == "NICU"
                        ? (isSelected ? Color.blue : Color.blue.opacity(0.5))
                        : (isSelected ? Color(hex: "D9B53E") : .gray.opacity(0.6))
                )

            
            Text(unitName)
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
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? Color(hex: "D9B53E").opacity(0.15) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isSelected ? Color(hex: "D9B53E") : Color.gray.opacity(0.25),
                    lineWidth: isSelected ? 2.5 : 1.5
                )
        )
        .shadow(
            color: isSelected ? Color(hex: "D9B53E").opacity(0.25) : .black.opacity(0.05),
            radius: isSelected ? 10 : 4,
            y: 3
        )
    }
    
    private func iconForUnit(_ unit: String) -> String {
        switch unit {
        case "NICU":
            return "teddybear.fill"
        case "ICU":
            return "cross.case.fill"
        case "Emergency":
            return "bolt.heart.fill"
        case "Surgery":
            return "cross.vial.fill"
        case "Pediatrics":
            return "figure.2.and.child.holdinghands"
        case "Cardiac":
            return "heart.text.square.fill"
        default:
            return "stethoscope"
        }
    }
}

// MARK: - Unit Card Component (keep for backwards compatibility)
struct UnitCard: View {
    let unitName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            UnitCardContent(unitName: unitName, isSelected: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        unitView()
    }
}
