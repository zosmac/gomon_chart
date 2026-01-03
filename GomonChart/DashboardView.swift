//
//  DashboardView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) var modelContext
    @Query(
        filter: Measures.latestMeasures(),
        sort: [.init(\.timestamp, order: .reverse)]
    ) private var events: [Measures]
    @State private var eventsID: Measures.ID?
    @State private var event: Measures?

    let dateFormat = Date.ISO8601FormatStyle(includingFractionalSeconds: true, timeZone: .current)

    var body: some View {
        NavigationSplitView {
            List(events, selection: $eventsID) { event in
                Text(event.timestamp.formatted(dateFormat)).font(.system(size: 12, design: .monospaced))
                    .tag(event.id)
            }
            .onChange(of: events) {
                if $0.count == 0 || $0.count > 0 && $0[0].id == eventsID {
                    eventsID = $1[0].id
                }
            }
            .onChange(of: eventsID) {
                if let index = events.firstIndex(where: { $0.id == eventsID }) {
                    event = events[index]
                } else {
                    event = events[0]
                }
            }
            .navigationSplitViewColumnWidth(ideal: 240.0)
        } detail: {
            if event != nil {
                EventView(event: event)
            } else {
                Text("select a time")
            }
        }
    }
}

struct EventView: View {
    var event: Measures?
    var body: some View {
        ScrollView {
            Text(String(data:event!.data, encoding: .utf8) ?? "no data")
                .multilineTextAlignment(.leading)
                .font(.system(size: 12.0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
        }
    }
}
