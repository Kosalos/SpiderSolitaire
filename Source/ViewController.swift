import UIKit
import QuartzCore

var cards = Cards()
var game = Game()

var screenYS = CGFloat()
var cardXS = CGFloat()
var cardYS = CGFloat()
var dealPosition = CGPoint()
var offscreenPosition = CGPoint()

class ViewController: UIViewController {

    @IBOutlet var undoButton: UIButton!
    @IBOutlet var addCardsButton: UIButton!
    @IBOutlet var newGameButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let xs = view.bounds.width
        screenYS = view.bounds.height
        
        cardXS = xs/10
        cardYS = cardXS * 4 / 3
        cards.initialize(self.view)

        dealPosition = CGPoint(x: xs - cardXS/3, y: screenYS - cardYS/2)
        offscreenPosition = CGPoint(x:1500, y: screenYS - cardYS/2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        newGame(newGameButton)
    }
    
    override var prefersStatusBarHidden : Bool { return true  }
    
    // MARK:-
    
    func startNewGame(_ style:Int) {
        if style == 3 { return } // 'Cancel'
        game.newGame(style)
        updateButtonEnables()
    }

    @IBAction func newGame(_ sender:UIButton) {
        let gName:[String] = [ "1 (Easy)","2 (Medium)","4 (Hard)","Cancel" ]
        let alert = UIAlertController(title: "New Game", message: "Select Number of Suits", preferredStyle: .actionSheet)
        
        for i in 0 ..< gName.count {
            let sa = UIAlertAction(title: gName[i], style: .default) { action -> Void in self.startNewGame(i) }
            alert.addAction(sa)
        }
        
        alert.popoverPresentationController?.sourceView = sender
        self.present(alert, animated: true, completion: nil)

    }
    
    @IBAction func undo(_ sender: AnyObject) {
        game.undo()
        updateButtonEnables()
    }
    
    @IBAction func addCards(_ sender: AnyObject) {
        game.addRowOfFaceUpCards()
        updateButtonEnables()
    }
    
    func updateButtonEnables() {
        undoButton!.isEnabled = game.isUndoAvailable()
        addCardsButton!.isEnabled = game.okToAddCards()
    }

    // MARK:-
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesBegan(touch.location(in: self.view))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesMoved(touch.location(in: self.view))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        game.touchesEnded()
        updateButtonEnables()
    }
}
