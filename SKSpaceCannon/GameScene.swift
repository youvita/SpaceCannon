//
//  GameScene.swift
//  SKSpaceCannon
//
//  Created by Chan Youvita on 6/12/15.
//  Copyright (c) 2015 Kosign. All rights reserved.
//

import SpriteKit
import AVFoundation

struct Halo {
    static let kSKHaloLowAngle  : CGFloat = CGFloat(200.0 * M_PI / 180.0)
    static let kSKHaloHighAngle : CGFloat = CGFloat(340.0 * M_PI / 180.0)
    static let kSKHaloSpeed     : CGFloat = 100.0
}

/*
* Category note for halo , ball or edge
* 0 - Halo , 1 - Ball , 2 - Edge
*/
struct Category {
    static let kSKHaloCategory      : UInt32 = 0x1 << 0
    static let kSKBallCategory      : UInt32 = 0x1 << 1
    static let kSKEdgeCategory      : UInt32 = 0x1 << 2
    static let kSKShieldsCategory   : UInt32 = 0x1 << 3
    static let kSKLifeBarCategory   : UInt32 = 0x1 << 4
    static let kSKShieldsUpCategory : UInt32 = 0x1 << 5
    static let kSKMultiUpCategory   : UInt32 = 0x1 << 6
}


class GameScene: SKScene , SKPhysicsContactDelegate{
    
    // Variable Properties
    var mainLayerGame      : SKNode?
    var cannonGame         : SKSpriteNode = SKSpriteNode()
    var ammonDisplay       : SKSpriteNode = SKSpriteNode()
    var lifeBar            : SKSpriteNode = SKSpriteNode()
    var backgroundGame     : SKSpriteNode = SKSpriteNode()
    var pauseButton        : SKSpriteNode = SKSpriteNode()
    var resumeButton       : SKSpriteNode = SKSpriteNode()
        
    var scoreLabel         : SKLabelNode  = SKLabelNode()
    var pointLabel         : SKLabelNode  = SKLabelNode()
    
    // Sounds Game
    var bounceSound        : SKAction = SKAction()
    var deepExplosionSound : SKAction = SKAction()
    var explosionSound     : SKAction = SKAction()
    var laserSound         : SKAction = SKAction()
    var zapSound           : SKAction = SKAction()
    var shieldUpSound      : SKAction = SKAction()
    
    var isGameOver         : Bool     = Bool()
    var shootSpeed         : CGFloat  = 1000.0
    var killCount          : Int      = 0
    
    var shieldPool         : NSMutableArray!
    var mainMenu           : SKMenu = SKMenu()
    
    var audioPlayer        : AVAudioPlayer = AVAudioPlayer()
    
    // Setter amount ball
    private var ammonValue : Int = 0
    private var ammon : Int {
        get{
            return ammonValue
        }
        set {
            if newValue >= 0 && newValue <= 5{
                println("new ----> \(newValue)")
                ammonValue = newValue
                ammonDisplay.texture = SKTexture(imageNamed: "Ammo\(ammonValue)")
            }
        }
    }
    
    
    // Setter and Getter Score
    private var scoreValue : Int    = 0
    private var score : Int {
        get{
            return scoreValue
        }
        set {
            
            if (newValue >= 0) {
                scoreValue      = newValue
                scoreLabel.text = "Score:\(scoreValue)"
            }
        }
    }
    
    // Setter and Getter Point
    private var pointValue : Int    = 0
    private var point : Int {
        get{
            return pointValue
        }
        set {
            
            if (newValue >= 0) {
                pointValue      = newValue
                pointLabel.text = "Score:\(pointValue)"
            }
        }
    }
    
    // Setter multiUp image
    private var multiMode : Bool = false{
        didSet {
            if multiMode {
                cannonGame.texture = SKTexture(imageNamed: "GreenCannon")
            }else{
                cannonGame.texture = SKTexture(imageNamed: "Cannon")
            }
        }
    }
    
    // Setter did shooting
    private var didShoot : Bool = false{
        didSet {
            if didShoot {
                var avarialbeAmmon : Int = 2
                for node : SKNode in mainLayerGame?.children as! [SKNode]{
                    if node.name == "ball" {
                        avarialbeAmmon--
                    }
                }
                
                // Condition shoot 2time per secornd
                if avarialbeAmmon > 0 {
                    makeShoot()
                }
            }
        }
    }
    
    internal var gamePause : Bool = false {
        didSet{
            if !isGameOver{
                self.pauseButton.hidden  = gamePause
                self.resumeButton.hidden = !gamePause
                self.paused              = gamePause
            }
        }
    }
    
      
    // MARK: - Initalzie method
    override init(size: CGSize) {
        super.init(size:size)
        
        // Turn off gravity
        self.physicsWorld.gravity         = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self // set delegate self
        
        
        // Add background image game
        backgroundGame             = SKSpriteNode(imageNamed: "Starfield")
        backgroundGame.position    = CGPointZero
        backgroundGame.anchorPoint = CGPointZero
        backgroundGame.blendMode   = SKBlendMode.Replace
        self.addChild(backgroundGame)
        
        // Main Layer Game
        mainLayerGame = SKNode()
        self.addChild(mainLayerGame!)
        
        //////////////////////////////////////////////////////
        // Create Main Menu
        mainMenu.position = CGPointMake(self.size.width * 0.5, self.size.height - 220);
        self.addChild(mainMenu)
        //////////////////////////////////////////////////////
        
        
        /* Add player cannon image game */
        cannonGame          = SKSpriteNode(imageNamed: "Cannon")
        cannonGame.position = CGPointMake(self.size.width * 0.5, 0.0)
        mainLayerGame!.addChild(cannonGame)
        
        // Move Roation repeat 180
        let cannonRotation = SKAction.sequence([
            SKAction.rotateByAngle(CGFloat(Float(M_PI)), duration: 2),
            SKAction.rotateByAngle(-CGFloat(Float(M_PI)), duration: 2)])
        cannonGame.runAction(SKAction.repeatActionForever(cannonRotation))
        
        /* Setup limited ball */
        ammonDisplay             = SKSpriteNode(imageNamed: "Ammo5")
        ammonDisplay.anchorPoint = CGPointMake(0.5, 0.0)
        ammonDisplay.position    = cannonGame.position
        mainLayerGame?.addChild(ammonDisplay)
        
        /* Create life bar */
        lifeBar                              = SKSpriteNode(imageNamed: "BlueBar")
        lifeBar.position                     = CGPointMake(self.size.width * 0.5, cannonGame.size.height/2)
        lifeBar.physicsBody                  = SKPhysicsBody(edgeFromPoint: CGPointMake(-lifeBar.size.width * 0.5, 0), toPoint: CGPointMake(lifeBar.size.width * 0.5, 0))
        lifeBar.physicsBody?.categoryBitMask = Category.kSKLifeBarCategory
        mainLayerGame?.addChild(lifeBar)
        
        
        // Add edges
        var leftEdge                            = SKNode()
        leftEdge.physicsBody                    = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, self.size.height))
        leftEdge.position                       = CGPointZero
        leftEdge.physicsBody?.categoryBitMask   = Category.kSKEdgeCategory
        self.addChild(leftEdge)
        
        var rightEdge                           = SKNode()
        rightEdge.physicsBody                   = SKPhysicsBody(edgeFromPoint: CGPointZero, toPoint: CGPointMake(0.0, self.size.height))
        rightEdge.position                      = CGPointMake(self.size.width, 0.0)
        rightEdge.physicsBody?.categoryBitMask  = Category.kSKEdgeCategory
        self.addChild(rightEdge)
        
        // Create Sqwan
        let spawnHalo = SKAction.sequence([
            SKAction.runBlock(self.spawnHalo),
            SKAction.waitForDuration(1)
            ])
        runAction(SKAction.repeatActionForever(spawnHalo), withKey: "SpawnHalo")
        
        let incrementAmmo = SKAction.sequence([
            SKAction.waitForDuration(1),
            SKAction.runBlock({
                if !self.multiMode {
                    self.ammon++
                }
                
            })])
        runAction(SKAction.repeatActionForever(incrementAmmo))
        
        
        //////////////////////////////////////////////////////////////////////////
        // Setup label score display
        scoreLabel = SKLabelNode(fontNamed: "DIN Alternate")
        scoreLabel.position = CGPointMake(15, 10)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabel.fontSize = 15
        scoreLabel.text     = "Score:\(0)"
        self.addChild(scoreLabel)
        
        // Setup point label score display
        pointLabel = SKLabelNode(fontNamed: "DIN Alternate")
        pointLabel.position = CGPointMake(15, 30)
        pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        pointLabel.fontSize = 15
        pointLabel.text     = "Points: x\(0)"
        self.addChild(pointLabel)
        //////////////////////////////////////////////////////////////////////////
        
        // Setup Sounds
        laserSound         = SKAction.playSoundFileNamed("Laser.caf", waitForCompletion:false) // ball shoot
        bounceSound        = SKAction.playSoundFileNamed("Bounce.caf", waitForCompletion:false) // ball bounce hit edge
        deepExplosionSound = SKAction.playSoundFileNamed("DeepExplosion.caf", waitForCompletion:false) // explosion halo hit shied (block)
        explosionSound     = SKAction.playSoundFileNamed("Explosion.caf", waitForCompletion:false) // explosion ball hit halo
        zapSound           = SKAction.playSoundFileNamed("Zap.caf", waitForCompletion:false) // halo hit edge
        shieldUpSound      = SKAction.playSoundFileNamed("ShieldUp.caf", waitForCompletion:false) // ball hit shieldup
        
        
        // Init Value
        self.actionForKey("SpawnHalo")?.speed = 1 // increas spawn speed
        isGameOver = true
        
        // Load top score
        let topScore = NSUserDefaults.standardUserDefaults()
        if let storeScore = topScore.integerForKey("Score") as Int? {
            mainMenu.scoreTop = storeScore
        }
        
        self.spawnShields()
        
        //        // Create spawn shield power up action.
        //        var spawnShieldPowerUp = SKAction.sequence([
        //            SKAction.runBlock(self.spawnShieldPowerUp),
        //            SKAction.waitForDuration(2, withRange: 4)])
        //        runAction(SKAction.repeatActionForever(spawnShieldPowerUp))
        
        /* Setup pause and resume button */
        //////////////////////////////////////////////////////////////////////////////////
        pauseButton           = SKSpriteNode(imageNamed: "PauseButton")
        pauseButton.position  = CGPointMake(self.size.width - 30, 20)
        pauseButton.hidden    = true
        self.addChild(pauseButton)
        
        resumeButton          = SKSpriteNode(imageNamed: "ResumeButton")
        resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5)
        resumeButton.hidden   = true
        self.addChild(resumeButton)
        //////////////////////////////////////////////////////////////////////////////////
        
        // Load music
        var url = NSBundle.mainBundle().URLForResource("ObservingTheStar", withExtension: "caf")
        audioPlayer = AVAudioPlayer(contentsOfURL: url, error: nil)
        if audioPlayer == false {
            println("Error loading audio player:")
        }
        else {
            audioPlayer.numberOfLoops  = -1
            audioPlayer.volume         = 0.8
            audioPlayer.play()
            self.mainMenu.musicPlaying = true
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SKPhysicsContact Delegate
    // Call everytime when physics contact is called
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody   = SKPhysicsBody()
        var secondBody : SKPhysicsBody  = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody   = contact.bodyA
            secondBody  = contact.bodyB
        }else{
            firstBody   = contact.bodyB
            secondBody  = contact.bodyA
        }
        
        // This condition when ball and halo hited each other
        if firstBody.categoryBitMask == Category.kSKHaloCategory && secondBody.categoryBitMask == Category.kSKBallCategory{
            self.score += self.pointValue
            // Collision between halo and ball
            self.addExplosion(firstBody.node?.position,withName: "HaloExplosion")// create explosion
            self.runAction(explosionSound)
            
            if let hasMultiplier:Bool = firstBody.node?.userData?.valueForKey("Multiplier") as? Bool {
                println("Multiplier -----> \(hasMultiplier)")
                self.pointValue++
            }
            else if let hasBomb:Bool = firstBody.node?.userData?.valueForKey("Bomb") as? Bool {
                println("Bomb -----> \(hasBomb)")
                mainLayerGame?.enumerateChildNodesWithName("halo", usingBlock:{
                    (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
                    self.addExplosion(node.position,withName: "HaloExplosion")// create explosion
                    node.removeFromParent()
                })
                
            }
            
            killCount++
            if killCount % 10 == 0 {
                runAction(SKAction.runBlock(self.spawnMultiShotPowerUp))
            }
            
            firstBody.categoryBitMask = 0
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            
        }
        
        if firstBody.categoryBitMask == Category.kSKHaloCategory && secondBody.categoryBitMask == Category.kSKShieldsCategory{
            // Collision between halo and shields
            self.addExplosion(firstBody.node?.position,withName: "HaloExplosion")// create explosion
            self.runAction(deepExplosionSound)
            
            
            if let hasBomb:Bool = firstBody.node?.userData?.valueForKey("Bomb") as? Bool {
                // Remove all shields
                mainLayerGame?.enumerateChildNodesWithName("shield", usingBlock:{
                    (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
                    node.removeFromParent()
                })
            }
            
            firstBody.categoryBitMask = 0 // make first body hit shield not duplicate
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            
            // Add shield pool one by one
            shieldPool.addObject(secondBody.node!)
            //            var spawnShieldPowerUp = SKAction.sequence([
            //                                     SKAction.runBlock(self.spawnShieldPowerUp),
            //                                     SKAction.waitForDuration(0.0, withRange: 4)])
            //            runAction(spawnShieldPowerUp)
            runAction(SKAction.runBlock(self.spawnShieldPowerUp))
        }
        
        if firstBody.categoryBitMask == Category.kSKHaloCategory && secondBody.categoryBitMask == Category.kSKLifeBarCategory{
            // Collision between halo and life bar
            self.addExplosion(firstBody.node?.position,withName: "HaloExplosion")// create explosion
            secondBody.node?.removeFromParent()
            self.runAction(deepExplosionSound)
            self.gameOver()
            
        }
        
        if firstBody.categoryBitMask == Category.kSKBallCategory && secondBody.categoryBitMask == Category.kSKEdgeCategory{
            // Collision between ball and edge
            self.addExplosion(firstBody.node?.position,withName: "BounceExplosion")// create explosion
            
            if let body = firstBody.node as? SKBall! {
                body.bounces++
                if body.bounces > 3 {
                    firstBody.node?.removeFromParent()
                    self.pointValue = 1
                }
            }
            
            self.runAction(bounceSound) // run sound
        }
        
        
        if firstBody.categoryBitMask == Category.kSKHaloCategory && secondBody.categoryBitMask == Category.kSKEdgeCategory{
            // Collision between ball and edge
            self.runAction(zapSound) // run sound
        }
        
        if firstBody.categoryBitMask == Category.kSKBallCategory && secondBody.categoryBitMask == Category.kSKShieldsUpCategory{
            // Hit a shield power up.
            if (shieldPool.count > 0 ) {
                var randomIndex : Int = Int(arc4random_uniform(UInt32(shieldPool.count)));
                mainLayerGame?.addChild(shieldPool.objectAtIndex(randomIndex) as! SKNode)
                shieldPool.removeObjectAtIndex(randomIndex)
                self.runAction(shieldUpSound)
            }
            
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == Category.kSKBallCategory && secondBody.categoryBitMask == Category.kSKMultiUpCategory{
            self.runAction(shieldUpSound) // run sound
            
            self.multiMode = true
            self.ammon  = 5
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
            
        }
        
    }
    
    // MARK: - Method Delegate
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            if !isGameOver && !gamePause {
                if !pauseButton.containsPoint(touch.locationInNode(pauseButton.parent)){
                    didShoot = true
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            if isGameOver && !mainMenu.touchable {
                // Find node by name in menu
                var location : CGPoint = touch.locationInNode(mainMenu)
                var node : SKNode = mainMenu.nodeAtPoint(location)
                if node.name == "Play" {
                    self.newGame()
                }
                if node.name == "Music" {
                    mainMenu.musicPlaying = !mainMenu.musicPlaying
                    if mainMenu.musicPlaying {
                        audioPlayer.play()
                    }else{
                        audioPlayer.stop()
                    }
                }
            }else if !isGameOver {
                if gamePause {
                    if resumeButton.containsPoint(touch.locationInNode(resumeButton.parent)) {
                        gamePause = false
                    }
                }else{
                    if pauseButton.containsPoint(touch.locationInNode(pauseButton.parent)){
                        gamePause = true
                    }
                }
            }
        }
    }
    
    // Method for remove sprite note
    override func didSimulatePhysics() {
        
        /* Shoot */
        if didShoot {
            if self.ammon > 0 {
                self.ammon--
                //                self.makeShoot()
                
                // auto shooting 5 time
                if multiMode {
                    for i in 1...5{
                        var multiPowerUp = SKAction.sequence([
                            SKAction.runBlock(self.makeShoot),
                            SKAction.waitForDuration(1)])
                        runAction(multiPowerUp)
                    }
                    
                    // reset shooting
                    if self.ammon == 0 {
                        multiMode = false
                        self.ammon = 5
                    }
                }
            }
            
            didShoot = false
        }
        
        mainLayerGame?.enumerateChildNodesWithName("ball", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            
            if node.respondsToSelector(Selector("updateTrail")) {
                node.runAction(SKAction.runBlock({ (node as! SKBall).updateTrail() }))
            }
            
            if !CGRectContainsPoint(self.frame, node.position){
                node.removeFromParent()
                self.ammon++
            }
        })
        
        mainLayerGame?.enumerateChildNodesWithName("halo", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            if node.position.y + node.frame.size.height < 0 {
                node.removeFromParent()
            }
        })
        
        mainLayerGame?.enumerateChildNodesWithName("shieldUp", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            if node.position.x + node.frame.size.width < 0 {
                node.removeFromParent()
            }
        })
        
        mainLayerGame?.enumerateChildNodesWithName("multiUp", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            if node.position.x - node.frame.size.width > self.size.width {
                node.removeFromParent()
            }
        })
        
        
    }
    
    // MARK: - Method
    func radiansToVector(radians:CGFloat?)->CGVector{
        var vector:CGVector = CGVector()
        vector.dx = cos(radians!)
        vector.dy = sin(radians!)
        return vector
    }
    
    // Method for shoot
    func makeShoot(){
        self.runAction(laserSound)
        
        
        // Condition shoot 2time per secornd
        //        if avarialbeAmmon > 0 {
        //            self.limitBall--
        
        var ball : SKBall                    = SKBall(imageNamed: "Ball")
        let rotationVector                   = radiansToVector(cannonGame.zRotation)
        ball.name                            = "ball"
        ball.position                        = CGPointMake(
            cannonGame.position.x + cannonGame.size.width * 0.5 * rotationVector.dx,
            cannonGame.position.y + cannonGame.size.width * 0.5 * rotationVector.dy)
        mainLayerGame?.addChild(ball)
        
        // Add physics body
        ball.physicsBody                     = SKPhysicsBody(circleOfRadius: 6.0)
        ball.physicsBody?.velocity           = CGVectorMake(rotationVector.dx * shootSpeed,rotationVector.dy * shootSpeed)
        ball.physicsBody?.restitution        = 1.0 // bounce physic
        ball.physicsBody?.linearDamping      = 0.0
        ball.physicsBody?.friction           = 0.0
        ball.physicsBody?.categoryBitMask    = Category.kSKBallCategory
        ball.physicsBody?.collisionBitMask   = Category.kSKEdgeCategory
        ball.physicsBody?.contactTestBitMask = Category.kSKEdgeCategory | Category.kSKShieldsUpCategory | Category.kSKMultiUpCategory
        
        // Add trail particle to ball
        var ballTrailPath : String           = NSBundle.mainBundle().pathForResource("BallTrail", ofType: "sks")!
        var ballTrail: SKEmitterNode         = NSKeyedUnarchiver.unarchiveObjectWithFile(ballTrailPath) as! SKEmitterNode
        ballTrail.targetNode                 = mainLayerGame // make ball trail particle follow ball
        mainLayerGame!.addChild(ballTrail)
        ball.trail                           = ballTrail
        ball.updateTrail()
        
        //        }
    }
    
    // Random position
    func randomInRange(low: CGFloat, high : CGFloat) -> CGFloat {
        return low + CGFloat(arc4random_uniform(UInt32(high - low + 1.0)))
    }
    
    // Create Shields block
    func spawnShields(){
        shieldPool = NSMutableArray()
        for index in 0...5{
            var shield : SKSpriteNode            = SKSpriteNode(imageNamed: "Block")
            shield.name                          = "shield"
            shield.position                      = CGPointMake(CGFloat(35 + (50 * index)), cannonGame.size.height/2 + 20.0);
            shield.physicsBody                   = SKPhysicsBody(rectangleOfSize: CGSize(width:42, height:9))
            shield.physicsBody?.categoryBitMask  = Category.kSKShieldsCategory
            shield.physicsBody?.collisionBitMask = Category.kSKEdgeCategory
            shieldPool.addObject(shield)
        }
    }
    
    // Create explosion
    func addExplosion(position:CGPoint?,withName:String?){
        // Add explosion by file
        var explosionPath:String = NSBundle.mainBundle().pathForResource(withName!, ofType: "sks")!
        var explosion:SKEmitterNode = NSKeyedUnarchiver.unarchiveObjectWithFile(explosionPath) as! SKEmitterNode
        explosion.position = position!
        mainLayerGame?.addChild(explosion)
        
        
        // Add explosion by manually
        //        var explosion:SKEmitterNode  = SKEmitterNode()
        //        explosion.particleTexture    = SKTexture(imageNamed: "spark")
        //        explosion.particleLifetime   = 1
        //        explosion.particleBirthRate  = 2000
        //        explosion.numParticlesToEmit = 100
        //        explosion.emissionAngleRange = 360
        //        explosion.particleScale      = 0.2
        //        explosion.particleScaleSpeed = -0.2
        //        explosion.particleSpeed      = 200
        //        explosion.position           = position!
        //        mainLayerGame?.addChild(explosion)
        
        var removeExplosion = SKAction.sequence([
            SKAction.waitForDuration(1.5),
            SKAction.removeFromParent()])
        explosion.runAction(removeExplosion)
    }
    
    func newGame(){
        
        mainLayerGame?.removeAllChildren()
        mainLayerGame?.addChild(ammonDisplay)
        mainLayerGame?.addChild(cannonGame)
        mainLayerGame?.addChild(lifeBar)
        
        /* Create all shield pool */
        while (shieldPool.count > 0) {
            mainLayerGame?.addChild(shieldPool.objectAtIndex(0) as! SKNode)
            shieldPool.removeObjectAtIndex(0)
        }
        
        // Init value
        self.ammon              = 5 // limited ball
        self.score              = 0 // start score
        self.killCount          = 0
        self.multiMode          = false
        self.isGameOver         = false
        self.mainMenu.touchable = true
        self.pauseButton.hidden = false
    }
    
    func gameOver(){
        mainLayerGame?.enumerateChildNodesWithName("halo", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            self.addExplosion(node.position, withName: "HaloExplosion")
            node.removeFromParent()
        })
        
        mainLayerGame?.enumerateChildNodesWithName("shield", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            self.shieldPool.addObject(node) // add all shield pool before remove from parent
            node.removeFromParent()
        })
        
        mainLayerGame?.enumerateChildNodesWithName("ball", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            node.removeFromParent()
        })
        
        mainLayerGame?.enumerateChildNodesWithName("shieldUp", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            node.removeFromParent()
        })
        
        mainLayerGame?.enumerateChildNodesWithName("multiUp", usingBlock:{
            (node: SKNode!, stop: UnsafeMutablePointer <ObjCBool>) -> Void in
            node.removeFromParent()
        })
        
        /* Objective C */
        //         [self performSelector:@selector(newGame) withObject:nil afterDelay:1.5];
        
        /* Swift */
        //        let delay = 1.5 * Double(NSEC_PER_SEC)
        //        let time  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        //        dispatch_after(time, dispatch_get_main_queue()){
        //            self.newGame()
        //        }
        
        // Setup score for game
        mainMenu.score = self.score
        if self.score > mainMenu.scoreTop {
            mainMenu.scoreTop = self.score
            
            // Save score in local device
            NSUserDefaults.standardUserDefaults().setInteger(self.score, forKey: "Score")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        // Setup when game over to show menu
        isGameOver              = true
        self.pauseButton.hidden = true
        self.runAction(SKAction.sequence([
            SKAction.waitForDuration(1.0),
            SKAction.runBlock({
                self.mainMenu.touchable = false
            })
            ]))
    }
    
    func spawnShieldPowerUp(){
        if shieldPool.count > 0 {
            var shieldUp : SKSpriteNode            = SKSpriteNode(imageNamed: "Block")
            shieldUp.name                          = "shieldUp"
            shieldUp.position                      = CGPointMake(self.size.width, randomInRange(150, high: self.size.height - 100));
            shieldUp.physicsBody                   = SKPhysicsBody(rectangleOfSize: CGSize(width:42, height:9))
            shieldUp.physicsBody?.categoryBitMask  = Category.kSKShieldsUpCategory
            shieldUp.physicsBody?.collisionBitMask = Category.kSKEdgeCategory
            shieldUp.physicsBody?.velocity         = CGVectorMake(-100, randomInRange(-40, high: 40))
            shieldUp.physicsBody?.angularVelocity  = CGFloat(M_PI)
            shieldUp.physicsBody?.linearDamping    = 0.0
            shieldUp.physicsBody?.angularDamping   = 0.0
            mainLayerGame?.addChild(shieldUp)
            
        }
    }
    
    /* Create multi shot of connon */
    func spawnMultiShotPowerUp(){
        println("\(self.size.width)")
        var multiUp : SKSpriteNode            = SKSpriteNode(imageNamed: "MultiShotPowerUp")
        multiUp.name                          = "multiUp"
        multiUp.position                      = CGPointMake(1.0,randomInRange(150, high: self.size.height - 100));
        multiUp.physicsBody                   = SKPhysicsBody(circleOfRadius: 12.0)
        multiUp.physicsBody?.categoryBitMask  = Category.kSKMultiUpCategory
        multiUp.physicsBody?.collisionBitMask = Category.kSKEdgeCategory
        multiUp.physicsBody?.velocity         = CGVectorMake(100, randomInRange(-40, high: 40))
        multiUp.physicsBody?.angularVelocity  = CGFloat(M_PI)
        multiUp.physicsBody?.linearDamping    = 0.0
        multiUp.physicsBody?.angularDamping   = 0.0
        mainLayerGame?.addChild(multiUp)
    }
    
    // MARK: - Spawn Halo
    func spawnHalo(){
        
        if !isGameOver {
            // Increas spawn speed
            ///////////////////////////////////////////////////////
            if let spawnAction = self.actionForKey("SpawnHalo"){
                if spawnAction.speed < 1.5 {
                    spawnAction.speed += 0.01 // add more speed
                }
            }
            //////////////////////////////////////////////////////
            
            // Create halo node
            var halo                             = SKSpriteNode(imageNamed: "Halo")
            halo.name                            = "halo"
            halo.position                        = CGPointMake(randomInRange(halo.size.width*0.5, high: self.size.width - (halo.size.width)),
                self.size.height + (halo.size.height * 0.5))
            halo.physicsBody                     = SKPhysicsBody(circleOfRadius: 16.0)
            var direction : CGVector             = radiansToVector(randomInRange(Halo.kSKHaloLowAngle, high: Halo.kSKHaloHighAngle))
            halo.physicsBody?.velocity           = CGVectorMake(direction.dx * Halo.kSKHaloSpeed, direction.dy * Halo.kSKHaloSpeed)
            halo.physicsBody?.restitution        = 1.0
            halo.physicsBody?.linearDamping      = 0.0
            halo.physicsBody?.friction           = 0.0
            halo.physicsBody?.categoryBitMask    = Category.kSKHaloCategory
            halo.physicsBody?.collisionBitMask   = Category.kSKEdgeCategory
            halo.physicsBody?.contactTestBitMask = Category.kSKBallCategory | Category.kSKShieldsCategory | Category.kSKLifeBarCategory | Category.kSKEdgeCategory // set contact test bit mask for call didBeginContact function
            
            var haloCount : Int = 0
            for node in mainLayerGame?.children as! [SKNode]{
                if node.name == "halo" {
                    haloCount++
                }
            }
            
            if haloCount == 4 {
                halo.texture = SKTexture(imageNamed: "HaloBomb") // change image
                halo.userData = ["Bomb":true]
            }else if (isGameOver != true && arc4random_uniform(6) == 0) {
                halo.texture = SKTexture(imageNamed: "HaloX")
                halo.userData = ["Multiplier":true]
            }
            
            mainLayerGame?.addChild(halo)
        }
    }
}
