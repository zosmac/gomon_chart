//
//  DashboardView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var events: [Event]
    @State private var event: Event?
    @State private var eventId: String = ""

    var body: some View {
        NavigationSplitView {
            let eventIds = Set(events.map { $0.eventId() }).sorted(by: <)
            EventListView(eventIds: eventIds, eventId: $eventId)
                .navigationSplitViewColumnWidth(ideal: 200.0)
        } content: {
            let events = events.filter{$0.eventId() == eventId}.sorted{$0._timestamp! > $1._timestamp!}
            EventTimeView(events: events, event: $event)
                .navigationSplitViewColumnWidth(ideal: 250.0)
        } detail: {
            EventView(event: event)
        }
    }
}

struct EventListView: View {
    var eventIds: [String]
    @Binding var eventId: String

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $eventId) {
                ForEach(eventIds, id: \.self) { event in
                    Text(event)
                        .tag(event)
                }
            }
            .onChange(of: eventId) {
                print("eventId selected: \($0) -> \($1)")
            }
        }
    }
}

struct EventTimeView: View {
    var events: [Event]
    @Binding var event: Event?
    @State private var eventID: PersistentIdentifier?

    var body: some View {
        ScrollViewReader { proxy in
            List(events, selection: $eventID) { event in
                Text(event.timestamp)
                    .tag(event.id)
            }
            .onChange(of: events, initial: true) {
                if ($0.count == 0 || $0.count > 0 && eventID == $0[0].id) && $1.count > 0 {
                    eventID = $1[0].id
                    proxy.scrollTo(eventID, anchor: .top)
                } else if $0.count > 0 && eventID == nil {
                    eventID = $0[0].id
                    proxy.scrollTo(eventID, anchor: .top)
                } else {
                    proxy.scrollTo(eventID, anchor: .center)
                }
            }
            .onChange(of: eventID) {
                if let index = events.firstIndex(where: { $0.id == eventID }) {
                    event = events[index]
                } else if events.count > 0 {
                    event = events[0]
                }
            }
        }
    }
}

struct EventView: View {
    var event: Event?
    var body: some View {
        if let event {
            ScrollView {
                Text(String(data: (try? event.encode()) ?? Data(), encoding: .utf8) ?? "no data")
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 12.0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
            }
            .navigationSubtitle("\(event.eventId())\n\(event.timestamp)")
        } else {
            Text("Awaiting first events from Gomon...")
        }
    }
}
