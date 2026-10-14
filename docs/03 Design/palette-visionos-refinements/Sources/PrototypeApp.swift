import SwiftUI
@main struct PaletteRefinementsApp: App {
    private var variant: Int {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--proposal"), args.indices.contains(i+1) { return Int(args[i+1]) ?? 16 }
        return 16
    }
    var body: some Scene {
        WindowGroup { RefinedProposals(variant: variant) }
            .windowResizability(.contentSize)
            .defaultSize(width: variant == 24 ? 1080 : 1320, height: 900)
    }
}
