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
    @Environment(\.colorScheme) var colorScheme
    @Query(sort: [.init(\Events.timestamp, order: .reverse)]) private var events: [Events]
    @State private var eventsID: Events.ID?
    @State private var event: Events?
    @State private var eventKind: EventKind = .allEvents

    var body: some View {
        NavigationSplitView {
            List(events, selection: $eventsID) { event in
                Text(event.timestamp.formatted(jsonDateStyle)).font(.system(size: 12, design: .monospaced))
                    .tag(event.id)
            }
            .onChange(of: events, initial: true) {
                if $0.count == 0 || $0.count > 0 && eventsID == $0[0].id {
                    if $1.count > 0 {
                        eventsID = $1[0].id
                    }
                } else if $0.count > 0 && eventsID == nil {
                    eventsID = $0[0].id
                }
            }
            .onChange(of: eventsID) {
                if let index = events.firstIndex(where: { $0.id == eventsID }) {
                    event = events[index]
                } else {
                    event = events[0]
                }
            }
            .navigationSplitViewColumnWidth(ideal: 320.0)
            .task {
                do {
                    nonisolated(unsafe) let context = modelContext
                    try await GomonProcess().run(context: context)
                } catch {
                    print(error)
                }
            }
            .toolbar {
                ToolbarItem(id: "Event Type", placement: .primaryAction) {
                    ControlGroup("Event Type") {
                        Button("All", systemImage: "rectangle.3.group") {
                            eventKind = .allEvents
                        }
                        .glassEffect(.regular.tint(tint(eventKind == .allEvents)))
                        Button("Process", systemImage: "list.clipboard") {
                            eventKind = .processMeasure
                        }
                        .glassEffect(.regular.tint(tint(eventKind == .processMeasure)))
                        Button("Server", systemImage: "server.rack") {
                            eventKind = .serverMeasure
                        }
                        .glassEffect(.regular.tint(tint(eventKind == .serverMeasure)))
                    }
                }
            }
        } detail: {
            if let event {
                EventView(event: event)
            } else {
                Text("select a time")
            }
        }
    }

    func tint(_ accent: Bool) -> Color {
        accent ? Color.accentColor.opacity(0.3) : colorScheme == .light ? Color.white : Color.black
    }
}

struct EventView: View {
    var event: Events
    var body: some View {
        ScrollView {
            Text(String(data: try! event.encode(), encoding: .utf8) ?? "no data")
                .multilineTextAlignment(.leading)
                .font(.system(size: 12.0))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)
        }
        .navigationSubtitle(event.timestamp.formatted(jsonDateStyle)).font(.system(size: 12, design: .monospaced))
    }
}
