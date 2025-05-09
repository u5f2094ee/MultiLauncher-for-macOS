
// MARK: - AppIconView.swift
// Purpose: Displays a single app icon.

import SwiftUI

struct AppIconView: View {
    @EnvironmentObject var settings: AppSettings
    let appItem: AppItem
    let onLaunch: (AppItem) -> Void

    private var iconSize: CGFloat { settings.iconSize }
    private var cornerRadiusSize: CGFloat { iconSize / 4.0 }
    private let textFontSize: CGFloat = 14
    private var cellWidth: CGFloat { iconSize + 25 }
    private var cellHeight: CGFloat { iconSize + 45 }
    private let vStackSpacing: CGFloat = 10

    var body: some View {
        Button(action: { onLaunch(appItem) }) {
            VStack(spacing: vStackSpacing) {
                appItem.getAppIcon().resizable().aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.primary).cornerRadius(cornerRadiusSize)
                Text(appItem.name).font(.system(size: textFontSize))
                    .foregroundColor(.primary).lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: cellWidth - 10)
            }
            .frame(width: cellWidth, height: cellHeight)
            .padding(5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
