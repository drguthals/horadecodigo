//
//  VirtualObject.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

enum VirtualObjectType: String, Codable {
    case unknown
    case actor
    case gem
    case shape
}

public class VirtualObject: SCNNode {
    
    var type: VirtualObjectType { return .unknown }
    
    var placeableObject: PlaceableObject {
        let object = PlaceableObject()
        object.type = self.type
        object.id = self.id
        return object
    }
    
    var id: String = UUID().uuidString
    var viewController: LiveViewController?
    var path: String = ""
    var modelName: String = ""
    var fileExtension: String = ""
    var isModelLoaded: Bool = false
    var relativePosition: SCNVector3 = SCNVector3Make(0, 0, 0)
    
    // All subclasses should implement this
    var customAccessibilityDescription: String {
        fatalError()
    }
    
    /*
     Boolean which indicates the user (and therefore the under-the-covers code)
     has actually *placed* the object in the scene, which means it's visible. It
     is possible for the user to create objects and edit their properties without
     actually placing them, and we need to track that difference. Hence this prop.
     */
    var hasBeenPlaced = false
    
    var virtualObjectRotation: Float {
        get {
            if self.hasBuiltInLightSources {
                return self.childNodes.first!.childNodes.first!.eulerAngles.y
            } else {
                return self.eulerAngles.y
            }
        }
        set(newValue) {
            if self.hasBuiltInLightSources {
                self.childNodes.first!.childNodes.first!.eulerAngles.y = newValue
            } else {
                self.eulerAngles.y = newValue
            }
        }
    }
    
    override init() {
        super.init()
        initialize(id: id)
    }
    
    init(path: String, modelName: String, fileExtension: String, id: String? = nil) {
        super.init()
        initialize(id: id)
        self.path = path
        self.modelName = modelName
        self.fileExtension = fileExtension
    }
    
    init(title: String, id: String? = nil) {
        super.init()
        initialize(id: id)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize(id: String?) {
        if let id = id {
            self.id = id
        } else {
            self.id = UUID().uuidString
        }
        self.name = "Virtual object root node"
    }
    
    func loadModel() {
        
        guard !path.isEmpty && !modelName.isEmpty else { return }
        
        guard let virtualObjectScene = SCNScene(named: "\(modelName).\(fileExtension)", inDirectory: "\(path)/") else {
            return
        }
        
        let wrapperNode = SCNNode()
        
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            child.movabilityHint = .movable
            wrapperNode.addChildNode(child)
        }
        self.addChildNode(wrapperNode)
        
        isModelLoaded = true
    }
    
    func unloadModel() {
        for child in self.childNodes {
            child.removeFromParentNode()
        }
        lightSourcesAndOriginalIntensities.removeAll()
        
        isModelLoaded = false
    }
    
    var hasBuiltInLightSources: Bool {
        return !lightSourcesAndOriginalIntensities.isEmpty
    }
    
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }

    /// - Tag: AdjustOntoPlaneAnchor
    func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) {
        // Get the object's position in the plane's coordinate system.
        let planePosition = node.convertPosition(position, from: parent)
        
        // Check that the object is not already on the plane.
        guard planePosition.y != 0 else { return }
        
        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1
        
        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        
        // Move onto the plane if it is near it (within 5 centimeters).
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }
    
    // MARK: Private
    
    var lightSourcesAndOriginalIntensities: [SCNLight : CGFloat] = [:]
    
    func prepareLightSourcesForAmbientLightEstimation() {
        // Retrieve all light nodes and store a reference to them to be able to update their intensity
        for node in self.childNodes(passingTest: { (node, _) in node.light != nil }) {
            let light = node.light!
            lightSourcesAndOriginalIntensities[light] = light.intensity
        }
    }
}

// MARK: - Protocols for Virtual Objects

protocol ReactsToRendering {
    func reactToRendering()
}

