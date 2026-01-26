//
//  DashboardView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI
import SwiftData

@Observable final class DashboardWindow {
    var window = Window(NSView())
    struct Window: NSViewRepresentable {
        let nsView: NSView
        init(_ nsView: NSView) {
            self.nsView = nsView
        }
        func makeNSView(context: Context) -> NSView { nsView }
        func updateNSView(_ nsView: NSView, context: Context) {}
        static func dismantleNSView(_ nsView: Self.NSViewType, coordinator: Self.Coordinator) {
            print("dismantle nsView \(nsView)")
            print("dismantle nsView window \(nsView.window, default: "nil")")
        }
    }
    @MainActor deinit {
        print("deinit DashboardWindow \(String(describing: window.nsView.window))")
    }
}

struct ContentView: View {
    @State private var window = DashboardWindow()

    var body: some View {
        DashboardView(window: window)
            .background { window.window } // creates background view that shares window
    }
}

struct DashboardView: View {
    @Bindable var window: DashboardWindow

    @Environment(\.colorScheme) var colorScheme
    @State private var predicate: Predicate<Event>?
    @State private var event: Event?
    @State private var eventKind: EventKind = .allEvents

    var body: some View {
        NavigationSplitView {
            //            Text("window \(String(describing: window.window.nsView.window))")
            EventListView(predicate: predicate, event: $event)
                .navigationSplitViewColumnWidth(ideal: 320.0)
                .toolbar {
                    ToolbarItem(id: "Event Type", placement: .primaryAction) {
                        ControlGroup("Event Type") {
                            Button("All", systemImage: "rectangle.3.group") {
                                eventKind = .allEvents
                                predicate = nil
                            }
                            .glassEffect(.regular.tint(tint(eventKind == .allEvents)))
                            Button("Process", systemImage: "list.clipboard") {
                                eventKind = .processMeasure
                                predicate = #Predicate<Event> { $0 is MeasureProcess }
                            }
                            .glassEffect(.regular.tint(tint(eventKind == .processMeasure)))
                            Button("Serve", systemImage: "server.rack") {
                                eventKind = .serveMeasure
                                predicate = #Predicate<Event> { $0 is MeasureServe }
                            }
                            .glassEffect(.regular.tint(tint(eventKind == .serveMeasure)))
                        }
                    }
                }
        } detail: {
            EventView(event: event, window: window)
        }
    }

    func tint(_ accent: Bool) -> Color {
        accent ? Color.accentColor.opacity(0.3) : colorScheme == .light ? Color.white : Color.black
    }
}

struct EventListView: View {
    @Environment(\.modelContext) var modelContext
    @Binding var event: Event?
    @Query private var events: [Event]
    @State private var eventID: Event.ID?

    init(predicate: Predicate<Event>? = nil, event: Binding<Event?>) {
        _events = Query(
            filter: predicate,
            sort: [.init(\._timestamp, order: .reverse)],
        )
        _event = event
    }

    var body: some View {
        List(events, selection: $eventID) { event in
            VStack(alignment: .leading, spacing: 0) {
                Text(event.eventId())
                Text(event.timestamp)
            }
            .tag(event.id)
        }
        .onChange(of: events, initial: true) {
            if ($0.count == 0 || $0.count > 0 && eventID == $0[0].id) && $1.count > 0 {
                eventID = $1[0].id
            } else if $0.count > 0 && eventID == nil {
                eventID = $0[0].id
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

struct EventView: View {
    var event: Event?
    @Bindable var window: DashboardWindow
    var body: some View {
        if let event, window.window.nsView.window != nil {
            ScrollView {
                Text(String(data: (try? Events.encoder.encode(event)) ?? Data(), encoding: .utf8) ?? "no data")
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
