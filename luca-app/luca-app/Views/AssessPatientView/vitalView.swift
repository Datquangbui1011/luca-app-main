//
//  VitalView.swift
//  luca-app
//
//  Created by Đạt Bùi on 10/30/25.
//

import SwiftUI

struct VitalsPayload {
    let heartRate: String
    let bloodPressure: String
    let temperature: String
    let respiratoryRate: String
    let oxygenSaturation: String
}

struct VitalView: View {
    @State private var heartRateTouched = false
    @State private var mapTouched = false
    @State private var respTouched = false
    @State private var o2Touched = false

    let selectedUnit: String
    let age: String
    
    @State private var heartRate = ""
    @State private var bloodPressure = ""
    @State private var temperature = ""
    @State private var respiratoryRate = ""
    @State private var oxygenSaturation = ""
    @State private var navigateToNext = false
    
    private func parseDouble(_ s: String) -> Double? {
        guard !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return Double(s.replacingOccurrences(of: ",", with: "."))
    }
    
    private func tempInCelsius(_ s: String) -> Double? {
        guard let n = parseDouble(s) else { return nil }
        return n < 70 ? n : (n - 32.0) * 5.0 / 9.0
    }
    
    private struct RangeSpec { let min: Double; let max: Double }
    
    private func outOfRangeMessage(
        rawText: String,
        numeric: Double?,
        allowed: RangeSpec
    ) -> String? {
        guard let v = numeric else { return nil }
        guard !rawText.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        if v < allowed.min || v > allowed.max {
            return "Did you mean \(rawText)? If yes, contact your doctor immediately."
        }
        return nil
    }
    
    private var tempRangeC: RangeSpec { .init(min: 36.4, max: 38.0) }
    private var heartRateRange: RangeSpec { .init(min: 70, max: 180) }
    private var respRateRange: RangeSpec { .init(min: 20, max: 80) }
    private var o2RangePct: RangeSpec { .init(min: 85, max: 100) }
    
    private func mapRangeForAge(_ ageText: String) -> RangeSpec? {
        let lower = ageText.lowercased()
        if lower.contains("24.0 - 29.9") {
            return .init(min: 24, max: 40)
        } else if lower.contains("30.0 - 35.9") {
            return .init(min: 30, max: 45)
        } else if lower.contains("36+")
                    || lower.contains("36.0+") {
            return .init(min: 35, max: 50)
        }
        return nil
    }
    
    private var tempWarning: String? {
        outOfRangeMessage(
            rawText: temperature,
            numeric: tempInCelsius(temperature),
            allowed: tempRangeC
        )
    }
    
    private var heartRateWarning: String? {
        outOfRangeMessage(
            rawText: heartRate,
            numeric: parseDouble(heartRate),
            allowed: heartRateRange
        )
    }
    
    private var respWarning: String? {
        outOfRangeMessage(
            rawText: respiratoryRate,
            numeric: parseDouble(respiratoryRate),
            allowed: respRateRange
        )
    }
    
    private var o2Warning: String? {
        outOfRangeMessage(
            rawText: oxygenSaturation,
            numeric: parseDouble(oxygenSaturation),
            allowed: o2RangePct
        )
    }
    
    private var mapWarning: String? {
        guard let range = mapRangeForAge(age) else { return nil }
        return outOfRangeMessage(
            rawText: bloodPressure,
            numeric: parseDouble(bloodPressure),
            allowed: range
        )
    }
     
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 45))
                    .foregroundColor(Color(hex: "D9B53E"))
                
                Text("Vital Signs")
                    .font(.system(size: 26, weight: .bold))
            }
            .padding(.top, 20)
            .padding(.bottom, 15)
            
            // Patient Info Summary
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("Unit:")
                        .foregroundColor(.secondary)
                    Text(selectedUnit)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 4) {
                    Text("Age:")
                        .foregroundColor(.secondary)
                    Text(age)
                        .fontWeight(.semibold)
                }
            }
            .font(.body)
            .padding(.bottom, 20)
            
            // Vital Signs Inputs
            VStack(spacing: 12) {
                // Heart Rate
                VStack(alignment: .leading, spacing: 6) {
                    VitalInputField(
                        label: "Heart Rate (bpm)",
                        value: $heartRate,
                        icon: "waveform.path.ecg",
                        placeholder: "e.g. 75",
                        onCommit: { heartRateTouched = true }
                    )
                    .keyboardType(.decimalPad)
                    
                    if heartRateTouched, let warn = heartRateWarning {
                        Text(warn)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Blood Pressure Mean
                VStack(alignment: .leading, spacing: 6) {
                    VitalInputField(
                        label: "Blood Pressure Mean (mmHg)",
                        value: $bloodPressure,
                        icon: "heart.fill",
                        placeholder: "e.g. 40",
                        onCommit: { mapTouched = true }
                    )
                    .keyboardType(.decimalPad)
                    
                    if mapTouched, let warn = mapWarning {
                        Text(warn)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Temperature
                VStack(alignment: .leading, spacing: 6) {
                    TempEditableField(
                        value: $temperature,
                        icon: "thermometer",
                        label: "Temperature (°F/°C)",
                        placeholder: "e.g., 98.6 or 37"
                    )
                    .keyboardType(.decimalPad)
                    
                    if let warn = tempWarning {
                        Text(warn)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Respiratory Rate
                VStack(alignment: .leading, spacing: 6) {
                    VitalInputField(
                        label: "Respiratory Rate (breaths/min)",
                        value: $respiratoryRate,
                        icon: "lungs.fill",
                        placeholder: "e.g. 60",
                        onCommit: { respTouched = true }
                    )
                    .keyboardType(.decimalPad)
                    
                    if respTouched, let warn = respWarning {
                        Text(warn)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Oxygen Saturation
                VStack(alignment: .leading, spacing: 6) {
                    VitalInputField(
                        label: "Oxygen Saturation (%)",
                        value: $oxygenSaturation,
                        icon: "drop.fill",
                        placeholder: "e.g. 98",
                        onCommit: { o2Touched = true }
                    )
                    .keyboardType(.decimalPad)
                    
                    if o2Touched, let warn = o2Warning {
                        Text(warn)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Next Button
            Button {
                navigateToNext = true
            } label: {
                HStack(spacing: 8) {
                    Text("Next")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .frame(width: 200, height: 56)
                .background(isFormValid ? Color(hex: "D9B53E") : Color.gray.opacity(0.5))
                .cornerRadius(30)
                .shadow(
                    color: isFormValid ? Color(hex: "D9B53E").opacity(0.3) : .clear,
                    radius: 8,
                    y: 4
                )
            }
            .disabled(!isFormValid)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "F5E8C7").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "F5E8C7"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .dismissKeyboardOnTap()
        .navigationDestination(isPresented: $navigateToNext) {
            SignSymView(
                selectedUnit: selectedUnit,
                age: age,
                vitals: VitalsPayload(
                    heartRate: heartRate,
                    bloodPressure: bloodPressure,
                    temperature: temperature,
                    respiratoryRate: respiratoryRate,
                    oxygenSaturation: oxygenSaturation
                )
            )
        }
    }
    
    private var isFormValid: Bool {
        let allFilled =
            !heartRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !bloodPressure.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !temperature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !respiratoryRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !oxygenSaturation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let noWarnings =
            heartRateWarning == nil &&
            mapWarning == nil &&
            tempWarning == nil &&
            respWarning == nil &&
            o2Warning == nil

        return allFilled && noWarnings
    }
}

struct VitalInputField: View {
    let label: String
    @Binding var value: String
    let icon: String
    let placeholder: String
    var onCommit: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "D9B53E"))
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            TextField(
                placeholder,
                text: $value,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        onCommit?()
                    }
                }
            )
            .font(.system(size: 16))
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}


extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

struct TempEditableField: View {
    @Binding var value: String
    let icon: String
    let label: String
    let placeholder: String

    @State private var showEditor = false
    @State private var draft = ""

    @FocusState private var isEditingTemp: Bool

    private enum TempUnit: String { case c, f }
    
    private var numericValue: Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }
    
    private var detectedUnit: TempUnit? {
        guard let n = numericValue else { return nil }
        return n < 70 ? .c : .f
    }
    
    private var celsiusValue: Double? {
        guard let n = numericValue, let u = detectedUnit else { return nil }
        return u == .c ? n : (n - 32) * 5.0 / 9.0
    }
    
    private var fahrenheitValue: Double? {
        guard let n = numericValue, let u = detectedUnit else { return nil }
        return u == .f ? n : (n * 9.0 / 5.0 + 32.0)
    }
    
    private func fmt(_ x: Double) -> String {
        String(format: "%.1f", x)
    }

    private var displayString: String {
        guard let u = detectedUnit,
              let c = celsiusValue,
              let f = fahrenheitValue else {
            return value.isEmpty ? placeholder : value
        }
        let primary   = (u == .c) ? "\(fmt(c)) °C" : "\(fmt(f)) °F"
        let secondary = (u == .c) ? "\(fmt(f)) °F" : "\(fmt(c)) °C"
        return "\(primary) | \(secondary)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "D9B53E"))
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Button {
                draft = value
                showEditor = true
            } label: {
                HStack {
                    Text(displayString)
                        .foregroundColor(value.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                    Spacer(minLength: 0)
                }
                .frame(height: 44)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Edit temperature"))
            .accessibilityHint(Text("Double tap to enter a value"))
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter Temperature")
                        .font(.headline)

                    TextField("e.g., 98.6 or 37", text: $draft)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isEditingTemp)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isEditingTemp = true
                            }
                        }

                    Spacer()
                }
                .padding()
                .navigationTitle("Temperature")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            showEditor = false
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}
