//
//  GameScene.swift
//  FlappyBird
//
//  Created by mawincommon on 2023/08/22.
//


/*
 画像：かわいいフリー素材集　いらすとや　URL：https://www.irasutoya.com
 paprika（vegetable_paprika_red）、satsumaimo（vegetable_satsumaimo_brown）、tougarashi（vegetable_kyouyasai_manganji_tougarashi）、
 youngcorn（food_young_corn）、GameOverImage（text_gameover_e）
 ※（）内は元のファイル名
 
 音源：無料BGM・効果音のフリー音源素材　springin（スプリンギン）　URL:https://www.springin.org/sound-stock/
 get（8bit獲得1）、crash（クラッカー2）、BGM（自然_01）、GameOverBgm（8bit失敗3）
 ※（）内は元のファイル名
 */


import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    
    /*
     itemを追加
     */
    var itemNode:SKNode!
    /*GameOverを追加
     */
    var gameOverImage = SKSpriteNode()
    
    // 衝突判定カテゴリー ↓追加
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    
    /*
     itemカテゴリーを追加
     */
    let itemCategory:UInt32 = 1 << 4
    
    // スコア用
    var score = 0  // ←追加
    /*
     itemのスコア用
     */
    var itemScore = 0
    
    var scoreLabelNode:SKLabelNode!    // ←追加
    var bestScoreLabelNode:SKLabelNode!    // ←追加
    var itemScoreLabelNode:SKLabelNode!
    var totalScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard    // 追加
    
    
    /*
     Sound設定
     */
    //プレイ中のサウンド
    let bgm = SKAudioNode(fileNamed: "BGM.mp3")
    //アイテムをゲットしたときのサウンド
    let getSound = SKAction.playSoundFileNamed("get.mp3", waitForCompletion : false)
    //衝突したときのサウンド
    let crash = SKAction.playSoundFileNamed("crash.mp3", waitForCompletion : false)
    //GameOverのサウンド
    let GameOverSound = SKAction.playSoundFileNamed("GameOverBgm.mp3", waitForCompletion : false)
    //Soundの再生・停止
    let playBgm = SKAction.play()
    let stopBgm = SKAction.stop()
    
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self // ←追加
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        /*
         item用のノード
         */
        itemNode = SKNode()
        scrollNode.addChild(itemNode)   //scrollNodeに追加
        
        
        //サウンドを追加
        addChild(bgm)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        /*itemを追加
         */
        setupItem()
        
        // スコア表示ラベルの設定
        setupScoreLabel()   // 追加
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 { // 追加
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 { // --- ここから ---
            restart()
            
            /*
             サウウドを再度再生する
             */
            bgm.run(playBgm)
        } // --- ここまで追加 ---
    }
    
    
    func restart() {
        
        /*
         GameOverを消去する
         */
        gameOverImage.isHidden = true
        
        // スコアを0にする
        score = 0
        scoreLabelNode.text = "Score:\(score)"    // ←追加
        
        
        /*
         itemスコアを0にする
         */
        itemScore = 0
        itemScoreLabelNode.text = "Item:\(itemScore)"
        
        // 鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        // 全ての壁を取り除く
        wallNode.removeAllChildren()
        
        // 鳥の羽ばたきを戻す
        bird.speed = 1
        
        // スクロールを再開させる
        scrollNode.speed = 1
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory    // ←追加
            
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
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:6)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする(5倍に変更)
        let slit_length = birdSize.height * 5
        
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // 空の中央位置を基準にして下側の壁の中央位置を取得
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
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // 下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
            under.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // 上側の壁に物理体を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
            upper.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            // --- ここから ---
            // スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            
            // 透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            
            // 壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)
            // --- ここまで追加 ---
            
            // 壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            // 壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
            
        })
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 3)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
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
        bird.physicsBody?.categoryBitMask = birdCategory    // ←追加
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory    // ←追加
        
        /*itmeカテゴリーを追加*/
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false    // ←追加
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
        
    }
    
    
    /*
     itemを作成
     */
    func setupItem() {
        
        /*
         item用に"wall"と"ground"の画像を読み込む
         */
        let wallTexture = SKTexture(imageNamed: "wall")
        let groundTexture = SKTexture(imageNamed: "ground")
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width * 2)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run ({
            
            //item画像の取り込み
            let textureNumber = Int.random(in: 0...3)
            let itemName = ["paprika", "satsumaimo", "tougarashi", "youngcorn"]
            let itemTexture = SKTexture(imageNamed: itemName[textureNumber])
            itemTexture.filteringMode = .linear
            
            
            // アイテム関連のノードをのせるノードを作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            
            //itemのy軸、x軸をランダムに生成
            let item_y_range = self.frame.size.height - itemTexture.size().height -  groundTexture.size().height
            let item_y = CGFloat.random(in:0...item_y_range) + itemTexture.size().height / 2 + groundTexture.size().height
            let item_x_range = (self.frame.size.width + wallTexture.size().width) / 3
            let item_x = CGFloat.random(in:0...item_x_range) + (wallTexture.size().width + itemTexture.size().width) / 2
            
            //アイテムを生成
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: item_x, y: item_y)
            //重力を設定
            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))
            itemSprite.physicsBody?.isDynamic = false
            itemSprite.physicsBody?.categoryBitMask = self.itemCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory   //衝突判定させる相手のカテゴリを設定
            
            item.addChild(itemSprite)
            
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
            
        })
        // 次のアイテム作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
        
    }
    
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score + itemScore > bestScore {
                bestScore = score + itemScore
                bestScoreLabelNode.text = "BestScore:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        }else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            // アイテムと衝突した
            
            itemScore += 1
            
            print("itemget")
            
            if contact.bodyA.categoryBitMask == itemCategory{
                contact.bodyA.node?.removeFromParent()
            }
            if contact.bodyB.categoryBitMask == itemCategory{
                contact.bodyB.node?.removeFromParent()
            }
            self.run(getSound)
            
            itemScoreLabelNode.text = "Item:\(itemScore)"
            
            
        }else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
            
            /*
             BGMを停止する
             */
            bgm.run(stopBgm)
            
            /*
             gameOverの作成と配置
             */
            //gameOverImageの初期化する
            gameOverImage = SKSpriteNode()
            let gameOverTexture = SKTexture(imageNamed: "GameOverImage")
            gameOverImage = SKSpriteNode(texture: gameOverTexture)
            
            //Imageの位置を決める
            gameOverImage.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            gameOverImage.zPosition = 11
            self.addChild(gameOverImage)
            
            //gameOverImageを消しておく
            gameOverImage.isHidden = true
            
            /*
             GameOverを表示する
             */
            gameOverImage.isHidden = false
            
            
            /*
             GemeOverのBgm(衝突したときのサウンドのあとに、GameOverのサウンドを再生する)
             */
            self.run(crash)
            DispatchQueue.main.asyncAfter(deadline : .now() + 1) {
                self.run(self.GameOverSound)
            }
            
        }
        
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
        
        // ベストスコア表示を作成
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        /*
         itemスコア表示用
         */
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item:\(score)"
        self.addChild(itemScoreLabelNode)
        
    }
}
