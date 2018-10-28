//
//  PlaygroundMessageToLiveView.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit

/// An enumeration of messages that can be sent to the live view.
public enum PlaygroundMessageToLiveView: PlaygroundMessage {

    case enableCameraVision
    case placeObjectOnPlane(object: PlaceableObject, plane: Plane, position: Point)
    case setObjectColor(object: PlaceableObject, color: UIColor)
    case setObjectImage(object: PlaceableObject, image: UIImage?)
    case setActorActions(actor: PlaceableObject, trigger: Trigger, actions: [ActorAction])
    case announceObjectPlacement(objects: [PlaceableObject])

    // MARK: PlaygroundMessage implementation.

    public enum MessageType: String, PlaygroundMessageType {
        case enableCameraVision
        case placeObjectOnPlane
        case setObjectColor
        case setObjectImage
        case setActorActions
        case announceObjectPlacement
    }

    public var messageType: MessageType {
        switch self {
        case .enableCameraVision:
            return .enableCameraVision
        case .placeObjectOnPlane(object:plane:position:):
            return .placeObjectOnPlane
        case .setObjectColor(object:color:):
            return .setObjectColor
        case .setObjectImage(object:image:):
            return .setObjectImage
        case .setActorActions(actor:actions:):
            return .setActorActions
        case .announceObjectPlacement(objects:):
            return .announceObjectPlacement
        }
    }

    public init?(messageType: MessageType, encodedPayload: Data?) {
        
        let decoder = JSONDecoder()
        
        switch messageType {
            
        case .enableCameraVision:
            self = .enableCameraVision

        case .placeObjectOnPlane:
            guard
                let encodedPayload = encodedPayload,
                let payload = try? decoder.decode(PlaceObjectOnPlanePayload.self, from: encodedPayload)
                else {
                    return nil
            }
            self = .placeObjectOnPlane(object: payload.object, plane: payload.plane, position: payload.position)
        
        case .setObjectColor:
            guard
                let encodedPayload = encodedPayload,
                let payload = try? decoder.decode(ObjectColorPayload.self, from: encodedPayload)
                else {
                    return nil
            }
            self = .setObjectColor(object: payload.object, color: payload.color.color)

        case .setObjectImage:
            guard
                let encodedPayload = encodedPayload,
                let payload = try? decoder.decode(ObjectImagePayload.self, from: encodedPayload)
                else {
                    return nil
            }
            self = .setObjectImage(object: payload.object, image: UIImage(data: payload.imageData))
            
        case .setActorActions:
            guard
                let encodedPayload = encodedPayload,
                let payload = try? decoder.decode(ActorActionsPayload.self, from: encodedPayload)
                else {
                    return nil
            }
            self = .setActorActions(actor: payload.actor, trigger: payload.trigger, actions: payload.actions)
            
        case .announceObjectPlacement:
            guard
                let encodedPayload = encodedPayload,
                let payload = try? decoder.decode(ObjectsPlacedPayload.self, from: encodedPayload)
                else {
                    return nil
            }
            self = .announceObjectPlacement(objects: payload.objects)
        }
    }

    public func encodePayload() -> Data? {
        
        let encoder = JSONEncoder()
        
        switch self {
            
        case .enableCameraVision:
            return nil
            
        case let .placeObjectOnPlane(object: object, plane: plane, position: position):
            let payload = PlaceObjectOnPlanePayload(object: object, plane: plane, position: position)
            return try! encoder.encode(payload)
            
        case let .setObjectColor(object: object, color: color):
            let payload = ObjectColorPayload(object: object, color: CodableColor(color))
            return try! encoder.encode(payload)
            
        case let .setObjectImage(object: object, image: image):
            guard
                let image = image,
                let data = (UIImagePNGRepresentation(image))
                else { return nil }
            let payload = ObjectImagePayload(object: object, imageData: data)
            return try! encoder.encode(payload)
            
        case let .setActorActions(actor: actor, trigger: trigger, actions: actions):
            let payload = ActorActionsPayload(actor: actor, trigger: trigger, actions: actions)
            
            do {
                return try encoder.encode(payload)
            } catch let (error) {
                fatalError("\(error)")
            }
            
        case let .announceObjectPlacement(objects: objects):
            let payload = ObjectsPlacedPayload(objects: objects)
            return try! encoder.encode(payload)
        }
    }
}
