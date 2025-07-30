//
//  MiningStatsWidgetLiveActivity.swift
//  MiningStatsWidget
//
//  Created by Jigish Belani on 7/29/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MiningStatsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MiningStatsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MiningStatsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MiningStatsWidgetAttributes {
    fileprivate static var preview: MiningStatsWidgetAttributes {
        MiningStatsWidgetAttributes(name: "World")
    }
}

extension MiningStatsWidgetAttributes.ContentState {
    fileprivate static var smiley: MiningStatsWidgetAttributes.ContentState {
        MiningStatsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MiningStatsWidgetAttributes.ContentState {
         MiningStatsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MiningStatsWidgetAttributes.preview) {
   MiningStatsWidgetLiveActivity()
} contentStates: {
    MiningStatsWidgetAttributes.ContentState.smiley
    MiningStatsWidgetAttributes.ContentState.starEyes
}
