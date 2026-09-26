import SwiftUI
import VenueVolumeCore

struct FixtureLabel: View {
    @Environment(VenueModel.self) private var model
    let fixture: Fixture

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(model.selectedID == fixture.id ? Color.cyan : Color.white.opacity(0.5)).frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 3) {
                Text(fixture.name).font(.headline).lineLimit(1)
                Text("U\(fixture.universe) · \(fixture.startAddress)–\(fixture.endAddress)")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Image(systemName: model.expandedID == fixture.id ? "chevron.up" : "slider.horizontal.3").foregroundStyle(.cyan)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .frame(minWidth: 180, maxWidth: 280)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 22))
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .hoverEffect(.highlight)
        .gesture(TapGesture(count: 2).exclusively(before: TapGesture(count: 1)).onEnded { gesture in
            switch gesture {
            case .first: withAnimation(.easeInOut(duration: 0.2)) { model.select(fixture.id, expand: true) }
            case .second: model.select(fixture.id)
            }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(fixture.name), universe \(fixture.universe), address \(fixture.startAddress)")
        .accessibilityHint("Double-select to expand channel controls")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Toggle DMX controls") { model.select(fixture.id, expand: true) }
    }
}
