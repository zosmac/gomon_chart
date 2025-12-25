//
//  DashboardView.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftUI
import Observation

struct DashboardView: View {
    let gomonProcess: GomonProcess
    @State private var gomonEvents = GomonEvents()
    
    let decoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    var body: some View {
        VStack {
            // use this to build Table:
            // event.message.map{ do { return try? decoder.decode(ProcessMeasure.self, from: Data($0.utf8)) } })")
            ScrollView {
                Text(gomonEvents.events.joined(separator: "\n"))
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 12.0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .task {
                do {
                    try await gomonProcess.runProcess(gomonEvents: gomonEvents)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func serialize(_ any: Any?) -> String {
        guard let any else { return "{}" }
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: any,
                options: [
                    .prettyPrinted,
                    .sortedKeys,
                    .withoutEscapingSlashes,
                    .fragmentsAllowed,
                ]
            )
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }
}
