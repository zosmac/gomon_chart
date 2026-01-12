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
            migrationPlan: GomonModelMigrationPlan.self,
            editor: {
                DashboardView()
            },
            prepareDocument: { context in
                print("New document created:\n\(context.container.configurations)\n")
            }
        )

        //        Window("Nodegraph", id: "Nodegraph") {
        //            NodegraphView()
        //        }
    }
}
