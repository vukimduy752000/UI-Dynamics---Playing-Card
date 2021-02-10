
import UIKit


class PlayingCardDeckScreen: UIViewController
{
    //MARK: Properties
    
    /**Model */
    private lazy var deck = PlayingCardDeck()
    
    
    //MARK: Hook up Gesture Recognizer with the playingCardView
    @IBOutlet private var playingCardViews: [KDPlayingCardView]!
    
    lazy var animator = UIDynamicAnimator(referenceView: view)
    lazy var cardBehavior = CardBehavior(in: animator)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureInitialSetup()
    }
    
    
    //MARK: Configure Initial Setup
    func configureInitialSetup() {
        
        // Drawing card from Model
        var cards = [PlayingCard]()
        for _ in 1...((playingCardViews.count + 1) / 2) {
            let card = deck.drawCard()!
            cards += [card,card]
        }
        
        
        // Drawing card to View
        for playingCardView in playingCardViews {
            playingCardView.isFaceUp = false
            
            let playingCard = cards.remove(at: cards.count.arc4random)
            playingCardView.rank = playingCard.rank.numericalRank
            playingCardView.suit = playingCard.suit.rawValue
            playingCardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(touchCardView(_:))))
            cardBehavior.addItem(playingCardView)
        }
    }
    
    //MARK: Animation
    private var faceUpCardViews: [KDPlayingCardView] {
        return playingCardViews.filter {
            $0.isFaceUp && !$0.isHidden && $0.transform != CGAffineTransform.identity.scaledBy(x: 3.0, y: 3.0) && $0.alpha == 1
        }
    }
    
    private var faceUpCardViewsMatch: Bool {
        return faceUpCardViews.count == 2 &&
            faceUpCardViews[0].rank == faceUpCardViews[1].rank &&
            faceUpCardViews[0].suit == faceUpCardViews[1].suit
    }
    
    private var lastChosenCard: KDPlayingCardView?
    
    @objc func touchCardView(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
            case .ended:
                
                //MARK: Working on the card involving in the match
                /// - Just choose 1 card per round -> faceUpCardViews.count < 2
                if let chosenCardView = recognizer.view as? KDPlayingCardView, faceUpCardViews.count < 2 {
                    lastChosenCard     = chosenCardView
                    cardBehavior.removeItem(chosenCardView)
                    
                    UIView.transition(with: chosenCardView,
                                      duration: 3.0,
                                      options: [.transitionFlipFromLeft]) {
                        chosenCardView.isFaceUp = !chosenCardView.isFaceUp
                        
                    } completion: { [self] (finished) in
                        
                        // Recalculate the faceUpCardView
                        let cardsToAnimate = faceUpCardViews
                        
                        print(faceUpCardViews.count)
                        
                        //MARK: Match
                        if faceUpCardViewsMatch {
                            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6,
                                                                           delay: 0,
                                                                           options: [.curveEaseIn]) {
                                cardsToAnimate.forEach {
                                    $0.transform = CGAffineTransform.identity.scaledBy(x: 3, y: 3)
                                }
                            } completion: { (finished) in
                                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6,
                                                                               delay: 0,
                                                                               options: [.curveEaseIn]) {
                                    cardsToAnimate.forEach {
                                        $0.transform = CGAffineTransform.identity.scaledBy(x: 0.1, y: 0.1)
                                        $0.alpha = 0
                                    }
                                } completion: { (finished) in
                                    cardsToAnimate.forEach {
                                        
                                        // Also inside the superview's list of subviews
                                        $0.isHidden  = true
                                        $0.alpha     = 100
                                        $0.transform = .identity
                                    }
                                }
                            }
                            
                            
                            //MARK: Dont't match
                        } else if cardsToAnimate.count == 2
                        {
                            if chosenCardView == self.lastChosenCard {
                                cardsToAnimate.forEach { faceUpCard in
                                    UIView.transition(with: faceUpCard, duration: 3.0, options: .transitionFlipFromRight)
                                    {
                                        faceUpCard.isFaceUp = !faceUpCard.isFaceUp
                                    } completion: { (finished) in
                                        cardBehavior.addItem(faceUpCard)
                                    }
                                }
                            }
                            
                            
                            //MARK: Reselect the chosen card
                        } else {
                            if !chosenCardView.isFaceUp {
                                cardBehavior.addItem(chosenCardView)
                            }
                        }
                    }
                }
            default: break
        }
    }
    
}

extension CGFloat {
    var arc4random: CGFloat {
        if self > 0 {
            return CGFloat(arc4random_uniform(UInt32(self)))
        } else if self < 0 {
            return -CGFloat(arc4random_uniform(UInt32(-self)))
        } else {
            return 0
        }
    }
}


