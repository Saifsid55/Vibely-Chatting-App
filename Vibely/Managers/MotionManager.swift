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

    init() {
        startUpdates()
    }

    func startUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 fps
            motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
                guard let motion = motion else { return }
                self.pitch = motion.attitude.pitch
                self.roll = motion.attitude.roll
            }
        }
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
