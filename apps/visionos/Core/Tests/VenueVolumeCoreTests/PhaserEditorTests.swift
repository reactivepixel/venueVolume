import Testing
@testable import VenueVolumeCore

@Test func shrinkingPhaserKeepsOldSelectionSafeUntilViewUpdates() {
    var phaser = DimmerPattern.wave.make()
    phaser.resizeSteps(to: 32)
    #expect(phaser.stepBank(containing: 31) == 24..<32)
    phaser.resizeSteps(to: 2)
    #expect(phaser.stepBank(containing: 31) == 0..<2)
    #expect(phaser.stepBank(containing: -1) == 0..<2)
    let before = phaser
    #expect(!phaser.updateStep(at: 31) { $0.values[0] = 100 })
    #expect(phaser == before)
    #expect(phaser.updateStep(at: 1) { $0.values[0] = 100 })
    #expect(phaser.steps[1].values[0] == 100)
    phaser.steps = []
    #expect(phaser.stepBank(containing: 31).isEmpty)
}
