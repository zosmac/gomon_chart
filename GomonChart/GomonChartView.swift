//
//  GomonChartView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI
import SwiftData
import Charts
import Algorithms

struct GomonChartView: View {
    @Query(sort: [.init(\Event.eventId), .init(\Event._timestamp)]) private var events: [Event]
    @State private var eventKind: GomonEvents.Kind = .processCPUTime
    @State private var measureId: Measure.ID?
    @State private var measure: Measure?
    @State private var scrollPosition = Date.distantFuture
    @State private var chartXVisibleDomain = 4*3600 // x axis length four hours

    var body: some View {
        let measures = events
            .filter {
                switch eventKind {
                case .processCPUTime:
                    return $0 is MeasureProcess
                case .collectionTime:
                    return $0 is MeasureServe
                default:
                    return false
                }
            }
            .adjacentPairs()
            .compactMap {
                Measure($0, $1)
            }

        NavigationSplitView {
            List(GomonEvents.Kind.allCases, id: \.self, selection: $eventKind) {
                Text($0.rawValue)
            }
            .navigationSplitViewColumnWidth(ideal: 150.0)
            .onChange(of: eventKind) {
                print("eventKind selected: \($0) -> \($1)")
            }
        } content: {
            MeasuresChart(measures: measures, eventKind: eventKind, measure: $measure, xAxisLength: $chartXVisibleDomain, scrollPosition: $scrollPosition)
                .navigationSplitViewColumnWidth(ideal: 400.0)
                .onChange(of: scrollPosition) {
                    print("\(scrollPosition)")
                }
        } detail: {
            MeasuresTable(measures: measures, eventKind: eventKind, measureId: $measureId)
                .onChange(of: measureId) {
                    if let index = events.firstIndex(where: { $0.id == measureId }) {
                        print(String(data: try! events[index].encode(), encoding: .utf8)!)
                    }
                    if let index = measures.firstIndex(where: { $0.id == measureId }) {
                        measure = measures[index]
                        scrollPosition = measure!.timestamp.addingTimeInterval(TimeInterval(-chartXVisibleDomain/2))
                        print("\(measure!.eventId) \(measure!.timestamp) \(measure!.value) ")
                    }
                }
                .ignoresSafeArea()
        }
    }
}

struct Measure: Identifiable {
    var id: PersistentIdentifier
    let eventId: String
    let timestamp: Date
    let value: Double
    init?(_ previous: Event, _ current: Event) {
        if previous.eventId != current.eventId { return nil }
        switch (previous, current) {
        case (let previous as MeasureProcess, let current as MeasureProcess):
            let interval = current._timestamp!.timeIntervalSince(previous._timestamp!) // seconds
            guard let currentTotal = current.total,
                  let previousTotal = previous.total,
                  previousTotal < currentTotal else { return nil }
            self.value = Double(currentTotal - previousTotal) / interval / 1000000000.0
        case (let previous as MeasureServe, let current as MeasureServe):
            guard let currentCollectionTime = current.collectionTime,
                  let previousCollectionTime = previous.collectionTime else { return nil }
            self.value = Double(currentCollectionTime - previousCollectionTime) / 1000000000.0 // nanoseconds
        default:
            return nil
        }
        self.id = current.persistentModelID
        self.eventId = current.eventId
        self.timestamp = current._timestamp!
    }
}

struct MeasuresChart: View {
    var measures: [Measure]
    var eventKind: GomonEvents.Kind
    @Binding var measure: Measure?
    @Binding var xAxisLength: Int
    @Binding var scrollPosition: Date

    //    static private let dateFormatter = {
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "dd/MM"
    //        return dateFormatter
    //    }()
    //    static private let hhmmFormatter = {
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "HH:mm"
    //        return dateFormatter
    //    }()

    var body: some View {
        Chart(measures, id: \.timestamp) {
            LineMark(x: .value("Timestamp", $0.timestamp), y: .value("Measure", $0.value))
                .foregroundStyle(by: .value("Event ID", $0.eventId))
                .symbol(by: .value("Event ID", $0.eventId))
//                .interpolationMethod(.catmullRom(alpha: 0.5))
                .interpolationMethod(.cardinal(tension: 0.8)) // Smooth the line using cardinal interpolation
            if let measure {
                PointMark(x: .value("Timestamp", measure.timestamp), y: .value("Measure", measure.value))
                    .symbolSize(by: .value("Measure", measure.value))
                    .annotation {
                        Text("\(measure.timestamp.formatted(date: .numeric, time: .standard))\n\(measure.eventId)\n\(measure.value)")
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, roundLowerBound: true, roundUpperBound: true)) { value in
                let date = value.as(Date.self)!
                AxisValueLabel(anchor: .top) {
                    VStack {
                        Text(date, format: .dateTime.hour())
                        Text(date, format: .dateTime.month().day())
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
            }
            AxisMarks(values: .stride(by: .minute, count: 10, roundLowerBound: true, roundUpperBound: true)) { value in
                let date = value.as(Date.self)!
                let minute = Calendar.current.component(.minute, from: date)
                if minute == 30 {
                    AxisValueLabel(anchor: .top) {
                        Text(date, format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                    }
                    AxisGridLine()
                }
            }
        }
        .chartXScale(domain: .automatic)
        .chartScrollableAxes(.horizontal) // Enable horizontal scrolling
        .chartXVisibleDomain(length: xAxisLength) // Show 4 hours at a time on the X-axis
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartScrollPosition(x: $scrollPosition)
        .onAppear()
    }
}

struct MeasuresTable: View {
    var measures: [Measure]
    var eventKind: GomonEvents.Kind
    @Binding var measureId: Measure.ID?

    var body: some View {
        Table(measures, selection: $measureId) {
            TableColumn("Event ID", value: \.eventId)
            TableColumn("Time(\(Date.now.formatted(Date.FormatStyle().timeZone(.specificName(.short)))))") {
                Text($0.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard).secondFraction(.fractional(3))) //GomonEvents.jsonDateStyle)
                    .monospaced()
            }
            .width(ideal: 220.0, max: .infinity)
            TableColumn(eventKind.rawValue) {
                Text($0.value, format: .number.precision(.fractionLength(6)))
                    .monospaced()
            }
            .width(ideal: 80.0, max: .infinity)
            .alignment(.trailing)
        }
        .toolbarBackgroundVisibility(.hidden, for: .automatic)
    }
}
