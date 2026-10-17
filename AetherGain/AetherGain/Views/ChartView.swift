







import SwiftUI

struct ChartView: View {
    var body: some View {
        AGProgressScreen()
    }
}

#Preview {
    ChartView().environmentObject(AuthViewModel())
}
