//
//  PLYFile.swift
//  SceneDepthPointCloud
//
//  Created by Ryan Phillips on 8/2/21.
//  Copyright © 2021 Apple. All rights reserved.
//

/*
 PLY File Scalar Byte Counts
 http://paulbourke.net/dataformats/ply/
 
 name        type        number of bytes
 ---------------------------------------
 char       character                 1
 uchar      unsigned character        1
 short      short integer             2
 ushort     unsigned short integer    2
 int        integer                   4
 uint       unsigned integer          4
 float      single-precision float    4
 double     double-precision float    8
 */

import Foundation

final class CPUParticle {
    var position: simd_float3
    var color: simd_float3
    var confidence: Float
    
    init(position: simd_float3, color: simd_float3, confidence: Float) {
        self.position = position
        self.color = color * 255
        self.confidence = confidence
    }
}

final class PLYFile {
    static func write(fileName: String,
                      cpuParticlesBuffer: [CPUParticle],
                      highConfCount: Int,
                      format: String) throws -> URL {
        
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let plyFile = documentsDirectory.appendingPathComponent(
            "\(fileName)_\(Date().description(with: .current)).ply", isDirectory: false)
        FileManager.default.createFile(atPath: plyFile.path, contents: nil, attributes: nil)
        
        var headersString = ""
        let headers = [
            "ply",
            "comment Created by SceneX (IOS)",
            "format \(format) 1.0",
            "element vertex \(highConfCount)",
            "property float x",
            "property float y",
            "property float z",
            "property uchar red",
            "property uchar green",
            "property uchar blue",
            "property uchar alpha",
            "element face 0",
            "property list uchar int vertex_indices",
            "end_header"]
        
        for header in headers { headersString += header + "\r\n" }
        try headersString.write(to: plyFile, atomically: true, encoding: .ascii)
        
        if format == "ascii" {
            try writeAscii(file: plyFile, cpuParticlesBuffer: cpuParticlesBuffer)
        } else {
            try writeBinary(file: plyFile, format: format, cpuParticlesBuffer: cpuParticlesBuffer)
        }
        
        return plyFile
    }
    
    private static func arrangeColorByte(color: simd_float1) -> UInt8 {
        /// Convert Float32 o UIn8 tbis is possible because rgb colors have a max value of 255 which is 1 byte
        let absColor = abs(Int16(color))
        return absColor <= 255 ? UInt8(absColor) : UInt8(255)
    }
    
    private static func writeBinary(file: URL, format: String, cpuParticlesBuffer: [CPUParticle]) throws -> Void {
        let fileHandle = try! FileHandle(forWritingTo: file)
        fileHandle.seekToEndOfFile()
        for particle in cpuParticlesBuffer {
            if particle.confidence != 2 { continue }
            
            if format == "binary_little_endian" {
                var x = particle.position.x.bitPattern.littleEndian
                let leX = withUnsafePointer(to: &x) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leX)
                fileHandle.seekToEndOfFile()
                
                var y = particle.position.y.bitPattern.littleEndian
                let leY = withUnsafePointer(to: &y) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leY)
                fileHandle.seekToEndOfFile()
                
                var z = particle.position.z.bitPattern.littleEndian
                let leZ = withUnsafePointer(to: &z) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leZ)
                fileHandle.seekToEndOfFile()
                
                let colors = particle.color
                
                var red = arrangeColorByte(color: colors.x).littleEndian
                let leRed = withUnsafePointer(to: &red) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leRed)
                fileHandle.seekToEndOfFile()
                
                var green = arrangeColorByte(color: colors.y).littleEndian
                let leGreen = withUnsafePointer(to: &green) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leGreen)
                fileHandle.seekToEndOfFile()
                
                var blue = arrangeColorByte(color: colors.z).littleEndian
                let leBlue = withUnsafePointer(to: &blue) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leBlue)
                fileHandle.seekToEndOfFile()
                
                var alpha = UInt8(255).littleEndian
                let leAlpha = withUnsafePointer(to: &alpha) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leAlpha)
                fileHandle.seekToEndOfFile()

            } else {
                var x = particle.position.x.bitPattern.bigEndian
                let leX = withUnsafePointer(to: &x) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leX)
                fileHandle.seekToEndOfFile()
                
                var y = particle.position.y.bitPattern.bigEndian
                let leY = withUnsafePointer(to: &y) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leY)
                fileHandle.seekToEndOfFile()
                
                var z = particle.position.z.bitPattern.bigEndian
                let leZ = withUnsafePointer(to: &z) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leZ)
                fileHandle.seekToEndOfFile()
                
                let colors = particle.color
                
                var red = arrangeColorByte(color: colors.x).bigEndian
                let leRed = withUnsafePointer(to: &red) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leRed)
                fileHandle.seekToEndOfFile()
                
                var green = arrangeColorByte(color: colors.y).bigEndian
                let leGreen = withUnsafePointer(to: &green) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leGreen)
                fileHandle.seekToEndOfFile()
                
                var blue = arrangeColorByte(color: colors.z).bigEndian
                let leBlue = withUnsafePointer(to: &blue) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leBlue)
                fileHandle.seekToEndOfFile()
                
                var alpha = UInt8(255).bigEndian
                let leAlpha = withUnsafePointer(to: &alpha) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                }
                fileHandle.write(leAlpha)
                fileHandle.seekToEndOfFile()
            }
        }
        fileHandle.closeFile()
        
    }
    
    private static func writeAscii(file: URL, cpuParticlesBuffer: [CPUParticle]) throws  -> Void {
        var vertexStrings = ""
        for particle in cpuParticlesBuffer {
            if particle.confidence != 2 { continue }
            let colors = particle.color
            let red = Int(colors.x)
            let green = Int(colors.y)
            let blue = Int(colors.z)
            let x = particle.position.x
            let y = particle.position.y
            let z = particle.position.z
            let pValue =  "\(x) \(y) \(z) \(red) \(green) \(blue) 255" + "\r\n"
            vertexStrings += pValue
        }
        
        let fileHandle = try FileHandle(forWritingTo: file)
        fileHandle.seekToEndOfFile()
        fileHandle.write(vertexStrings.data(using: .ascii)!)
        fileHandle.closeFile()
    }
}
