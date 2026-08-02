//
//  ChartView.swift
//  AetherGain
//
//  Deprecated placeholder that just forwards to the real progress screen.
//  Kept so any lingering references still compile.
//

import SwiftUI

struct ChartView: View {
    var body: some View {
        AGProgressScreen()
    }
}

#Preview {
    ChartView().environmentObject(AuthViewModel())
}
