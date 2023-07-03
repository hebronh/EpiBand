//
//  ContentView.swift
//  heartrate Watch App
//
//  Created by Hebron Bekele on 7/3/23.
//

import HealthKit
import UserNotifications
import WatchConnectivity
import WatchKit
import SwiftUI
import HealthKit
import Combine


struct ContentView: View {
    
    @State private var maxHeartRate: Double = 190 // Assuming a max heart rate of 190 bpm
    @State private var currentHeartRate: Double = 110 // Assuming a current heart rate of 110 bpm
    @State private var sex: HKBiologicalSex = .female // Assuming a 30-year-old female
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            Text("Heart Rate Zones")
                .font(.headline)
            RingChartView(
                data: [
                    RingChartData(value: 0.5, color: .blue, innerRadius: 20),
                    RingChartData(value: 0.2, color: .green, innerRadius: 20),
                    RingChartData(value: 0.1, color: .teal, innerRadius: 20)
                ],
                title: "",
                subtitle: ""
            )
            .frame(width: 120, height: 120)
            
            Text("Max Heart Rate: \(Int(maxHeartRate)) bpm")
                .font(.system(size: 10))
            Text("Current Heart Rate Zone: 1")
                .font(.system(size: 10))
            Text("Current Heart Rate: \(Int(currentHeartRate)) bpm")
                .font(.system(size: 10))
            
            Button(action: requestAuthorization) {
                Text("Authorize HealthKit")
            }
        }
        .padding()
        .onAppear(perform: requestAuthorization)
        .background(Color.indigo)
    }
    
    private func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [            HKObjectType.quantityType(forIdentifier: .heartRate)!,            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                fetchHeartRateSamples()
                fetchBiologicalSex()
            } else if let error = error {
                print("Error requesting authorization: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchHeartRateSamples() {
        let calendar = Calendar.current
        let date = Date()
        let interval = DateComponents(hour: 1)
        let anchorDate = calendar.date(byAdding: .hour, value: -1, to: date)!
        let predicate = HKQuery.predicateForSamples(withStart: anchorDate, end: date, options: .strictEndDate)
        let query = HKStatisticsCollectionQuery(
            quantityType: HKObjectType.quantityType(forIdentifier: .heartRate)!,
            quantitySamplePredicate: predicate,
            options: [.discreteAverage],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, result, error in
            guard let result = result else {
                if let error = error {
                    print("Error fetching heart rate samples: \(error.localizedDescription)")
                }
                return
            }
            
            let heartRateSamples = result.statistics().map { $0.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0 }
            if let latestHeartRate = heartRateSamples.last {
                currentHeartRate = latestHeartRate
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBiologicalSex() {
        let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        
        do {
            let biologicalSex = try healthStore.biologicalSex().biologicalSex
            sex = biologicalSex
        }
        catch {
            print("Error fetching biological sex: \(error.localizedDescription)")
        }
    }
}
struct RingChartView: View {
    let data: [RingChartData]
    let title: String
    let subtitle: String
    
    var body: some View {
        ZStack {
            let redData = data[0]
            let greenData = data[1]
            let yellowData = data[2]
            
            let redEndAngle = Angle(degrees: redData.value * 360)
            let greenEndAngle = Angle(degrees: (redData.value + greenData.value) * 360)
            let yellowEndAngle = Angle(degrees: (redData.value + greenData.value + yellowData.value) * 360)
            
            RingShape(startAngle: .degrees(0), endAngle: redEndAngle, lineWidth: 20, innerRadius: greenData.innerRadius)
                .fill(redData.color)
                .overlay(
                    VStack {
                        Text(title)
                            .font(.title)
                        Text(subtitle)
                            .font(.subheadline)
                    }
                )
            
            RingShape(startAngle: redEndAngle, endAngle: greenEndAngle, lineWidth: 20, innerRadius: yellowData.innerRadius)
                .fill(greenData.color)
            
            RingShape(startAngle: greenEndAngle, endAngle: yellowEndAngle, lineWidth: 20, innerRadius: redData.innerRadius)
                .fill(yellowData.color)
        }
    }
}
struct RingChartData {
    let value: Double
    let color: Color
    let innerRadius: CGFloat
}

struct RingShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat
    let innerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        
        path.addArc(
            center: center,
            radius: radius - innerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        path = path.strokedPath(.init(lineWidth: lineWidth))
        
        return path
    }
}
