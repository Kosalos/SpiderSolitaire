import UIKit

let NUMCOLUMNS = 10
let NUMROWS = 50
let KING = 12
let MAX_SPACING = 70
let EMPTY = -1
let MAX_UNDO = 50

struct BoardPosition {
    var position:CGPoint
    var cardIndex:Int
    var face:Bool
    
    init() {
        position = CGPoint()
        cardIndex = EMPTY
        face = false
    }
}

struct GameData {
    var board = Array<Array<BoardPosition>>()
    var deckIndex:Int = 0
}

var gd = GameData()

class Game {
    let DEAL_DELAY:TimeInterval = 0.1
    
    var verticalSpacingBetweenCards = [Int]()
    var touchStartColumn:Int = EMPTY
    var touchStartRow:Int = 0
    var touchPt:CGPoint = CGPoint.zero
    var tapped:Bool = false
    var isSameSuit:Bool = false
    var finishedSession:Bool = true
    var dealDelay:TimeInterval = 0
    
    init() {
        func createBoard(_ ptr:inout GameData) {
            for _ in 0 ..< NUMCOLUMNS {
                ptr.board.append(Array(repeating: BoardPosition(), count: NUMROWS))
            }
        }
        
        createBoard(&gd)
        
        for _ in 0 ..< MAX_UNDO {
            var v = GameData()
            createBoard(&v)
            undoMemory.append(v)
        }
        
        for _ in 0 ..< NUMCOLUMNS {
            verticalSpacingBetweenCards.append(0)
        }
    }
    
    func doneFlagSet() {
        finishedSession = true
        updateVerticalSpacingOfAllCards()
    }
    
    // MARK:-
    
    func newGame(_ style:Int) {
        if !finishedSession { return } // must wait until previous session is finished
        finishedSession = false
        
        resetUndo()
        
        cards.setNumberOfDecks(style)
        cards.shuffle()
        
        gd.deckIndex = NUM_CARDS-1
        
        // start with empty board
        for c:Int in 0 ..< NUMCOLUMNS {
            for r:Int in 0 ..< NUMROWS {
                gd.board[c][r].cardIndex = EMPTY
                gd.board[c][r].position.x = CGFloat(c) * cardXS
                gd.board[c][r].position.y = CGFloat(r) * CGFloat(MAX_SPACING)
            }
        }
        
        dealDelay = 0
        
        UIView.animate(withDuration: 0.5, delay: dealDelay, options: .curveLinear, animations:
            {
                for i in 0 ..< NUM_CARDS { // move All Cards To Deal Pile
                    cards.setPosition(i, dealPosition)
                    cards.setFaceUp(i, false)
                    cards.setZ(i, i)
                }
        }, completion: { (complete: Bool) in
            
            // face down cards:  4 full rows, 1 partial row of 4 columns
            for i in 0 ..< NUMCOLUMNS*4 {
                self.addCardToColumn(gd.deckIndex, i % NUMCOLUMNS, false, self.dealDelay)
                gd.deckIndex -= 1
                self.dealDelay += self.DEAL_DELAY
            }
            
            for i in 0 ..< 4 {
                self.addCardToColumn(gd.deckIndex, i % NUMCOLUMNS, false, self.dealDelay)
                gd.deckIndex -= 1
                self.dealDelay += self.DEAL_DELAY
            }
            
            // one row of face up cards
            for i in 0 ..< NUMCOLUMNS {
                self.addCardToColumn(gd.deckIndex, i % NUMCOLUMNS, false, self.dealDelay, (i == NUMCOLUMNS-1), true)
                gd.deckIndex -= 1
                self.dealDelay += self.DEAL_DELAY
            }
        }
        )
    }
    
    // MARK:-
    
    func addCardToColumn(_ cardIndex:Int, _ column:Int, _ isFaceUp:Bool, _ delay:TimeInterval,
                         _ flipBottomRowWhenFinished:Bool = false,
                         _ setDoneFlag:Bool = false)
    {
        // find topMost open position
        var row:Int = EMPTY
        for r:Int in 0 ..< NUMROWS {
            if gd.board[column][r].cardIndex == EMPTY {
                row = r
                break
            }
        }
        if row == EMPTY { return } // column is full
        
        gd.board[column][row].cardIndex = cardIndex
        gd.board[column][row].face = isFaceUp
        
        cards.setZ(cardIndex, row)
        
        UIView.animate(withDuration: 0.3, delay: delay, options: .curveLinear, animations: {
            cards.setPosition(cardIndex, gd.board[column][row].position)
            cards.setFaceUp(cardIndex, isFaceUp)
        }, completion: { (complete: Bool) in
            if flipBottomRowWhenFinished {
                for column in 0 ..< NUMCOLUMNS {
                    self.flipCardFaceUp(column, self.rowOfBottomMostCardInColumn(column), (column == NUMCOLUMNS-1))
                }
            }
            else {
                if setDoneFlag {
                    self.doneFlagSet()
                }
            }
        }
        )
    }
    
    // MARK:-
    
    func rowOfBottomMostCardInColumn(_ column:Int) -> Int {
        for row in 0 ..< NUMROWS-1 {
            if gd.board[column][row+1].cardIndex == EMPTY { // row below me is empty
                return row
            }
        }
        
        return NUMROWS-1
    }
    
    // faceup.  last card, or top of group of descending same suit
    
    func isLegalToMoveThisCard(_ column:Int, _ selectedRow:Int) -> Bool {
        if selectedRow == NUMROWS-1 {
            return true
        }
        
        var row = selectedRow  // start at the row for the top of this group
        var topCardOfGroup = cards.card(gd.board[column][row].cardIndex)
        
        if gd.board[column][selectedRow].face == false {
            return false
        }
        
        // if there are cards below the selected one, they must all be same suit and descending rank
        while true {
            if gd.board[column][row].cardIndex == EMPTY {
                return true
            }
            
            let card = cards.card(gd.board[column][row].cardIndex)
            
            if card.suit != topCardOfGroup.suit {
                return false
            }
            
            if card.rank != topCardOfGroup.rank {
                return false
            }
            
            topCardOfGroup.rank -= 1
            row += 1
            if row == NUMROWS { return true }
        }
    }
    
    // current bottommost card of destination column must be rank+1 (or empty column)
    
    func isLegalToDropCardOnThisColumn(_ column:Int) -> Bool {
        if gd.board[column][0].cardIndex == EMPTY {
            return true
        }
        
        let card1 = cards.card(gd.board[touchStartColumn][touchStartRow].cardIndex)
        
        if card1.rank == KING {
            return false
        }
        
        let row = rowOfBottomMostCardInColumn(column)
        if row >= NUMROWS-1 {
            return false
        }
        
        let card2 = cards.card(gd.board[column][row].cardIndex)
        
        isSameSuit = (card1.suit == card2.suit)
        
        let sourceRank = card1.rank
        let destinationRank = card2.rank
        
        if destinationRank == sourceRank+1 {
            return true
        }
        
        return false
    }
    
    // MARK:-
    
    func moveCardsToNewColumn(_ oldColumn:Int, _ oldRow:Int, _ newColumn:Int) {
        var oldRow = oldRow
        var delay:TimeInterval = 0
        
        while true {
            if oldRow >= NUMROWS {  break }
            
            let cardIndex = gd.board[oldColumn][oldRow].cardIndex
            if cardIndex == EMPTY { break }
            
            addCardToColumn(cardIndex, newColumn, true, delay, false, true)
            gd.board[oldColumn][oldRow].cardIndex = EMPTY
            oldRow += 1
            delay += 0.1
        }
    }
    
    func updateCurrentPositionOfMovingCards(_ dx:CGFloat, _ dy:CGFloat) {
        var row = touchStartRow
        
        while true {
            if row >= NUMROWS { return }
            let cardIndex = gd.board[touchStartColumn][row].cardIndex
            if cardIndex == EMPTY { return }
            
            cards.setDeltaPosition(cardIndex,dx,dy)
            row += 1
        }
    }
    
    func sendMovingCardsBackHome() {
        var row = touchStartRow
        
        while true {
            if row >= NUMROWS { return }
            let cardIndex = gd.board[touchStartColumn][row].cardIndex
            if cardIndex == EMPTY { return }
            
            cards.goBackHome(cardIndex)
            row += 1
        }
    }
    
    func flipCardFaceUp(_ column:Int, _ row:Int, _ setDoneFlag:Bool = false) {
        if row < 0 { return }
        
        if gd.board[column][row].face == false {
            let cardIndex = gd.board[column][row].cardIndex
            if cardIndex != EMPTY {
                cards.animateFaceUp(cardIndex,setDoneFlag)
                gd.board[column][row].face = true
            }
        }
    }
    
    func flipUpNewlyExposedCard(_ column:Int, _ row:Int) {
        if row >= 0 {
            let cardIndex = gd.board[column][row].cardIndex
            if cardIndex != EMPTY {
                flipCardFaceUp(column, row)
            }
        }
    }
    
    // MARK:-
    
    func updateVerticalSpacingOfAllCards() {
        for column in 0 ..< NUMCOLUMNS {
            let row = rowOfBottomMostCardInColumn(column)
            
            if row == 0 {
                verticalSpacingBetweenCards[column] = MAX_SPACING
            }
            else {
                verticalSpacingBetweenCards[column] = Int((screenYS - cardYS - CGFloat(70)) / CGFloat(row))
                
                if verticalSpacingBetweenCards[column] > MAX_SPACING {
                    verticalSpacingBetweenCards[column] = MAX_SPACING
                }
            }
            
            for y:Int in 0 ..< NUMROWS {
                gd.board[column][y].position.y = CGFloat(y * verticalSpacingBetweenCards[column])
            }
        }
        
        // command all cards to move to updated positions (and adjust Z coords)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear,
                       animations: {
                        for c:Int in 0 ..< NUMCOLUMNS {
                            for r:Int in 0 ..< NUMROWS {
                                let cardIndex = gd.board[c][r].cardIndex
                                if cardIndex == EMPTY { break }
                                
                                cards.setZ(cardIndex,r)
                                cards.setPosition(cardIndex, gd.board[c][r].position)
                            }
                        }
        }, completion: nil)
    }
    
    // MARK:-
    
    func performAutoMove(_ column:Int) {
        moveCardsToNewColumn(touchStartColumn, touchStartRow, column)
        flipUpNewlyExposedCard(touchStartColumn, touchStartRow-1)
        checkForFullGroup()
    }
    
    func checkForAutoMove() {
        var differentSuitColumn = EMPTY
        var emptyColumn = EMPTY
        var destinationColumn:Int
        
        for i in 0 ..< NUMCOLUMNS {
            destinationColumn = touchStartColumn + i
            if destinationColumn >= NUMCOLUMNS {
                destinationColumn -= NUMCOLUMNS
            }
            
            if gd.board[destinationColumn][0].cardIndex == EMPTY {
                emptyColumn = destinationColumn
                continue
            }
            
            if isLegalToDropCardOnThisColumn(destinationColumn) {
                if isSameSuit {
                    performAutoMove(destinationColumn)
                    return
                }
                
                differentSuitColumn = destinationColumn
            }
        }
        
        if differentSuitColumn != EMPTY {
            destinationColumn = differentSuitColumn
        }
        else {
            if emptyColumn != EMPTY {
                destinationColumn = emptyColumn
            }
            else {
                return
            }
        }
        
        performAutoMove(destinationColumn)
    }
    
    // MARK:-
    
    func addRowOfFaceUpCards() {
        if !finishedSession { return } // must wait until previous session is finished
        finishedSession = false
        
        if gd.deckIndex > 0 {
            
            copytoUndo()
            
            dealDelay = 0
            for i in 0 ..< NUMCOLUMNS {
                addCardToColumn(gd.deckIndex, i % NUMCOLUMNS, false, dealDelay, (i == NUMCOLUMNS-1))
                gd.deckIndex -= 1
                dealDelay += DEAL_DELAY
            }
        }
    }
    
    func okToAddCards() -> Bool {
        if gd.deckIndex <= 0 {
            return false	// no cards left
        }
        
        // have enough cards on board to have at least one card in each column?
        var count = 0
        for c:Int in 0 ..< NUMCOLUMNS {
            for r:Int in 0 ..< NUMROWS {
                if gd.board[c][r].cardIndex != EMPTY {
                    count += 1
                }
            }
        }
        if count < NUMCOLUMNS { // not enough. ok to add now
            return true
        }
        
        // have enough cards to enforce rule that all columns must be populated
        for c:Int in 0 ..< NUMCOLUMNS {
            if gd.board[c][0].cardIndex == EMPTY {
                return false
            }
        }
        
        return true
    }
    
    // MARK:-
    
    func checkForFullGroupKingToAceOfSameSuit(_ column:Int, _ row:Int) {
        var topCard = cards.card(gd.board[column][row].cardIndex)
        
        for r in row+1 ..< NUMROWS {
            topCard.rank -= 1
            if topCard.rank < 0 {	// have encountered all cards of a group. remove them all
                
                UIView.animate(withDuration: 1, delay:2, options: .curveLinear, animations: {
                    for k in row ..< NUMROWS {
                        let cardIndex = gd.board[column][k].cardIndex
                        if cardIndex == EMPTY { break }
                        cards.setPosition(cardIndex, offscreenPosition)
                        gd.board[column][k].cardIndex = EMPTY
                    }
                }, completion: { (complete: Bool) in
                    self.flipUpNewlyExposedCard(column, row-1)
                }
                )
                
                return
            }
            
            let cardIndex = gd.board[column][r].cardIndex
            if cardIndex == EMPTY { return }
            
            let card = cards.card(cardIndex)
            if card.suit != topCard.suit { return }
            if card.rank != topCard.rank { return }
        }
    }
    
    func checkForFullGroup() {
        for c:Int in 0 ..< NUMCOLUMNS {
            for r:Int in 0 ..< NUMROWS-KING-1 {
                let b = gd.board[c][r]
                if b.cardIndex == EMPTY { break }
                if b.face == false { continue }
                if cards.card(b.cardIndex).rank == KING {
                    checkForFullGroupKingToAceOfSameSuit(c,r)
                }
            }
        }
    }
    
    // MARK:-
    
    var touchBeganPoint = CGPoint()
    
    func touchesBegan(_ pt:CGPoint) {
        
        // set touchX,Y to board index of selected card(s)
        touchStartColumn = EMPTY // assume nothing selected
        
        var rect = CGRect(x:0, y:0, width:cardXS, height:0)
        
        for c:Int in 0 ..< NUMCOLUMNS {
            for r:Int in 0 ..< NUMROWS {
                if gd.board[c][r].cardIndex == EMPTY { break }
                
                rect.origin = gd.board[c][r].position
                rect.size.height = CGFloat(verticalSpacingBetweenCards[c])
                
                if rect.contains(pt) {
                    if isLegalToMoveThisCard(c,r) {
                        touchBeganPoint = pt
                        touchStartColumn = c
                        touchStartRow = r
                        tapped = true
                    }
                    
                    return
                }
            }
        }
    }
    
    func touchesMoved(_ pt:CGPoint) {
        if (fabs(pt.x-touchBeganPoint.x)+fabs(pt.y-touchBeganPoint.y)) > 10.0 {
            if touchStartColumn != EMPTY {
                tapped = false
                touchPt = pt
                
                // set moving cards above all board cards
                var r = touchStartRow
                while true {
                    let cardIndex = gd.board[touchStartColumn][r].cardIndex
                    if cardIndex == EMPTY { break }
                    
                    cards.setZ(cardIndex, 200+r)
                    r += 1
                }
                
                let dx = pt.x - touchBeganPoint.x
                let dy = pt.y - touchBeganPoint.y
                updateCurrentPositionOfMovingCards(dx,dy)
            }
        }
    }
    
    func touchesEnded() {
        if touchStartColumn == EMPTY { return }
        
        copytoUndo()
        
        if tapped {
            checkForAutoMove()
            touchStartColumn = EMPTY
            return
        }
        
        let column = Int(touchPt.x / cardXS)
        
        if isLegalToDropCardOnThisColumn(column) {
            moveCardsToNewColumn(touchStartColumn, touchStartRow, column)
            flipUpNewlyExposedCard(touchStartColumn, touchStartRow-1)
            checkForFullGroup()
        }
        else {
            sendMovingCardsBackHome()
        }
        
        touchStartColumn = EMPTY
    }
    
    // MARK:-
    
    var undoIndex = 0
    var undoCount = 0
    var undoMemory = Array<GameData>()
    
    func resetUndo() {
        undoIndex = 0
        undoCount = 0
    }
    
    func copyGameData(_ src:GameData, _ dest:inout GameData) {
        dest.deckIndex = src.deckIndex
        
        for c:Int in 0 ..< NUMCOLUMNS {
            for r:Int in 0 ..< NUMROWS {
                dest.board[c][r] = src.board[c][r]
            }
        }
    }
    
    func copytoUndo() {
        copyGameData(gd, &undoMemory[undoIndex])
        undoIndex += 1
        if undoIndex == MAX_UNDO {
            undoIndex = 0
        }
        
        undoCount += 1
        if undoCount == MAX_UNDO {
            undoCount = MAX_UNDO-1
        }
    }
    
    func undo() {
        if undoCount > 0 {
            undoCount -= 1
            
            undoIndex -= 1
            if undoIndex < 0 {
                undoIndex = MAX_UNDO-1
            }
            
            copyGameData(undoMemory[undoIndex], &gd)
            
            // 1. all cards off screen (assume they have already been removed)
            for i in 0 ..< NUM_CARDS {
                cards.setPosition(i, offscreenPosition)
            }
            
            // 2. cards 0..deckIndex to dealPosition (haven't been played yet)
            if gd.deckIndex > 0 {
                for i in 0 ..< gd.deckIndex {
                    cards.setPosition(i, dealPosition)
                    cards.setFaceUp(i, false)
                }
            }
            
            // 3. walk board, moving cards to populated spots
            for c:Int in 0 ..< NUMCOLUMNS {
                for r:Int in 0 ..< NUMROWS {
                    let cardIndex = gd.board[c][r].cardIndex
                    
                    if cardIndex == EMPTY {
                        break
                    }
                    
                    cards.setPosition(cardIndex, gd.board[c][r].position)
                    cards.setFaceUp(cardIndex, gd.board[c][r].face)
                    cards.setZ(cardIndex, r)
                }
            }
        }
    }
    
    func isUndoAvailable() -> Bool { return undoCount > 0 }
}
