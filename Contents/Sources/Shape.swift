//
//  Shape.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport

public typealias Image = UIImage

public class Shape: PlaceableObject {
    
    private let maximumImageSize = CGSize(width: 1024, height: 1024)
    
    public let shapeType: ShapeType
    
    public var color: UIColor = UIColor.lightGray {
        
        didSet {
            
            guard let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else { return }
            
            proxy.send(
                PlaygroundMessageToLiveView.setObjectColor(object: self, color: color).playgroundValue
            )
        }
    }
    
    public var image: Image = UIImage() {
        
        didSet {
            
            guard (image.size.width > 0) && (image.size.height > 0) else { return }
            
            // If image does not fit within maximumImageSize, then scale it so that it does.
            // This also has the benefit of setting image orientation to its default (up).
            var desiredImageSize = image.size
            if (image.size.width > maximumImageSize.width) || (image.size.height > maximumImageSize.height) {
                desiredImageSize = maximumImageSize
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                let newImage = self.image.scaledToFit(within: desiredImageSize)
                
                DispatchQueue.main.async {
                    
                    guard let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else { return }
                    
                    proxy.send(
                        PlaygroundMessageToLiveView.setObjectImage(object: self, image: newImage).playgroundValue
                    )
                }
            }
        }
    }
    
    public init(type: ShapeType) {
        shapeType = type
        super.init()
        self.name = shapeType.rawValue
        self.type = VirtualObjectType.shape
    }

    // MARK: - Codable implementation.

    private enum CodingKeys: String, CodingKey {
        case shapeType
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        shapeType = try values.decode(ShapeType.self, forKey: .shapeType)

        try super.init(from: decoder)
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shapeType, forKey: .shapeType)
    }
}
