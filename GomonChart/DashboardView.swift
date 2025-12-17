//
//  DashboardView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI
import Observation

struct DashboardView: View {
    @State private var event = GomonEvent()

    var body: some View {
        @Bindable var messages = GomonEvents(event: event)
        VStack {
            Text(String(describing: String(data: event.json ?? Data("{}".utf8), encoding: .utf8)))
                .task {
                    messages.capture()
                }
            if let event = messages.event.any as? ProcessMeasure {
                Text("Total CPU usage:\(event.total)")
                Text("Total Memory usage:\(event.size)")
            }
        }
    }
}
