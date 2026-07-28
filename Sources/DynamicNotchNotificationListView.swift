import CmuxSettings
import SwiftUI

/// Scrollable, snapshot-driven rows for the expanded Dynamic Notch tray.
struct DynamicNotchNotificationListView: View {
    let notifications: [TerminalNotification]
    let isExpanded: Bool
    let viewportHeight: CGFloat
    let globalAppearance: DynamicNotchAppearance
    let trayAppearance: DynamicNotchAppearance
    let contentHeightChanged: (CGFloat) -> Void
    let performAction: (String, [String: String], TerminalNotification) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(
                        Array(notifications.enumerated()),
                        id: \.element.id
                    ) { index, notification in
                        let appearance = globalAppearance.applying(
                            notification.presentation.appearance
                        )
                        VStack(spacing: 0) {
                            DynamicNotchNotificationView(
                                notification: notification,
                                isTrayExpanded: isExpanded,
                                shouldAutofocus: index == 0,
                                appearance: appearance
                            ) { action, values in
                                performAction(action, values, notification)
                            }

                            if index < notifications.count - 1 {
                                Divider()
                                    .overlay(
                                        trayAppearance.color(
                                            .dividerColor,
                                            system: Color(nsColor: .separatorColor)
                                        )
                                    )
                                    .padding(
                                        .horizontal,
                                        trayAppearance.dimension(.dividerHorizontalPadding)
                                    )
                            }
                        }
                        .id(notification.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .animation(
                    reduceMotion
                        ? nil
                        : .snappy(duration: animationDuration),
                    value: notifications.map(\.id)
                )
                .onGeometryChange(for: CGFloat.self, of: \.size.height) {
                    contentHeightChanged($0)
                }
            }
            .scrollIndicators(
                trayAppearance.boolean(.showScrollIndicators) ? .visible : .hidden
            )
            .frame(
                width: trayAppearance.dimension(.expandedWidth),
                height: viewportHeight
            )
            .onChange(of: notifications.first?.id) { _, newestID in
                guard isExpanded, let newestID else { return }
                if reduceMotion {
                    proxy.scrollTo(newestID, anchor: .top)
                } else {
                    withAnimation(.snappy(duration: animationDuration)) {
                        proxy.scrollTo(newestID, anchor: .top)
                    }
                }
            }
            .onChange(of: isExpanded) { _, expanded in
                guard expanded, let newestID = notifications.first?.id else {
                    return
                }
                proxy.scrollTo(newestID, anchor: .top)
            }
            .accessibilityIdentifier("DynamicNotchNotificationList")
        }
    }

    private var animationDuration: Double {
        Double(trayAppearance.dimension(.animationDuration))
    }
}
