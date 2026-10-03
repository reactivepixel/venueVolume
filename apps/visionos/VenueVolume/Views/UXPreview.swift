import SwiftUI

extension View {
    @ViewBuilder func auditTextSize() -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ux-large-text") {
            self.dynamicTypeSize(.accessibility5)
        } else { self }
        #else
        self
        #endif
    }
}
