import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    private var spaceMonkey = SKSpriteNode()
    private var alien = SKSpriteNode()
    private var asteroid = SKSpriteNode()
    private var banana = SKSpriteNode()
    private var spaceMonkeyFrames: [SKTexture] = []
    private var alienFrames: [SKTexture] = []
    private var asteroidFrames: [SKTexture] = []
    private var bananaFrames: [SKTexture] = []
    private var aliens: [SKSpriteNode] = []
    private var asteroids: [SKSpriteNode] = []
    private var bananas: [SKSpriteNode] = []
    private var lives: Int = 3
    private var heartNodes: [SKLabelNode] = []
    
    // MARK: - Score and Level Properties
    private var score: Int = 0
    private var level: Int = 1
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    
    // MARK: - Game Difficulty Settings
    private var alienSpawnRate: TimeInterval = 2.0
    private var asteroidSpawnRate: TimeInterval = 2.0
    private var bananaSpawnRate: TimeInterval = 3.0
    private var alienMoveSpeed: TimeInterval = 5.0
    private var asteroidMoveSpeed: TimeInterval = 5.0
    private var bananaMoveSpeed: TimeInterval = 4.0
    
    // MARK: - Physics Categories
    let spaceMonkeyCategory: UInt32 = 0x1 << 0
    let alienCategory: UInt32 = 0x1 << 1
    let asteroidCategory: UInt32 = 0x1 << 2
    let bananaCategory: UInt32 = 0x1 << 3
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        backgroundColor = .black
        createSpaceBackground()
        createMoon()
        buildSpaceMonkey()
        animateSpaceMonkey()
        spawnAliens()
        spawnAsteroids()
        spawnBananas()
        displayLives()
        setupLabels()
    }
    
    // MARK: - Score and Level Setup
    func setupLabels() {
        // Score Label
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 50)
        addChild(scoreLabel)
        
        // Level Label
        levelLabel = SKLabelNode(fontNamed: "Arial")
        levelLabel.fontSize = 30
        levelLabel.fontColor = .yellow
        levelLabel.text = "Level: 1"
        levelLabel.horizontalAlignmentMode = .right
        levelLabel.position = CGPoint(x: size.width - 20, y: size.height - 90)
        addChild(levelLabel)
    }
    
    func updateScore(points: Int) {
        score += points
        scoreLabel.text = "Score: \(score)"
        
        let newLevel = (score / 60) + 1
        if newLevel > level {
            levelUp(to: newLevel)
        }
    }
    
    func levelUp(to newLevel: Int) {
        level = newLevel
        levelLabel.text = "Level: \(level)"
        
        // Increase difficulty
        alienSpawnRate = max(0.5, 2.0 - (Double(level) * 0.2))
        asteroidSpawnRate = max(0.5, 2.0 - (Double(level) * 0.2))
        alienMoveSpeed = max(2.0, 5.0 - (Double(level) * 0.3))
        asteroidMoveSpeed = max(2.0, 5.0 - (Double(level) * 0.3))
        
        // Optional: Visual level up effect
        let levelUpLabel = SKLabelNode(fontNamed: "Arial")
        levelUpLabel.text = "Level Up!"
        levelUpLabel.fontSize = 48
        levelUpLabel.fontColor = .green
        levelUpLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        levelUpLabel.run(SKAction.sequence([
            .wait(forDuration: 1.0),
            .removeFromParent()
        ]))
        addChild(levelUpLabel)
    }
    
    // MARK: - UI Setup
    func displayLives() {
        // Remove existing heart nodes if any
        heartNodes.forEach { $0.removeFromParent() }
        heartNodes.removeAll()
        
        for i in 0..<lives {
            let heart = SKLabelNode(text: "❤️")
            heart.position = CGPoint(x: 30 + i * 40, y: Int(size.height) - 40)
            heart.fontSize = 40
            heartNodes.append(heart)
            addChild(heart)
        }
    }
    
    func createSpaceBackground() {
        for _ in 0..<100 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            star.fillColor = .white
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            addChild(star)
        }
    }
    
    func createMoon() {
        let moon = SKShapeNode(circleOfRadius: 150)
        moon.fillColor = .lightGray
        moon.position = CGPoint(x: size.width - 150, y: size.height - 150)
        addChild(moon)
    }
    
    // MARK: - Game Objects Setup
    func buildSpaceMonkey() {
        let spaceMonkeyAtlas = SKTextureAtlas(named: "SpaceMonkey")
        for i in 1...2 {
            let textureName = "spacemonkey_fly0\(i)"
            spaceMonkeyFrames.append(spaceMonkeyAtlas.textureNamed(textureName))
        }
        
        let firstFrame = spaceMonkeyFrames[0]
        spaceMonkey = SKSpriteNode(texture: firstFrame)
        spaceMonkey.position = CGPoint(x: frame.midX, y: frame.midY - 200)
        spaceMonkey.setScale(0.5)
        
        spaceMonkey.physicsBody = SKPhysicsBody(rectangleOf: spaceMonkey.size)
        spaceMonkey.physicsBody?.categoryBitMask = spaceMonkeyCategory
        spaceMonkey.physicsBody?.contactTestBitMask = alienCategory | asteroidCategory | bananaCategory
        spaceMonkey.physicsBody?.collisionBitMask = 0
        spaceMonkey.physicsBody?.isDynamic = true
        
        addChild(spaceMonkey)
    }
    
    func animateSpaceMonkey() {
        spaceMonkey.run(SKAction.repeatForever(
            SKAction.animate(with: spaceMonkeyFrames,
                             timePerFrame: 0.1,
                             resize: false,
                             restore: true)),
                        withKey: "spaceMonkeyAnimation")
    }
    
    // MARK: - Spawning Objects
    func spawnAliens() {
        let alienAtlas = SKTextureAtlas(named: "Alien")
        let textureName1 = "alien_top_01"
        let textureName2 = "alien_top_02"
        alienFrames.append(alienAtlas.textureNamed(textureName1))
        alienFrames.append(alienAtlas.textureNamed(textureName2))
        
        let spawnAction = SKAction.run { [weak self] in
            self?.createAlien()
        }
        let waitAction = SKAction.wait(forDuration: 2.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    func createAlien() {
        let alienNode = SKSpriteNode(texture: alienFrames.randomElement()!)
        alienNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
        
        // Increase size and difficulty with levels
        let scale = min(1.0, 0.5 + (CGFloat(level) * 0.1))
        alienNode.setScale(scale)
        
        alienNode.physicsBody = SKPhysicsBody(rectangleOf: alienNode.size)
        alienNode.physicsBody?.categoryBitMask = alienCategory
        alienNode.physicsBody?.contactTestBitMask = spaceMonkeyCategory
        alienNode.physicsBody?.collisionBitMask = 0
        
        addChild(alienNode)
        aliens.append(alienNode)
        
        let moveAction = SKAction.moveTo(y: -alienNode.size.height, duration: alienMoveSpeed)
        alienNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    func spawnAsteroids() {
        let asteroidAtlas = SKTextureAtlas(named: "Objects")
        asteroidFrames.append(asteroidAtlas.textureNamed("object_asteroid_01"))
        
        let spawnAction = SKAction.run { [weak self] in
            self?.createAsteroid()
        }
        let waitAction = SKAction.wait(forDuration: 2.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    func createAsteroid() {
        let asteroidNode = SKSpriteNode(texture: asteroidFrames[0])
        asteroidNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
        
        // Increase size and difficulty with levels
        let scale = min(1.0, 0.5 + (CGFloat(level) * 0.1))
        asteroidNode.setScale(scale)
        
        asteroidNode.physicsBody = SKPhysicsBody(rectangleOf: asteroidNode.size)
        asteroidNode.physicsBody?.categoryBitMask = asteroidCategory
        asteroidNode.physicsBody?.contactTestBitMask = spaceMonkeyCategory
        asteroidNode.physicsBody?.collisionBitMask = 0
        
        addChild(asteroidNode)
        asteroids.append(asteroidNode)
        
        let moveAction = SKAction.moveTo(y: -asteroidNode.size.height, duration: asteroidMoveSpeed)
        asteroidNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    func spawnBananas() {
        let bananaAtlas = SKTextureAtlas(named: "Objects")
        bananaFrames.append(bananaAtlas.textureNamed("powerup_banana"))
        
        let spawnAction = SKAction.run { [weak self] in
            self?.createBanana()
        }
        let waitAction = SKAction.wait(forDuration: 3.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    func createBanana() {
        let bananaNode = SKSpriteNode(texture: bananaFrames[0])
        bananaNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
        bananaNode.setScale(0.5)
        
        bananaNode.physicsBody = SKPhysicsBody(rectangleOf: bananaNode.size)
        bananaNode.physicsBody?.categoryBitMask = bananaCategory
        bananaNode.physicsBody?.contactTestBitMask = spaceMonkeyCategory
        bananaNode.physicsBody?.collisionBitMask = 0
        
        addChild(bananaNode)
        bananas.append(bananaNode)
        
        let moveAction = SKAction.moveTo(y: -bananaNode.size.height, duration: bananaMoveSpeed)
        bananaNode.run(SKAction.sequence([moveAction, .removeFromParent()]))
    }
    
    // MARK: - Game Logic
    func moveSpaceMonkey(to location: CGPoint) {
        spaceMonkey.removeAllActions()
        animateSpaceMonkey()
        
        let newLocation = CGPoint(x: location.x, y: spaceMonkey.position.y)
        let moveAction = SKAction.move(to: newLocation, duration: 0.1)
        spaceMonkey.run(moveAction)
    }
    
    func updateLives() {
        if lives > 0 {
            lives -= 1
            heartNodes[lives].removeFromParent()
            
            if lives == 0 {
                // Game Over logic
                let gameOverLabel = SKLabelNode(fontNamed: "Arial")
                gameOverLabel.text = "Game Over"
                gameOverLabel.fontSize = 48
                gameOverLabel.fontColor = .red
                gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
                addChild(gameOverLabel)
                
                // Show final score
                let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
                finalScoreLabel.text = "Final Score: \(score)"
                finalScoreLabel.fontSize = 36
                finalScoreLabel.fontColor = .white
                finalScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - 60)
                addChild(finalScoreLabel)
                
                // Detener todas las acciones
                removeAllActions()
                spaceMonkey.removeAllActions()
                
                // Agregar el botón de reinicio
                addRestartButton()
            }
        }
    }
    func collectBanana(_ bananaNode: SKSpriteNode) {
        bananaNode.removeFromParent()
        if let index = bananas.firstIndex(of: bananaNode) {
            bananas.remove(at: index)
        }
        
        // Update score when collecting a banana
        updateScore(points: 10)
        
        if lives < 3 {
            lives += 1
            displayLives()
        }
    }
    
    // MARK: - Touch Handling
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Verifica si tocó el botón de reinicio
        if let node = atPoint(location) as? SKLabelNode, node.name == "restartButton" {
            restartGame()
        } else {
            let newLocation = CGPoint(x: location.x, y: spaceMonkey.position.y)
            moveSpaceMonkey(to: newLocation)
        }
    }
    // MARK: - Collision Detection
// Replace the didBegin function with:
func didBegin(_ contact: SKPhysicsContact) {
    let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    
    if collision == spaceMonkeyCategory | alienCategory ||
        collision == spaceMonkeyCategory | asteroidCategory {
        updateLives()
    } else if collision == spaceMonkeyCategory | bananaCategory {
        if let banana = (contact.bodyA.categoryBitMask == bananaCategory ? contact.bodyA.node : contact.bodyB.node) as? SKSpriteNode {
            // Use collectBanana function instead of direct manipulation
            collectBanana(banana)
            
            // Play collection sound
            run(SKAction.playSoundFileNamed("collect.mp3", waitForCompletion: false))
            
            // Optional particle effect
            if let particles = SKEmitterNode(fileNamed: "CollectParticles") {
                particles.position = banana.position
                addChild(particles)
                particles.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }
}
    func addRestartButton() {
        let restartButton = SKLabelNode(text: "Reiniciar")
        restartButton.fontSize = 40
        restartButton.fontColor = .white
        restartButton.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        restartButton.name = "restartButton" // Esto es importante para identificar el botón
        addChild(restartButton)
    }
    
    func restartGame() {
        // Eliminar el botón de reinicio antes de reiniciar el juego
        if let restartButton = childNode(withName: "restartButton") {
            restartButton.removeFromParent()
        }
        
        // Resetea las propiedades del juego
        score = 0
        level = 1
        lives = 3
        spaceMonkey.removeAllActions()
        removeAllChildren() // Elimina todos los nodos existentes
        setupLabels() // Configura de nuevo las etiquetas de puntuación y nivel
        displayLives() // Vuelve a mostrar las vidas
        buildSpaceMonkey() // Vuelve a construir el espacio mono
        animateSpaceMonkey() // Reaplica la animación
        spawnAliens() // Reinicia el spawneo de aliens
        spawnAsteroids() // Reinicia el spawneo de asteroides
        spawnBananas() // Reinicia el spawneo de bananas
        createSpaceBackground() // Vuelve a crear el fondo espacial
        createMoon() // Crea de nuevo la luna
    }
}
