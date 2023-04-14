//
//  GameScene.swift
//  FlappyBird
//
//  Created by Teruo Yamamoro on 2023/03/29.
//

import SpriteKit
import AVFoundation

class SoundPlayer: NSObject {
    let coinData = NSDataAsset(name:"Coin")!.data
    let bgmData = NSDataAsset(name:"101BGM")!.data
    var coinPlayer: AVAudioPlayer!
    var bgmPlayer: AVAudioPlayer!
    
    func coinSound(){
        do {
            coinPlayer = try AVAudioPlayer(data:coinData)
            coinPlayer.play()
        } catch {
            print("エラーが発生")
        }
    }
    
    func bgmSound(){
        do {
            bgmPlayer = try AVAudioPlayer(data:bgmData)
            bgmPlayer.numberOfLoops = -1//無限ループ
            bgmPlayer.play()
            
        } catch {
            print("エラーが発生")
        }
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    
    var appleNode:SKNode!
    var apple:SKSpriteNode!
    
    let soundPlayer = SoundPlayer()
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4
    
    // スコア用
    var score = 0
    var itemScore = 0
    var totalScore = 0
    var scoreLabelNode:SKLabelNode!
    var itemLabelNode:SKLabelNode!
    var totalLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //easy modeボタン
    let easyButton = SKLabelNode(text: "Easy")
    //hard modeボタン
    let hardButton = SKLabelNode(text: "Hard")
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //モード選択
        easyButton.position = CGPoint(x: frame.midX - 100, y: frame.midY)
        easyButton.zPosition = 110
        addChild(easyButton)
        
        hardButton.position = CGPoint(x: frame.midX + 100, y: frame.midY)
        hardButton.zPosition = 110
        addChild(hardButton)
        
    
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // 初期重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        //BGM
        soundPlayer.bgmSound()
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        scrollNode.speed = 0
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        appleNode = SKNode()
        scrollNode.addChild(appleNode)
        
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        setupApple()
        
        setupScoreLabel()
        
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            
            // 鳥の速度をゼロにする（画面の一定位置にいる）
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
            
        }// else if bird.speed == 0 {
        //  restart()
        // }
        if easyButton.isHidden == false {
            //touches[0]
            for touch in touches {
                //タッチされた場所を検出し、その場所にあるノードをself.atPointで検出している。
                let location = touch.location(in: self)
                let touchedNode = self.atPoint(location)
                //touchedNodeがeasyButtonかhardButtonである場合のみ、画面タップが有効になる。それ以外の場合、他のノードはfalseで反応しなくなる。
                if touchedNode == easyButton || touchedNode == hardButton {
                    if touchedNode == easyButton {
                        easyMode()
                    } else {
                        hardMode()
                    }
                }
            }
        }
    }
    
    //ボタンの機能
    func easyMode (){
        restart()
        scrollNode.speed = 1
    }
    
    func hardMode (){
        restart()
        scrollNode.speed = 2.0
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算、合計五枚の画像を用意している。
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する、一枚の画像に対して
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する、テクスチャを指定してスプライトを作成する
            //* CGFloat(i)で次に出てくる画像の座標を増やして位置を作っていってる。例：40+40*0~4の座標
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory//衝撃判定
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // 空の中央位置を基準にして下側の壁の中央位置を取得、- wallTexture.size().height /2 壁の真ん中の部分（半分）引いてる。中心座標のため。
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            print (under_wall_y)
            
            // 下側の壁を作成、0=親の相対位置
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // 下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory//衝突判定
            under.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // 上側の壁に物理体を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory //衝突判定
            upper.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            // スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            // 透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)
            
            // 壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            // 壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        // // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory//衝撃判定
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory//当たった時に跳ね返る動作をする相手
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory  | itemCategory//衝突判定の対象となるカテゴリ
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        //どちらがぶつかってくるもので、ぶつかるものか分からないため、２パターン用意している。今回は、鳥しかぶつかってこないため、socorecategoryとscorecategoryでやっている。本来はこれだと、複数がぶつかってくる設定。
        if //(contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || //(contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //例：鳥と壁のみが衝突する設定。
            (contact.bodyA.categoryBitMask & birdCategory) == birdCategory &&
                (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory
                ||
                (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory &&
                (contact.bodyB.categoryBitMask & birdCategory) == birdCategory {
            
            // スコアカウント用の透明な壁と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            totalScore = score + itemScore
            totalLabelNode.text = "Total Score:\(score + itemScore)"
            
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if itemScore + score > bestScore {
                bestScore = itemScore + score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
                
            }
        }
        else if
            (contact.bodyA.categoryBitMask & birdCategory) == birdCategory &&
                (contact.bodyB.categoryBitMask & itemCategory) == itemCategory
                ||
                (contact.bodyA.categoryBitMask & itemCategory) == itemCategory &&
                (contact.bodyB.categoryBitMask & birdCategory) == birdCategory {
            //衝突したりんごのみ消す。
            if let apple = contact.bodyA.node as? SKSpriteNode, apple.physicsBody?.categoryBitMask == itemCategory {
                apple.removeFromParent()
            }
            if let apple = contact.bodyB.node as? SKSpriteNode, apple.physicsBody?.categoryBitMask == itemCategory {
                apple.removeFromParent()
            }
            
            
            // アイテムと衝突した
            print("ScoreUp")
            itemScore += 1
            itemLabelNode.text = "Item Score:\(itemScore)"
            totalScore = score + itemScore
            totalLabelNode.text = "Total Score:\(score + itemScore)"
            
            //appleNode.removeAllChildren()
            
            
            //let sound = SKAction.playSoundFileNamed("Coin.mp3", waitForCompletion: false)
            //self.run(sound)
            
            soundPlayer.coinSound()
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if totalScore > bestScore {
                bestScore = totalScore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
                
            }
        } else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            // 衝突後は地面と反発するのみとする(リスタートするまで壁と反発させない)
            bird.physicsBody?.collisionBitMask = groundCategory
            
            // 衝突後1秒間、鳥をくるくる回転させる
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
                //衝突の際にボタンを表示する。
                self.easyButton.isHidden = false
                self.hardButton.isHidden = false
            })
        }
    }
    func restart() {
        
        //ボタンを隠す
        easyButton.isHidden = true
        hardButton.isHidden = true
        
        // スコアを0にする
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScore = 0
        itemLabelNode.text = "Item Score:\(itemScore)"
        totalScore = 0
        totalLabelNode.text = "total Score:\(totalScore)"
        
        // 鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        // 全ての壁を取り除く
        wallNode.removeAllChildren()
        appleNode.removeAllChildren()
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        
        // 鳥の羽ばたきを戻す
        bird.speed = 1
        
        // スクロールを再開させる
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        // スコア表示を作成
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        itemScore = 0
        itemLabelNode = SKLabelNode()
        itemLabelNode.fontColor = UIColor.black
        itemLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemLabelNode.zPosition = 100 // 一番手前に表示する
        itemLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemLabelNode)
        
        totalScore = 0
        totalLabelNode = SKLabelNode()
        totalLabelNode.fontColor = UIColor.black
        totalLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        totalLabelNode.zPosition = 100 // 一番手前に表示する
        totalLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        totalLabelNode.text = "Total Score:\(score + itemScore)"
        self.addChild(totalLabelNode)
        
        
        // ベストスコア表示を作成
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    func setupApple() {
        // りんごの画像を読み込む
        let appleTexture = SKTexture(imageNamed: "apple")
        appleTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + appleTexture.size().width
        
        // 画面外まで移動するアクションを作成
        //let duration = Double.random(in: 0.5...6)←一回だけなので、最初に決まる。毎出現ではない。
        let moveApple = SKAction.moveBy(x: -movingDistance, y: 0, duration: 3)
        
        // 自身を取り除くアクションを作成
        let removeApple = SKAction.removeFromParent()
        print (removeApple)
        
        // 2つのアニメーションを順に実行するアクションを作成
        let appleAnimation = SKAction.sequence([moveApple, removeApple])
        
        
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 150
        
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // りんごを生成するアクションを作成
        let createAppleAnimation = SKAction.run({
            // りんごをまとめるノードを作成
            let apple = SKNode()
            apple.position = CGPoint(x: self.frame.size.width + appleTexture.size().width / 2, y: 0)
            apple.zPosition = 100 //一番手前
            
            // りんごの中央位置にランダム値を足して、表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let apple_y = sky_center_y + random_y
            
            // りんごを作成
            let appleItem = SKSpriteNode(texture: appleTexture)
            appleItem.position = CGPoint(x: 0, y: apple_y)
            //りんごサイズ
            appleItem.size = CGSize(width: appleItem.size.width*0.2, height: appleItem.size.height*0.2)
            
            // 下側の壁に物理体を設定する
            appleItem.physicsBody = SKPhysicsBody(circleOfRadius: appleTexture.size().height * 0.1)
            appleItem.physicsBody?.categoryBitMask = self.itemCategory//衝突判定
            appleItem.physicsBody?.isDynamic = false
            
            // りんごをまとめるノードに下側の壁を追加
            apple.addChild(appleItem)
            
            // りんごをまとめるノードにアニメーションを設定
            apple.run(appleAnimation)
            
            // りんごを表示するノードに今回作成したりんごを追加
            self.appleNode.addChild(apple)
        })
        // 次のりんご出現までの時間待ちのアクションを作成
        //let forduration = Double.random(in: 0.5...3)←一回だけなので、最初に決まる。毎出現ではない。
        let waitAnimation = SKAction.wait(forDuration: 1)
        
        // りんごを作成->時間待ち->りんごを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createAppleAnimation, waitAnimation]))
        
        // // りんごを表示するノードにりんごの作成を無限に繰り返すアクションを設定
        appleNode.run(repeatForeverAnimation)
    }
    
    
}

