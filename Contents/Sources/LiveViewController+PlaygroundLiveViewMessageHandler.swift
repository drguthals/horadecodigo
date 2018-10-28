//
//  LiveViewController+PlaygroundLiveViewMessageHandler.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import PlaygroundSupport
import UIKit

extension LiveViewController: PlaygroundLiveViewMessageHandler {
    
    public func liveViewMessageConnectionClosed() {
        // Once the user taps "Stop", re-show the focus square
        focusSquare.unhide()
    }
    
    public func liveViewMessageConnectionOpened() {
        // Reset the scene whenever user taps "Run My Code"
        restartExperience()
        
        // Automatic VoiceOver to remind user to move iPad
        let axPlaneDetection = NSLocalizedString("Move the iPad around to detect planes.", comment: "Basic plane detection instructions")
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, axPlaneDetection)
    }
    
    public func receive(_ message: PlaygroundValue) {
        
        guard let liveViewMessage = PlaygroundMessageToLiveView(playgroundValue: message) else { return }
        
        switch liveViewMessage {
            
        case .enableCameraVision:
            break
        case let .placeObjectOnPlane(object: object, plane: plane, position: position):
            
            guard let livePlane = self.planeWith(id: plane.id) else {
                log(message: "Unable to find plane with id: \(plane.id)")
                return
            }
            
            guard let virtualObject = self.getVirtualObject(for: object) else {
                log(message: "Failed to find or create \(object.name) object with id: \(object.id)")
                return
            }
            
            self.placeObject(object: virtualObject, on: livePlane, at: position)
            
        case let .setObjectColor(object: object, color: color):
            
            guard let shape = self.getVirtualObject(for: object) as? LiveShape else {
                log(message: "Failed to find or create shape with name: \(object.name) id: \(object.id)")
                return
            }
            
            shape.color = color
            
        case let .setObjectImage(object: object, image: image):
            
            guard let image = image else {
                log(message: "Nil image passed to live view")
                return
            }
            
            guard let shape = self.getVirtualObject(for: object) as? LiveShape else {
                log(message: "Failed to find or create shape with name: \(object.name) id: \(object.id)")
                return
            }
            
            shape.image = image
        case .setActorActions(let actor, let trigger, let actions):
            guard let virtualActor = self.getVirtualObject(for: actor) as? LiveActor else {
                fatalError("Failed to find or create \(actor.name) object with id: \(actor.id) as Actor")
            }
            
            switch trigger {
            case .reactBehind:
                virtualActor.behindActions += actions
            case .reactRight:
                virtualActor.turnRightActions += actions
            case .reactLeft:
                virtualActor.turnLeftActions += actions
            case .reactTooClose:
                virtualActor.tooCloseActions += actions
            }
            
        case .announceObjectPlacement(let objects):
            announceObjectPlacement(objects: objects)
        }
    }
}
