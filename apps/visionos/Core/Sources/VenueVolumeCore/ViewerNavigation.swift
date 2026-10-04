import Foundation

/// Virtual travel relative to the venue's spawn-facing frame. Never moves ARKit's camera.
public struct ViewerNavigationPose: Codable, Equatable, Sendable {
    public var offset: Position3D
    public var orientation: Quaternion3D
    public init(offset: Position3D = .init(x: 0,y: 0,z: 0), orientation: Quaternion3D = .init()) {
        self.offset = offset; self.orientation = orientation
    }
    public var isValid: Bool {
        let q = orientation
        return [offset.x,offset.y,offset.z,q.x,q.y,q.z,q.w].allSatisfy(\.isFinite)
            && abs(q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w-1) < 0.001
    }
    public static func compose(_ a: Quaternion3D, _ b: Quaternion3D) -> Quaternion3D {
        let x = a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y
        let y = a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x
        let z = a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w
        let w = a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z
        let n = sqrt(x*x+y*y+z*z+w*w)
        return .init(x: x/n,y: y/n,z: z/n,w: w/n)
    }
}

public enum NavigationFinger: String, Sendable { case index, middle }
public enum NavigationReset: Sendable { case orientation, spawn }

/// Positions are tracking positions expressed in the physical spawn-facing frame.
public struct NavigationHandSample: Sendable {
    public var thumb: SIMD3<Float>
    public var index: SIMD3<Float>
    public var middle: SIMD3<Float>
    public init(thumb: SIMD3<Float>, index: SIMD3<Float>, middle: SIMD3<Float>) {
        self.thumb = thumb; self.index = index; self.middle = middle
    }
    public var isValid: Bool { [thumb,index,middle].allSatisfy { [$0.x,$0.y,$0.z].allSatisfy(\.isFinite) } }
    func distance(_ finger: NavigationFinger) -> Float { FixtureAiming.length((finger == .index ? index : middle)-thumb) }
    func point(_ finger: NavigationFinger) -> SIMD3<Float> { ((finger == .index ? index : middle)+thumb)/2 }
}

/// Exclusive pinch recognition with hysteresis, clutching, double-click resets and loss recovery.
public struct LeftHandNavigation: Sendable {
    public private(set) var pose = ViewerNavigationPose()
    public private(set) var activeFinger: NavigationFinger?
    public private(set) var reset: NavigationReset?
    public private(set) var reservedUntil: Double = 0
    private var needsRelease = false
    private var startPoint = SIMD3<Float>.zero
    private var startPose = ViewerNavigationPose()
    private var headBasis = Quaternion3D()
    private var startedAt: Double = 0
    private var moved = false
    private var lastClick: (finger: NavigationFinger, time: Double)?
    private var lastUpdate: Double?
    public init() {}
    public mutating func restore(_ pose: ViewerNavigationPose) {
        guard pose.isValid, activeFinger == nil else { return }
        self.pose = pose
    }
    public func reservesInput(at time: Double) -> Bool { activeFinger != nil || time < reservedUntil }
    public mutating func cancel(at time: Double) {
        if activeFinger != nil { reservedUntil = time+0.3 }
        activeFinger = nil; lastClick = nil; needsRelease = true; reset = nil
    }
    public mutating func update(_ sample: NavigationHandSample?, headBasis: Quaternion3D = .init(), at time: Double) {
        reset = nil
        guard time.isFinite else { return }
        guard let sample, sample.isValid, ViewerNavigationPose(orientation: headBasis).isValid else { cancel(at: time); lastUpdate = time; return }
        if let lastUpdate, time-lastUpdate > 0.25 || time < lastUpdate { cancel(at: time) }
        lastUpdate = time
        let index = sample.distance(.index), middle = sample.distance(.middle)
        // Reserve app UI before the system's completed index pinch reaches a button.
        if (index < 0.035 && index+0.008 < middle) || (middle < 0.035 && middle+0.008 < index) {
            reservedUntil = time+0.3
        }
        if needsRelease {
            if index > 0.04 && middle > 0.04 { needsRelease = false }
            return
        }
        if let finger = activeFinger {
            if sample.distance(finger) > 0.04 {
                if !moved && time-startedAt <= 0.3 {
                    if let click = lastClick, click.finger == finger, time-click.time <= 0.4 {
                        if finger == .index { pose = .init(); reset = .spawn }
                        else { pose.orientation = .init(); reset = .orientation }
                        lastClick = nil
                    } else { lastClick = (finger,time) }
                } else { lastClick = nil }
                activeFinger = nil; needsRelease = true
                return
            }
            let delta = sample.point(finger)-startPoint
            if FixtureAiming.length(delta) > 0.015 { moved = true; lastClick = nil }
            guard moved else { return }
            if finger == .index {
                let p = FixtureAiming.vector(startPose.offset) + FixtureAiming.rotate(startPose.orientation,delta)*3
                pose.offset = .init(x: p.x,y: p.y,z: p.z)
            } else {
                let local = FixtureAiming.rotate(FixtureAiming.inverse(self.headBasis),delta)
                let degrees: Float = 3*180 / .pi
                let turn = FixtureAiming.euler(yaw: -local.x*degrees,pitch: local.y*degrees,roll: -local.z*degrees)
                let framed = ViewerNavigationPose.compose(ViewerNavigationPose.compose(self.headBasis,turn),FixtureAiming.inverse(self.headBasis))
                pose.orientation = ViewerNavigationPose.compose(startPose.orientation,framed)
            }
            return
        }
        let finger: NavigationFinger?
        if index < 0.025 && index+0.008 < middle { finger = .index }
        else if middle < 0.025 && middle+0.008 < index { finger = .middle }
        else { finger = nil }
        guard let finger else { return }
        activeFinger = finger; startPoint = sample.point(finger); startPose = pose
        self.headBasis = headBasis; startedAt = time; moved = false
    }
}
