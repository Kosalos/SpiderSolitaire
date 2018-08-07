import UIKit

let RANK = 13
let SUIT = 4
let DECKS = 2
let NUM_CARDS = DECKS * SUIT * RANK

var numSuits:Int = 4

struct CardData {
    var view:UIImageView
    var suit:Int
    var rank:Int
    var picIndex :Int
    var homePosition:CGPoint
    
    init() {
        view = UIImageView()
        suit = 0
        rank = 0
        picIndex = 0
        homePosition = CGPoint.zero
    }
}

class Cards
{
    var backFace = UIImage()
    var cardPicture = [UIImage]()
    var cardData = [CardData]()
    
    func initialize(_ parentView:UIView) {
        backFace = UIImage(named: "cardback.png")!
        let deck = UIImage(named: "cardFaces.png")
        
        // load all card faces into cardPicture[] -------------------
        let sx:CGFloat = 15
        let sy:CGFloat = 9
        let xs:CGFloat = 374
        let ys:CGFloat = 522
        let xh:CGFloat = 65
        let yh:CGFloat = 65
        
        for s in 0 ..< SUIT {
            for r in 0 ..< RANK {
                let x = sx + CGFloat(r) * (xs + xh)
                let y = sy + CGFloat(s) * (ys + yh)
                let rect = CGRect(x: x,y: y,width: xs,height: ys)
                let cardFace = deck!.cgImage!.cropping(to: rect)
                
                cardPicture.append(UIImage(cgImage: cardFace!))
            }
        }
        
        // create UIImageView for each card --------------------------
        for i in 0 ..< NUM_CARDS {
            var cd = CardData()
            cd.view = UIImageView()
            cd.view.isOpaque = true
            
            cardData.append(cd)
            parentView.addSubview(cd.view)
            
            setPosition(i, offscreenPosition)
            setFaceUp(i, false)
            setZ(i, i)
            
            cd.view.layer.shadowColor = UIColor.black.cgColor
            cd.view.layer.shadowOpacity = 1
            cd.view.layer.shadowOffset = CGSize.zero
            cd.view.layer.shadowRadius = 3
            cd.view.layer.shadowPath = UIBezierPath(rect: cd.view.bounds).cgPath
        }
    }
    
    func setNumberOfDecks(_ style:Int) {  // 0,1,2 -> 1,2,4 suits
        var index:Int = 0
        for _ in 0 ..< DECKS {
            for s in 0 ..< SUIT {
                for r in 0 ..< RANK {
                    switch style {
                    case 0 : cardData[index].suit = 0       // one suit
                    case 1 : cardData[index].suit = s & 1   // two suits (one black, one red)
                    case 2 : cardData[index].suit = s       // all 4 suits
                    default: cardData[index].suit = s
                    }
                    
                    cardData[index].rank = r
                    cardData[index].picIndex = cardData[index].suit * RANK + r
                    index += 1
                }
            }
        }
    }

    // MARK:-
    
    func card(_ index:Int) -> CardData { return cardData[index] }
    func setZ(_ index:Int, _ value:Int) { cardData[index].view.layer.zPosition = CGFloat(value * 10) }
    
    // MARK:-
    
    func setPosition(_ index:Int, _ pos:CGPoint) {
        cardData[index].homePosition = pos
        cardData[index].view.frame = CGRect(x: pos.x,y: pos.y,width: cardXS,height: cardYS)
    }
    
    func goBackHome(_ index:Int) {
        UIView.animate(withDuration: 0.3, delay:0, options: .curveLinear,
            animations: {
                self.setPosition(index, self.cardData[index].homePosition)
            }, completion: nil)
    }
    
    func setDeltaPosition(_ index:Int, _ dx:CGFloat, _ dy:CGFloat) {
        let pos = cardData[index].homePosition
        cardData[index].view.frame = CGRect(x: pos.x + dx,y: pos.y + dy,width: cardXS,height: cardYS)
    }
    
    // MARK:-
    
    func setFaceUp(_ index:Int, _ faceUp:Bool) {
        self.cardData[index].view.image = faceUp ? self.cardPicture[self.cardData[index].picIndex] : backFace
    }
    
    let flipAngle = CGFloat(Float.pi)

    func animateFaceUp(_ index:Int, _ setDoneFlag:Bool = false) {
        setZ(index, 500)
        var pos = cardData[index].homePosition
        pos.y += 30
        
        let duration : TimeInterval = 0.1
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.cardData[index].view.layer.transform = CATransform3DIdentity
            self.cardData[index].view.layer.transform = CATransform3DRotate(self.cardData[index].view.layer.transform, -self.flipAngle,0,1, 0)
            self.cardData[index].view.frame = CGRect(x: pos.x,y: pos.y,width: cardXS,height: cardYS)
            
            }, completion: { (complete: Bool) in
                self.cardData[index].view.image = self.cardPicture[self.cardData[index].picIndex]
                
                UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                    self.cardData[index].view.layer.transform = CATransform3DRotate(self.cardData[index].view.layer.transform, +self.flipAngle,0,1, 0)
                    self.cardData[index].view.frame = CGRect(x: self.cardData[index].homePosition.x,y: self.cardData[index].homePosition.y,width: cardXS,height: cardYS)

                    }, completion: { (complete: Bool) in
                        if setDoneFlag {
                            game.doneFlagSet()
                        }
                    }
                )
            }
        )
    }
    
    // MARK:-
    
    func shuffle() {
        for _ in 0 ..< 1000 {
            let i1 = Int(arc4random_uniform(UInt32(NUM_CARDS)))
            let i2 = Int(arc4random_uniform(UInt32(NUM_CARDS)))
            
            let t = cardData[i1]
            cardData[i1] = cardData[i2]
            cardData[i2] = t
        }
    }

    // MARK:-
    
    let sName:[String] = [ "Clubs","Spades","Hearts","Diamonds" ]
    let rName:[String] = [ "Ace","2","3","4","5","6","7","8","9","10","J","Q","K" ]
    
    func name(_ suit:Int, rank:Int) -> String {
        return rName[rank] + " of " + sName[suit]
    }
    
}
