//
//  MotionManager.swift
//  Vibely
//
//  Created by Mohd Saif on 25/10/25.
//

import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    var motionEnabled = false

    init(enableMotion: Bool = false) {
        self.motionEnabled = enableMotion
        if enableMotion {
            startUpdates()
        }
    }

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion else { return }
            self.pitch = motion.attitude.pitch
            self.roll = motion.attitude.roll
        }
    }

    func stopUpdate() {
        motionManager.stopDeviceMotionUpdates()
    }

    deinit {
        stopUpdate()
    }
}
