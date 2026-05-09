//
//  HelpButton.swift
//  AppPorts
//
//  Created by AppPorts on 2026/5/5.
//

import SwiftUI

/// 带弹出帮助内容的问号按钮
struct HelpButton: View {
    let content: String
    @State private var showPopover = false

    var body: some View {
        Button(action: { showPopover.toggle() }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            Text(LocalizedStringKey(content))
                .font(.system(size: 12))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(width: 300)
        }
    }
}
