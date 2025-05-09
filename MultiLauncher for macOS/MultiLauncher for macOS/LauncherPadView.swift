

// MARK: - LauncherPadView.swift
// Purpose: The main launcher pad UI.

import SwiftUI
import AppKit

struct LauncherPadView: View {
    @EnvironmentObject var settings: AppSettings
    let onLaunchApp: (AppItem) -> Void

    private var gridItemSpacing: CGFloat { settings.iconPadding }
    private var vStackSpacing: CGFloat { settings.iconPadding }
    private let overallPadding: CGFloat = 40
    private let padCornerRadius: CGFloat = 35

    private var columns: [GridItem] { Array(repeating: .init(.flexible(), spacing: gridItemSpacing), count: settings.columnsInGrid) }

    var body: some View {
        VStack(spacing: vStackSpacing) {
            if settings.apps.isEmpty {
                Text("No apps added yet.\nOpen Settings (via menubar icon)\nto add applications.")
                    .font(.title3).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(60)
            } else {
                LazyVGrid(columns: columns, spacing: gridItemSpacing) {
                    ForEach(settings.apps) { app in
                        AppIconView(appItem: app, onLaunch: { onLaunchApp($0) })
                    }
                }
                .padding(.horizontal, gridItemSpacing)
            }
        }
        .padding(overallPadding)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(padCornerRadius)
                // Shadow is now removed from here.
        )
        .frame(minWidth: calculateMinWidth(),
               maxWidth: calculateMaxWidth(),
               minHeight: calculateMinHeight())
        .fixedSize(horizontal: false, vertical: true)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: settings.apps)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: settings.columnsInGrid)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: settings.iconSize)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: settings.iconPadding)
        .transition(.scale.combined(with: .opacity))
    }

    private func calculateCellWidth() -> CGFloat { return settings.iconSize + 25 }
    private func calculateCellHeight() -> CGFloat { return settings.iconSize + 45 }
    private func calculateMinWidth() -> CGFloat {
        let singleCellEffectiveWidth = calculateCellWidth()
        let totalIconWidth = CGFloat(settings.columnsInGrid) * singleCellEffectiveWidth
        let totalSpacingWidth = CGFloat(max(0, settings.columnsInGrid - 1)) * settings.iconPadding
        return totalIconWidth + totalSpacingWidth + overallPadding * 2
    }
    private func calculateMinHeight() -> CGFloat { return calculateCellHeight() + overallPadding * 2 }
    private func calculateMaxWidth() -> CGFloat { return NSScreen.main?.visibleFrame.width ?? 1000 }
}
