//
//  ContentView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 2/4/26.
//

import Foundation
import SwiftUI

struct ContentView: NSViewRepresentable {
    typealias NSViewType = NSHostingView<DashboardView>

    func makeNSView(context: Context) -> NSViewType {
        NSHostingView(rootView: DashboardView())
    }

    func updateNSView(_ nsView: NSViewType, context: Context) { }

    static func dismantleNSView(_ nsView: NSViewType, coordinator: ()) {
        print("dismantle \(nsView.rootView)")
        print("gomonProcess shared \(String(describing: GomonProcess.shared))")
    }
}
