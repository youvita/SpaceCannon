//
//  SKMenu.swift
//  SKSpaceCannon
//
//  Created by Chan Youvita on 6/12/15.
//  Copyright (c) 2015 Kosign. All rights reserved.
//

import UIKit
import SpriteKit

class SKMenu: SKNode {
    let title         = SKSpriteNode(imageNamed: "Title")
    let scoreBoard    = SKSpriteNode(imageNamed: "ScoreBoard")
    let playButton    = SKSpriteNode(imageNamed: "PlayButton")
    let scoreLabel    = SKLabelNode(fontNamed: "DIN Alternate")
    let scoreTopLabel = SKLabelNode(fontNamed: "DIN Alternate")
    
    var musicButton        : SKSpriteNode = SKSpriteNode()

    
    // Setter and Getter score
    internal var scoreValue : Int = 0
    internal var score : Int {
        get{
            return scoreValue
        }
        set {
            
            if (newValue >= 0) {
                scoreValue      = newValue
                scoreLabel.text = "\(scoreValue)"
            }
        }
    }
    
    // Setter and Getter score top
    internal var scoreValueTop : Int = 0
    internal var scoreTop : Int {
        get{
            return scoreValueTop
        }
        set {
            
            if (newValue >= 0) {
                scoreValueTop      = newValue
                scoreTopLabel.text = "\(scoreValueTop)"
            }
        }
    }
    
    /* Properties Music Player */
    internal var musicPlaying : Bool = false {
        didSet{
            if musicPlaying {
                musicButton.texture = SKTexture(imageNamed: "MusicOnButton")
            }else{
                musicButton.texture = SKTexture(imageNamed: "MusicOffButton")
            }
        }
    }

    
    internal var touchable : Bool = false {
        didSet{
            if touchable {
                
                /* Make menu hide and animation */
                let animateMenu = SKAction.scaleTo(0.0, duration: 0.5)
                animateMenu.timingMode = SKActionTimingMode.EaseIn
                self.runAction(SKAction.sequence([animateMenu,SKAction.runBlock({
                    self.xScale = 1.0
                    self.yScale = 1.0
                    self.hidden    = true
                })
                    ]))
                
            }else{
                self.hidden    = false
                
                /* Make menu show and animation */
                let fadeIn = SKAction.fadeInWithDuration(0.5)
                
                let animateTitle = SKAction.group([SKAction.moveToY(140, duration: 0.5),fadeIn])
                animateTitle.timingMode = SKActionTimingMode.EaseOut
                title.runAction(animateTitle)
                
                scoreBoard.xScale = 4.0
                scoreBoard.yScale = 4.0
                scoreBoard.alpha  = 0.0
                let animateBoard = SKAction.group([SKAction.scaleTo(1.0, duration: 0.5),fadeIn])
                animateBoard.timingMode = SKActionTimingMode.EaseOut
                scoreBoard.runAction(animateBoard)
                
                playButton.alpha = 0.0
                let animatePlayButton = SKAction.fadeInWithDuration(2.0)
                playButton.runAction(animatePlayButton)
                
                musicButton.alpha = 0.0
                musicButton.runAction(animatePlayButton)
            }
        }
    }
    
    
    override init() {
        super.init()
        title.position = CGPointMake(0, 140)
        self.addChild(title)
        
        scoreBoard.position = CGPointMake(0, 70)
        self.addChild(scoreBoard)
        
        playButton.position = CGPointMake(0, 0)
        playButton.name     = "Play"
        self.addChild(playButton)
        
        scoreLabel.fontSize = 30;
        scoreLabel.position = CGPointMake(-52, -20);
        scoreBoard.addChild(scoreLabel)
        
        scoreTopLabel.fontSize = 30;
        scoreTopLabel.position = CGPointMake(48, -20);
        scoreBoard.addChild(scoreTopLabel)
        
        self.score = 0;
        self.scoreTop = 0;
        
        // Setup Button Music Off / On
        musicButton          = SKSpriteNode(imageNamed: "MusicOnButton")
        musicButton.name     = "Music"
        musicButton.position = CGPointMake(90, 0)
        self.addChild(musicButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
