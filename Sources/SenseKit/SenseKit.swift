//
//  SenseKit.swift
//  SenseKit
//
//  Created by Karl Ehrlich on 21.07.24.
//

import Foundation
import CoreMotion

public class SenseKit {
    public struct AltimeterData {
        public var pressure: Double
        public var relativeAltitude: Double
        public var altitude: Double
        public var accuracy: Double
        public var precision: Double
        
        public init(pressure: Double, relativeAltitude: Double, altitude: Double, accuracy: Double, precision: Double) {
            self.pressure = pressure
            self.relativeAltitude = relativeAltitude
            self.altitude = altitude
            self.accuracy = accuracy
            self.precision = precision
        }
    }

    public struct MagneticField {
        public var x: Double
        public var y: Double
        public var z: Double
        
        public init(x: Double, y: Double, z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }

    public struct Quaternion {
        public var x: Double
        public var y: Double
        public var z: Double
        public var w: Double
        
        public init(x: Double, y: Double, z: Double, w: Double) {
            self.x = x
            self.y = y
            self.z = z
            self.w = w
        }
    }

    public struct RotationMatrix {
        public var m11: Double
        public var m12: Double
        public var m13: Double
        public var m21: Double
        public var m22: Double
        public var m23: Double
        public var m31: Double
        public var m32: Double
        public var m33: Double
        
        public init(m11: Double, m12: Double, m13: Double, m21: Double, m22: Double, m23: Double, m31: Double, m32: Double, m33: Double) {
            self.m11 = m11
            self.m12 = m12
            self.m13 = m13
            self.m21 = m21
            self.m22 = m22
            self.m23 = m23
            self.m31 = m31
            self.m32 = m32
            self.m33 = m33
        }
    }

    public struct Acceleration {
        public var x: Double
        public var y: Double
        public var z: Double
        
        public init(x: Double, y: Double, z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }

    public struct RotationRate {
        public var x: Double
        public var y: Double
        public var z: Double
        
        public init(x: Double, y: Double, z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }

    public struct Gravity {
        public var x: Double
        public var y: Double
        public var z: Double
        
        public init(x: Double, y: Double, z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }
}

public class SensorManager: ObservableObject {
    private var altimeter = CMAltimeter()
    private var motionManager = CMMotionManager()
    
    private let altimeterQueue = OperationQueue()
    private let magnetometerQueue = OperationQueue()
    private let accelerometerQueue = OperationQueue()
    private let gyroQueue = OperationQueue()
    private let deviceMotionQueue = OperationQueue()
    
    @Published public var altimeterData = SenseKit.AltimeterData(pressure: 0, relativeAltitude: 0, altitude: 0, accuracy: 0, precision: 0)
    @Published public var magneticField = SenseKit.MagneticField(x: 0, y: 0, z: 0)
    @Published public var quaternion = SenseKit.Quaternion(x: 0, y: 0, z: 0, w: 0)
    @Published public var rotationMatrix = SenseKit.RotationMatrix(m11: 0, m12: 0, m13: 0, m21: 0, m22: 0, m23: 0, m31: 0, m32: 0, m33: 0)
    @Published public var calibratedMagneticField = SenseKit.MagneticField(x: 0, y: 0, z: 0)
    @Published public var acceleration = SenseKit.Acceleration(x: 0, y: 0, z: 0)
    @Published public var userAcceleration = SenseKit.Acceleration(x: 0, y: 0, z: 0)
    @Published public var rotationRate = SenseKit.RotationRate(x: 0, y: 0, z: 0)
    @Published public var calibratedRotationRate = SenseKit.RotationRate(x: 0, y: 0, z: 0)
    @Published public var gravity = SenseKit.Gravity(x: 0, y: 0, z: 0)
    @Published public var pitch: Double = 0.0
    @Published public var yaw: Double = 0.0
    @Published public var roll: Double = 0.0
    @Published public var heading: Double = 0.0

    public init() {}

    public func start() {
        startAltimeter()
        startMotionUpdates()
    }

    public func stop() {
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
