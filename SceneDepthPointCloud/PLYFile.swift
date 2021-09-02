//
//  PLYFile.swift
//  SceneDepthPointCloud

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

final class PLYFile {
    static func write(fileName: String,
                      cpuParticlesBuffer: inout [CPUParticle],
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
            try writeAscii(file: plyFile, cpuParticlesBuffer: &cpuParticlesBuffer)
        } else {
            try writeBinary(file: plyFile, format: format, cpuParticlesBuffer: &cpuParticlesBuffer)
        }
        
        return plyFile
    }
    
    private static func arrangeColorByte(color: simd_float1) -> UInt8 {
        /// Convert [0, 255] Float32 to UInt8
        let absColor = abs(Int16(color))
        return absColor <= 255 ? UInt8(absColor) : UInt8(255)
    }
    
    private static func writeBinary(file: URL, format: String, cpuParticlesBuffer: inout [CPUParticle]) throws -> Void {
        let fileHandle = try! FileHandle(forWritingTo: file)
        fileHandle.seekToEndOfFile()
        var data = Data()
        
        for particle in cpuParticlesBuffer {
            if particle.confidence != 2 { continue }
            
            if format == "binary_little_endian" {
                var x = particle.position.x.bitPattern.littleEndian
                data.append(withUnsafePointer(to: &x) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var y = particle.position.y.bitPattern.littleEndian
                data.append(withUnsafePointer(to: &y) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var z = particle.position.z.bitPattern.littleEndian
                data.append(withUnsafePointer(to: &z) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                let colors = particle.color
                var red = arrangeColorByte(color: colors.x).littleEndian
                data.append(withUnsafePointer(to: &red) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var green = arrangeColorByte(color: colors.y).littleEndian
                data.append(withUnsafePointer(to: &green) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var blue = arrangeColorByte(color: colors.z).littleEndian
                data.append(withUnsafePointer(to: &blue) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var alpha = UInt8(255).littleEndian
                data.append(withUnsafePointer(to: &alpha) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
            } else {
                var x = particle.position.x.bitPattern.bigEndian
                data.append(withUnsafePointer(to: &x) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var y = particle.position.y.bitPattern.bigEndian
                data.append(withUnsafePointer(to: &y) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var z = particle.position.z.bitPattern.bigEndian
                data.append(withUnsafePointer(to: &z) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                let colors = particle.color
                var red = arrangeColorByte(color: colors.x).bigEndian
                data.append(withUnsafePointer(to: &red) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var green = arrangeColorByte(color: colors.y).bigEndian
                data.append(withUnsafePointer(to: &green) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var blue = arrangeColorByte(color: colors.z).bigEndian
                data.append(withUnsafePointer(to: &blue) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
                
                var alpha = UInt8(255).bigEndian
                data.append(withUnsafePointer(to: &alpha) {
                    Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
                })
            }
        }
        fileHandle.write(data)
        fileHandle.closeFile()
    }
    
    private static func writeAscii(file: URL, cpuParticlesBuffer: inout [CPUParticle]) throws  -> Void {
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
