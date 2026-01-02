//
//  SummaryView.swift
//  luca-app
//
//  Created by Đạt Bùi on 10/30/25.
//

import SwiftUI

struct SummaryView: View {
    let unit: String
    let age: String
    let vitals: VitalsPayload
    let color: String
    let respiratory: [String]
    let abdomen: [String]
    let alarms: [String]
    
    @State private var goToOutput = false
    
    var body: some View {
        ZStack {
            Color(hex: "F5E8C7").ignoresSafeArea()
            
            List {
                Section("Patient Context") {
                    LabeledContent("Unit", value: unit)
                    LabeledContent("Age", value: age)
                }
                
                Section("Vital Signs") {
                    LabeledContent("Heart Rate (bpm)", value: vitals.heartRate)
                    LabeledContent("Blood Pressure", value: vitals.bloodPressure)
                    LabeledContent("Temperature (°F)", value: vitals.temperature)
                    LabeledContent("Respiratory Rate", value: vitals.respiratoryRate)
                    LabeledContent("Oxygen Saturation (%)", value: vitals.oxygenSaturation)
                }
                
                Section("Signs & Symptoms") {
                    LabeledContent("Color", value: color.isEmpty ? "—" : color)
                    labeledList(title: "Respiratory", items: respiratory)
                    labeledList(title: "Abdomen", items: abdomen)
                    labeledList(title: "Alarms", items: alarms)
                }
                
                // MARK: - Search Button
                Section {
                    HStack {
                        Spacer()
                        Button {
                            goToOutput = true
                        } label: {
                            HStack(spacing: 8) {
                                Text("Search")
                                    .font(.headline)
                                Image(systemName: "magnifyingglass")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 200, height: 56)
                            .background(Color(hex: "D9B53E"))
                            .cornerRadius(30)
                            .shadow(
                                color: Color(hex: "D9B53E").opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationDestination(isPresented: $goToOutput) {
            OutputView()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Function
    @ViewBuilder
    private func labeledList(title: String, items: [String]) -> some View {
        if items.isEmpty {
            LabeledContent(title, value: "—")
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(items.joined(separator: ", "))
            }
        }
    }
}

#Preview {
    NavigationStack {
        SummaryView(
            unit: "NICU",
            age: "22–30 weeks",
            vitals: VitalsPayload(
                heartRate: "140",
                bloodPressure: "65/40",
                temperature: "98.6",
                respiratoryRate: "40",
                oxygenSaturation: "96"
            ),
            color: "Pink",
            respiratory: ["Retractions", "Tachypnea"],
            abdomen: ["Soft"],
            alarms: ["Increased Desats"]
        )
    }
}
