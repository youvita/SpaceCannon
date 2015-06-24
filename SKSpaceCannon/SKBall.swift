//
//  SKBall.swift
//  SKSpaceCanon
//
//  Created by Chan Youvita on 6/10/15.
//  Copyright (c) 2015 Kosign. All rights reserved.
//

import UIKit
import SpriteKit

class SKBall: SKSpriteNode {
    var trail : SKEmitterNode!
    var bounces : Int = 0
    
    func updateTrail(){
        if self.trail != nil {
            self.trail.position = self.position
        }
    }
    
    override func removeFromParent() {
        if self.trail != nil {
            self.trail.particleBirthRate = 0.0
            let effectDuration = Double(self.trail!.particleLifetime + self.trail!.particleLifetimeRange)
            let removeTrail = SKAction.sequence([SKAction.waitForDuration(effectDuration), SKAction.removeFromParent()])
            self.runAction(removeTrail)
        }
        
        super.removeFromParent()
    }

}
