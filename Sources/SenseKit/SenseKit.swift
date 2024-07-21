//
//  SenseKit.swift
//  SenseKit
//
//  Created by Karl Ehrlich on 21.07.24.
//

import Foundation
import CoreMotion

class SenseKit {
    struct AltimeterData {
        var pressure: Double
        var relativeAltitude: Double
        var altitude: Double
        var accuracy: Double
        var precision: Double
    }

    struct MagneticField {
        var x: Double
        var y: Double
        var z: Double
    }

    struct Quaternion {
        var x: Double
        var y: Double
        var z: Double
        var w: Double
    }

    struct RotationMatrix {
        var m11: Double
        var m12: Double
        var m13: Double
        var m21: Double
        var m22: Double
        var m23: Double
        var m31: Double
        var m32: Double
        var m33: Double
    }

    struct Acceleration {
        var x: Double
        var y: Double
        var z: Double
    }

    struct RotationRate {
        var x: Double
        var y: Double
        var z: Double
    }

    struct Gravity {
        var x: Double
        var y: Double
        var z: Double
    }
}

class SensorManager: ObservableObject {
    private var altimeter = CMAltimeter()
    private var motionManager = CMMotionManager()
    
    private let altimeterQueue = OperationQueue()
    private let magnetometerQueue = OperationQueue()
    private let accelerometerQueue = OperationQueue()
    private let gyroQueue = OperationQueue()
    private let deviceMotionQueue = OperationQueue()
    
    @Published var altimeterData = SenseKit.AltimeterData(pressure: 0, relativeAltitude: 0, altitude: 0, accuracy: 0, precision: 0)
    @Published var magneticField = SenseKit.MagneticField(x: 0, y: 0, z: 0)
    @Published var quaternion = SenseKit.Quaternion(x: 0, y: 0, z: 0, w: 0)
    @Published var rotationMatrix = SenseKit.RotationMatrix(m11: 0, m12: 0, m13: 0, m21: 0, m22: 0, m23: 0, m31: 0, m32: 0, m33: 0)
    @Published var calibratedMagneticField = SenseKit.MagneticField(x: 0, y: 0, z: 0)
    @Published var acceleration = SenseKit.Acceleration(x: 0, y: 0, z: 0)
    @Published var userAcceleration = SenseKit.Acceleration(x: 0, y: 0, z: 0)
    @Published var rotationRate = SenseKit.RotationRate(x: 0, y: 0, z: 0)
    @Published var calibratedRotationRate = SenseKit.RotationRate(x: 0, y: 0, z: 0)
    @Published var gravity = SenseKit.Gravity(x: 0, y: 0, z: 0)
    @Published var pitch: Double = 0.0
    @Published var yaw: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var heading: Double = 0.0

    func start() {
        startAltimeter()
        startMotionUpdates()
    }

    func stop() {
        altimeter.stopAbsoluteAltitudeUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
    }

    private func startAltimeter() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: altimeterQueue) { data, error in
                self.handleAltimeterData(data, error: error, isRelative: true)
            }
        }
        if CMAltimeter.isAbsoluteAltitudeAvailable() {
            altimeter.startAbsoluteAltitudeUpdates(to: altimeterQueue) { data, error in
                self.handleAbsoluteAltitudeData(data, error: error)
            }
        }
    }

    private func handleAltimeterData(_ data: CMAltitudeData?, error: Error?, isRelative: Bool) {
        guard let data = data else {
            print(error ?? "Unknown error")
            return
        }
        DispatchQueue.main.async {
            if isRelative {
                self.altimeterData.pressure = data.pressure.doubleValue
                self.altimeterData.relativeAltitude = data.relativeAltitude.doubleValue
            }
        }
    }

    private func handleAbsoluteAltitudeData(_ data: CMAbsoluteAltitudeData?, error: Error?) {
        guard let data = data else {
            print(error ?? "Unknown error")
            return
        }
        DispatchQueue.main.async {
            self.altimeterData.accuracy = data.accuracy
            self.altimeterData.precision = data.precision
            self.altimeterData.altitude = data.altitude
        }
    }

    private func startMotionUpdates() {
        if motionManager.isMagnetometerAvailable {
            motionManager.startMagnetometerUpdates(to: magnetometerQueue) { data, error in
                self.handleMagnetometerData(data, error: error)
            }
        }
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: accelerometerQueue) { data, error in
                self.handleAccelerometerData(data, error: error)
            }
        }
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: gyroQueue) { data, error in
                self.handleGyroData(data, error: error)
            }
        }
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: deviceMotionQueue) { data, error in
                self.handleDeviceMotionData(data, error: error)
            }
        }
    }

    private func handleMagnetometerData(_ data: CMMagnetometerData?, error: Error?) {
        guard let data = data else {
            print(error ?? "Unknown error")
            return
        }
        DispatchQueue.main.async {
            self.magneticField.x = data.magneticField.x
            self.magneticField.y = data.magneticField.y
            self.magneticField.z = data.magneticField.z
        }
    }

    private func handleAccelerometerData(_ data: CMAccelerometerData?, error: Error?) {
        guard let data = data else {
            print(error ?? "Unknown error")
            return
        }
        DispatchQueue.main.async {
            self.acceleration.x = data.acceleration.x
            self.acceleration.y = data.acceleration.y
            self.acceleration.z = data.acceleration.z
        }
    }

    private func handleGyroData(_ data: CMGyroData?, error: Error?) {
        guard let data = data else {
            print(error ?? "Unknown error")
            return
        }
        DispatchQueue.main.async {
            self.rotationRate.x = data.rotationRate.x
            self.rotationRate.y = data.rotationRate.y
            self.rotationRate.z = data.rotationRate.z
        }
    }

    private func handleDeviceMotionData(_ data: CMDeviceMotion?, error: Error?) {
        guard let data = data else {
            print(error ?? "Unknown error")
            return
        }
        DispatchQueue.main.async {
            self.gravity.x = data.gravity.x
            self.gravity.y = data.gravity.y
            self.gravity.z = data.gravity.z
            
            self.pitch = data.attitude.pitch
            self.roll = data.attitude.roll
            self.yaw = data.attitude.yaw
            
            self.calibratedMagneticField.x = data.magneticField.field.x
            self.calibratedMagneticField.y = data.magneticField.field.y
            self.calibratedMagneticField.z = data.magneticField.field.z
            
            self.quaternion.x = data.attitude.quaternion.x
            self.quaternion.y = data.attitude.quaternion.y
            self.quaternion.z = data.attitude.quaternion.z
            self.quaternion.w = data.attitude.quaternion.w
            
            self.rotationMatrix.m11 = data.attitude.rotationMatrix.m11
            self.rotationMatrix.m12 = data.attitude.rotationMatrix.m12
            self.rotationMatrix.m13 = data.attitude.rotationMatrix.m13
            self.rotationMatrix.m21 = data.attitude.rotationMatrix.m21
            self.rotationMatrix.m22 = data.attitude.rotationMatrix.m22
            self.rotationMatrix.m23 = data.attitude.rotationMatrix.m23
            self.rotationMatrix.m31 = data.attitude.rotationMatrix.m31
            self.rotationMatrix.m32 = data.attitude.rotationMatrix.m32
            self.rotationMatrix.m33 = data.attitude.rotationMatrix.m33
            
            self.heading = data.heading
            
            self.calibratedRotationRate.x = data.rotationRate.x
            self.calibratedRotationRate.y = data.rotationRate.y
            self.calibratedRotationRate.z = data.rotationRate.z
            
            self.userAcceleration.x = data.userAcceleration.x
            self.userAcceleration.y = data.userAcceleration.y
            self.userAcceleration.z = data.userAcceleration.z
        }
    }
}
