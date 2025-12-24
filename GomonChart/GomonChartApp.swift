//
//  GomonChartApp.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI

@main
struct GomonChartApp: App {
    @State private var gomonProcess = GomonProcess.shared

    var body: some Scene {
        Window("Dashboard", id: "Dashboard") {
            DashboardView(gomonProcess: gomonProcess)
        }
//        Window("Nodegraph", id: "Nodegraph") {
//            NodegraphView()
//        }
    }
}
