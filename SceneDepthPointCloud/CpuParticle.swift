//
//  CpuParticle.swift
//  SceneDepthPointCloud
//

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
