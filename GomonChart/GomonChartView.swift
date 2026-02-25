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
//                Measure.domain = [Double.zero, Double.zero]
            }
        } content: {
            MeasuresChart(measures: measures, eventKind: eventKind)
            .navigationSplitViewColumnWidth(ideal: 400.0)
        } detail: {
            MeasuresTable(measures: measures, eventKind: eventKind, measureId: $measureId)
                .onChange(of: measureId) {
                    if let index = events.firstIndex(where: { $0.id == measureId }) {
                        print(String(data: try! events[index].encode(), encoding: .utf8)!)
                    }
                }
        }
    }
}

struct Measure: Identifiable {
//    static var domain = [Double.zero, Double.zero]
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
//        Self.domain[0] = min(Self.domain[0], self.value.rounded(.down))
//        Self.domain[1] = max(Self.domain[1], self.value.rounded(.up))
    }
}

struct MeasuresChart: View {
    var measures: [Measure]
    var eventKind: GomonEvents.Kind
    static private let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM"
        return dateFormatter
    }()
    static private let hourFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        return dateFormatter
    }()

    var body: some View {
        Chart(measures, id: \.timestamp) {
            LineMark(x: .value("Timestamp", $0.timestamp), y: .value("CPU", $0.value))
                .foregroundStyle(by: .value("Event ID", $0.eventId))
                .symbol(by: .value("Event ID", $0.eventId))
        }
//        .chartYScale(domain: .automatic(includesZero: true, reversed: false, dataType: Double.self) { $0.append(Measure.domain[1]) }) // Measure.domain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                if let date = value.as(Date.self) {
                    let hour = Calendar.current.component(.hour, from: date)
                    AxisValueLabel {
                        VStack(alignment: .leading) {
                            Text(date, formatter: Self.hourFormatter)
                            if value.index == 0 || hour == 0 {
                                Text(date, formatter: Self.dateFormatter)
                            }
                        }
                    }

                    if hour == 0 {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1.0))
                        AxisTick(stroke: StrokeStyle(lineWidth: 1.0))
                    } else {
                        AxisGridLine()
                        AxisTick()
                    }
                }
            }
        }
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
        .ignoresSafeArea()
    }
}

//    @State private var event: Event?
//    @State private var eventId: String = ""
//
//        NavigationSplitView {
//            let eventIds = Set(events.map{$0.eventId}).sorted(by: <)
//            EventListView(eventIds: eventIds, eventId: $eventId)
//                .navigationSplitViewColumnWidth(ideal: 200.0)
//        } content: {
//            let events = events.filter{$0.eventId == eventId}.sorted{$0._timestamp! > $1._timestamp!}
//            EventTimeView(events: events, event: $event)
//                .navigationSplitViewColumnWidth(ideal: 250.0)
//        } detail: {
//            EventView(event: event)
//        }

//struct EventListView: View {
//    var eventIds: [String]
//    @Binding var eventId: String
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            List(selection: $eventId) {
//                ForEach(eventIds, id: \.self) { event in
//                    Text(event)
//                        .tag(event)
//                }
//            }
//            .onChange(of: eventId) {
//                print("eventId selected: \($0) -> \($1)")
//            }
//        }
//    }
//}
//
//struct EventTimeView: View {
//    var events: [Event]
//    @Binding var event: Event?
//    @State private var eventID: PersistentIdentifier?
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            List(events, selection: $eventID) { event in
//                Text(event.timestamp)
//                    .tag(event.id)
//            }
//            .onChange(of: events, initial: true) {
//                if ($0.count == 0 || $0.count > 0 && eventID == $0[0].id) && $1.count > 0 {
//                    eventID = $1[0].id
//                    proxy.scrollTo(eventID, anchor: .top)
//                } else if $0.count > 0 && eventID == nil {
//                    eventID = $0[0].id
//                    proxy.scrollTo(eventID, anchor: .top)
//                } else {
//                    proxy.scrollTo(eventID, anchor: .center)
//                }
//            }
//            .onChange(of: eventID) {
//                if let index = events.firstIndex(where: { $0.id == eventID }) {
//                    event = events[index]
//                } else if events.count > 0 {
//                    event = events[0]
//                }
//            }
//        }
//    }
//}
//
//struct EventView: View {
//    var event: Event?
//    var body: some View {
//        if let event {
//            ScrollView {
//                Text(String(data: (try? event.encode()) ?? Data(), encoding: .utf8) ?? "no data")
//                    .multilineTextAlignment(.leading)
//                    .font(.system(size: 12.0))
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//                    .padding(10)
//            }
//            .navigationSubtitle("\(event.eventId)\n\(event.timestamp)")
//        } else {
//            Text("Awaiting first events from Gomon...")
//        }
//    }
//}
