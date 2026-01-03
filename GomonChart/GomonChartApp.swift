//
//  GomonChartApp.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftData
import SwiftUI

@main
struct GomonChartApp: App {

    var body: some Scene {
        DocumentGroup(
            editing: .gomonModelDocument,
            migrationPlan: GomonModelMigrationPlan.self
        ) {
            DashboardView()
        } prepareDocument: { context in
            Task {
                do {
                    try await GomonProcess().run(context: context)
                } catch {
                    print(error)
                }
            }
        }

        //        Window("Nodegraph", id: "Nodegraph") {
        //            NodegraphView()
        //        }
    }
}
