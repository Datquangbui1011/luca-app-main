


import SwiftUI

struct SignSymView: View {
    let selectedUnit: String
    let age: String
    let vitals: VitalsPayload
    
    @State private var selectedColor: String? = nil
    @State private var otherColorText: String = ""
    @State private var respiratorySelections: Set<String> = []
    @State private var abdomenSelections: Set<String> = []
    @State private var alarmSelections: Set<String> = []
    @State private var navigateToSummary = false
    
    private let colorOptions = [
        "Pink", "Pale", "Dusky", "Yellow", "Ruddy", "Bruised",
        "Mottled", "Acrocyanosis", "Other"
    ]
    
    private let respiratoryOptions = [
        "Labored", "Retractions", "Nasal Flaring", "Tachypnea", "Shallow",
        "Stridor", "Decreased Lung sounds", "Nasal Respiratory Support",
        "Increased O2 Needs", "Increased Suctioning", "Intubated"
    ]
    
    private let abdomenOptions = [
        "Soft", "Firm", "Distended", "No bowel sounds", "Loops of bowel",
        "Increased spits", "Bright green spits", "Poor feeding",
        "Bloody stool", "NG or OG tube", "Dark Abdomen"
    ]
    
    private let alarmOptions = [
        "Increased Brady HR", "Increased Tachy HR", "Increased Apnea",
        "Increased Tachypnea", "Increased Desats",
        "Increased Bed Alarms", "Increased Vent Alarms"
    ]
    
    private var isOtherSelected: Bool { (selectedColor ?? "").lowercased() == "other" }
    
    private var isFormValid: Bool {
        (selectedColor != nil) ||
        !respiratorySelections.isEmpty ||
        !abdomenSelections.isEmpty ||
        !alarmSelections.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5E8C7").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 45))
                            .foregroundColor(Color(hex: "D9B53E"))
                        Text("Signs & Symptoms")
                            .font(.system(size: 26, weight: .bold))
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        // COLOR
                        CollapsibleCard(title: "Color", systemImage: "paintpalette.fill") {
                            VStack(spacing: 8) {
                                ForEach(colorOptions, id: \.self) { option in
                                    SingleSelectRow(
                                        title: option,
                                        isSelected: selectedColor == option
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedColor = option
                                            if option.lowercased() != "other" { otherColorText = "" }
                                        }
                                    }
                                }
                                
                                if isOtherSelected {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Specify other")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Type color/description…", text: $otherColorText)
                                            .font(.system(size: 16))
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // RESPIRATORY
                        CollapsibleCard(title: "Respiratory", systemImage: "lungs.fill") {
                            VStack(spacing: 8) {
                                ForEach(respiratoryOptions, id: \.self) { option in
                                    MultiSelectRow(
                                        title: option,
                                        isOn: respiratorySelections.contains(option)
                                    ) {
                                        toggle(option, in: &respiratorySelections)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // ABDOMEN
                        CollapsibleCard(title: "Abdomen", systemImage: "figure.wave") {
                            VStack(spacing: 8) {
                                ForEach(abdomenOptions, id: \.self) { option in
                                    MultiSelectRow(
                                        title: option,
                                        isOn: abdomenSelections.contains(option)
                                    ) {
                                        toggle(option, in: &abdomenSelections)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // ALARMS
                        CollapsibleCard(title: "Alarms", systemImage: "bell.badge.fill") {
                            VStack(spacing: 8) {
                                ForEach(alarmOptions, id: \.self) { option in
                                    MultiSelectRow(
                                        title: option,
                                        isOn: alarmSelections.contains(option)
                                    ) {
                                        toggle(option, in: &alarmSelections)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Next button
                    Button {
                        navigateToSummary = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 56)
                        .background(Color(hex: "D9B53E"))
                        .cornerRadius(30)
                        .shadow(
                            color: isFormValid ? Color(hex: "D9B53E").opacity(0.3) : .clear,
                            radius: 8,
                            y: 4
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .padding(.bottom, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "F5E8C7"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(
            NavigationLink(
                destination: SummaryView(
                    unit: selectedUnit,
                    age: age,
                    vitals: vitals,
                    color: displayColor(),
                    respiratory: respiratorySelections.sorted(),
                    abdomen: abdomenSelections.sorted(),
                    alarms: alarmSelections.sorted()
                ),
                isActive: $navigateToSummary
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    // MARK: - Helpers
    private func toggle(_ item: String, in set: inout Set<String>) {
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }
    
    private func displayColor() -> String {
        guard let selected = selectedColor else { return "—" }
        if selected.lowercased() == "other" {
            return otherColorText.isEmpty ? "Other" : "Other: \(otherColorText)"
        } else {
            return selected
        }
    }
}

// MARK: - Collapsible Card Shell
private struct CollapsibleCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content   // store the built content view
    
    @State private var isExpanded = false
    
    // Custom initializer so you can use trailing closure syntax
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 10) {
                        content
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            } label: {
                                Text("Save & Close")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "D9B53E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 8)
                },
                label: {
                    HStack(spacing: 10) {
                        Image(systemName: systemImage)
                            .foregroundColor(Color(hex: "D9B53E"))
                        Text(title)
                            .font(.headline)
                        Spacer()
                    }
                }
            )
            .tint(.black)
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 3)
        .padding(.horizontal, 20)
    }
}

// MARK: - Single Select Row (Color)
private struct SingleSelectRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "D9B53E"))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Multi Select Row
private struct MultiSelectRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn ? Color(hex: "D9B53E") : .secondary)
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct SummaryStubView: View {
    let color: String
    let respiratory: [String]
    let abdomen: [String]
    let alarms: [String]
    
    var body: some View {
        List {
            Section("Color") { Text(color) }
            Section("Respiratory") {
                ForEach(respiratory, id: \.self, content: Text.init)
            }
            Section("Abdomen") {
                ForEach(abdomen, id: \.self, content: Text.init)
            }
            Section("Alarms") {
                ForEach(alarms, id: \.self, content: Text.init)
            }
        }
        .navigationTitle("Summary (Stub)")
    }
}
