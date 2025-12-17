//
//  GomonChartApp.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI

@main
struct GomonChartApp: App {
    var body: some Scene {
        Window("Dashboard", id: "Dashboard") {
            DashboardView()
        }
//        Window("Nodegraph", id: "Nodegraph") {
//            NodegraphView()
//        }
    }
}
