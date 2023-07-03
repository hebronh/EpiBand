//
//  ContentView.swift
//  Breathing Rate Watch App
//
//  Created by Hebron Bekele on 7/3/23.
//
import Foundation
import WatchKit
import HealthKit
import SwiftUI

class BreathingRateViewModel: ObservableObject {
    @Published var sex: Sex = .male
    @Published var dateOfBirthString = ""
    @Published var breathingRateZones: [String] = []

    func calculateBreathingRateZones() {
        guard let dateOfBirth = DateUtils.date(from: dateOfBirthString) else {
            return
        }
        
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year!
        let maxHeartRate = sex == .male ? 220 - age : 226 - age
        let moderateZone = Int(Double(maxHeartRate) * 0.5)...Int(Double(maxHeartRate) * 0.7)
        let vigorousZone = Int(Double(maxHeartRate) * 0.7)...Int(Double(maxHeartRate) * 0.85)
        breathingRateZones = ["Moderate Zone: \(moderateZone.lowerBound) - \(moderateZone.upperBound)",
                              "Vigorous Zone: \(vigorousZone.lowerBound) - \(vigorousZone.upperBound)"]
    }

    private func monitorBreathingRate() {
        // Use a timer to monitor breathing rate during exercise
        // If breathing rate reaches maximum zone, print "auto-injecting"
    }
}

struct BreathingRateView: View {
    @StateObject var viewModel = BreathingRateViewModel()

    var body: some View {
        VStack {
            Text("Enter your sex and date of birth:")
            Picker("Sex", selection: $viewModel.sex) {
                Text("Male").tag(Sex.male)
                Text("Female").tag(Sex.female)
            }
            
            .pickerStyle(WheelPickerStyle()) // Apply the default picker style
            .frame(width: 200)
            .frame(height: 50)
            
            TextField("Date of Birth (YYYY-MM-DD)", text: $viewModel.dateOfBirthString)
            Button("Calculate Breathing Rate Zones") {
                viewModel.calculateBreathingRateZones()
            }
            List(viewModel.breathingRateZones, id: \.self) { zone in
                Text(zone)
            }
        }
    }
}

enum Sex {
    case male, female
}

struct DateUtils {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static func date(from dateString: String) -> Date? {
        return dateFormatter.date(from: dateString)
    }
}
