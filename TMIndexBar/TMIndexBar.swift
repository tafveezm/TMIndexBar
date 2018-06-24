/**
 * Copyright (c) 2018 Tafveez Mehdi
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

public enum TMIndexBarAlignment {
    case center
    case top
    case bottom
}


public enum TMIndexBarPosition {
    case right
    case left
}

public protocol TMIndexBarDelegate: class {
    func numberOfIndexes(for indexBar: TMIndexBar) -> Int
    func fetchString(for index: Int) -> String
    func indexBarDidSelect(index: Int)
}

public class BarAppearanceBuilder {
    
    public static let kTMDefaultBarBackgroundWidth: CGFloat = 15.0
    public static let kTMDefaultFontName = "HelveticaNeue-Bold"
    public static let kTMDefaultFontSize: CGFloat = 13.0
    public static let kTMDefaultTextSpacing: CGFloat = 5
    public static let kTMDefaultTruncatedItemText = "•"
    public static let kTMDefaultBarWidth: CGFloat = 30
    public static let kTMDefaultOffset = UIOffset(horizontal: (kTMDefaultBarWidth - kTMDefaultBarBackgroundWidth)/2 , vertical: 0)
    
    var truncatedItemText: String
    var indexBarVerticalAlignment: TMIndexBarAlignment
    var alwaysShowBarBackground: Bool
    
    var barWidth: CGFloat
    var barBackgroundWidth: CGFloat
    var barBackgroundColor: UIColor
    
    var barBackgroundOffset: UIOffset
    
    var textOffset: UIOffset
    var textFont: UIFont
    var textColor: UIColor
    var textSpacing: CGFloat
    var textShadowColor: UIColor
    var backgroundViewCornerRadius: CGFloat
    var indexBarPosition: TMIndexBarPosition
    
    public init( truncatedItemText: String = kTMDefaultTruncatedItemText,
         indexBarVerticalAlignment: TMIndexBarAlignment = .center,
         alwaysShowBarBackground: Bool = true,
         barWidth: CGFloat = kTMDefaultBarWidth,
         barBackgroundWidth: CGFloat = kTMDefaultBarBackgroundWidth,
         barBackgroundColor: UIColor = UIColor.white,
         barBackgroundOffset: UIOffset = kTMDefaultOffset,
         textOffset: UIOffset = kTMDefaultOffset,
         textShadowOffset: UIOffset = kTMDefaultOffset,
         textFont: UIFont = UIFont(name: kTMDefaultFontName, size: kTMDefaultFontSize)!,
         textColor: UIColor = UIColor.white,
         textSpacing: CGFloat = kTMDefaultTextSpacing,
         textShadowColor: UIColor = UIColor.blue,
         backgroundViewCornerRadius: CGFloat = 0,
         indexBarPosition: TMIndexBarPosition = .right)
    {
        self.truncatedItemText = truncatedItemText
        self.indexBarVerticalAlignment = indexBarVerticalAlignment
        self.alwaysShowBarBackground = alwaysShowBarBackground
        self.barWidth = barWidth
        self.barBackgroundWidth = barBackgroundWidth
        self.barBackgroundColor = barBackgroundColor
        self.barBackgroundOffset = barBackgroundOffset
        self.textOffset = textOffset
        self.textFont = textFont
        self.textColor = textColor
        self.textSpacing = textSpacing
        self.textShadowColor = textShadowColor
        self.backgroundViewCornerRadius = backgroundViewCornerRadius
        self.indexBarPosition = indexBarPosition
        
        if indexBarPosition == .left {
            self.textOffset = UIOffset(horizontal: -textOffset.horizontal, vertical: textOffset.vertical)
            self.barBackgroundOffset = UIOffset(horizontal: -barBackgroundOffset.horizontal, vertical: barBackgroundOffset.vertical)
        }
    }
}

public class TMIndexBar: UIControl {
    
    static let kShowDebugOutlines = false
    static let kObservingContext = "TMIndexBarContext"
    static let kObservingKeyPath = "bounds"
    
    weak var delegate: TMIndexBarDelegate? {
        didSet {
            if delegate != nil && tableView != nil {
                reload()
            }
        }
    }
    @IBOutlet weak var tableView: UITableView!
    var backgroundView: UIView?
    
    var barAppearanceBuilder: BarAppearanceBuilder
    
    var numberOfIndices: Int?
    var lastSelectedStringIndex: Int?
    var lineHeight: CGFloat?
    var textAttributes: [String: Any]?
    var currentTouch: UITouch?
    var indexStrings: [String]?
    var displayedIndexStrings: [String]?
    
    var desiredHeight: CGFloat {
        let rowHeight = lineHeight! + barAppearanceBuilder.textSpacing
        return barAppearanceBuilder.textSpacing * CGFloat(2) + CGFloat(rowHeight) * CGFloat(numberOfIndices!)
    }
    
    var numberOfDisplayableRows: Int {
        let rowHeight = lineHeight! + barAppearanceBuilder.textSpacing
        if desiredHeight > self.bounds.size.height {
            var numberOfRowsThatFit = Int(self.bounds.height / rowHeight)
            numberOfRowsThatFit -= (numberOfRowsThatFit % 2 == 0) ? 1 : 0
            return numberOfRowsThatFit
        }
        return numberOfIndices!
    }
    
    public init(with tableView: UITableView, barAppearanceBuilder: BarAppearanceBuilder = BarAppearanceBuilder()) {
        self.tableView = tableView
        self.barAppearanceBuilder = barAppearanceBuilder
        super.init(frame: CGRect.zero)
        
        initializeIndexBar()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
 
    override public func awakeFromNib() {
        super.awakeFromNib()
        initializeIndexBar()
    }
    
    func initializeIndexBar(){
        initializeBackgroundView()
        lastSelectedStringIndex = nil
        
        isExclusiveTouch = true
        isMultipleTouchEnabled = false
        self.backgroundColor = UIColor.clear
        
        reload()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: Notification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardChange), name: Notification.Name.UIKeyboardDidHide, object: nil)
        
    }
    
    
    func reload(){
        guard let delegate = self.delegate else { return }
        
        self.numberOfIndices = delegate.numberOfIndexes(for: self)
        lineHeight = ("0" as NSString).size(withAttributes: [NSAttributedStringKey.font: barAppearanceBuilder.textFont]).height
        indexStrings = [String]()
        
        for i in 0..<numberOfIndices! {
            indexStrings?.append(delegate.fetchString(for: i))
        }
        
        setNeedsLayout()
        setNeedsDisplay()
    }
    
}


// MARK: - Notification methods
extension TMIndexBar {

    @objc func handleDeviceOrientationChange(){
        setNeedsLayout()
    }
    
    @objc func handleKeyboardChange(){
        setNeedsLayout()
    }
}


// MARK: - Layout
extension TMIndexBar {
    
    func updateDisplaedIndexStrings(){
        guard desiredHeight > self.bounds.size.height else {
            displayedIndexStrings = indexStrings
            return
        }
        
        displayedIndexStrings = [String]()
        let numberOfRowsToFit = self.numberOfDisplayableRows
        let step = CGFloat(indexStrings!.count / numberOfRowsToFit)
        var stepIndex: CGFloat = 0
        for i in 0..<numberOfRowsToFit {
            let letterIndex = Int(stepIndex.rounded())
            // for every other letter, use the truncated text string instead of the actual letter.
            if (i % 2 == 1) {
                displayedIndexStrings?.insert(barAppearanceBuilder.truncatedItemText, at: i)
            }
                // otherwise, store the actual letter
            else {
                var letter = ""
                if letterIndex < indexStrings!.count {
                    // if this is the last letter displayed, but is not using the last letter,
                    // then force the last letter to be displayed to footnote the bar
                    if (i+1 == numberOfRowsToFit && letterIndex != numberOfRowsToFit-1) {
                        letter = indexStrings!.last!
                    }
                    else {
                        letter = indexStrings![letterIndex]
                    }
                }
                else {
                    letter = indexStrings!.last!
                }
                displayedIndexStrings?.insert(letter, at: i)
            }
            stepIndex += step
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let newFrame = rectForIndexBarFrame()
        let hasNewSize = !self.frame.size.equalTo(newFrame.size)
        self.frame = newFrame
        self.backgroundView?.frame = self.rectForBarBackgroundView()
        if self.superview is UITableView {
            self.superview?.bringSubview(toFront: self)
        }
        
        if hasNewSize {
            self.setNeedsLayout()
        }
        
    }
    
    
    func rectForIndexBarFrame() -> CGRect {
        
        var relativeTableViewTopHorizontalPoint: CGPoint!
        var origin: CGPoint!
        
        if barAppearanceBuilder.indexBarPosition == .right {
            relativeTableViewTopHorizontalPoint = tableView.convert(CGPoint(x: tableView.frame.size.width, y: 0), to: self.superview)
            origin = CGPoint(x: relativeTableViewTopHorizontalPoint.x - barAppearanceBuilder.barWidth, y: relativeTableViewTopHorizontalPoint.y + tableView.contentOffset.y + tableView.contentInset.bottom)
        } else {
            relativeTableViewTopHorizontalPoint = tableView.convert(CGPoint(x: 0, y: 0), to: self.superview)
            origin = CGPoint(x: 0 , y: relativeTableViewTopHorizontalPoint.y + tableView.contentOffset.y + tableView.contentInset.top)
        }
        
        let height = tableView.frame.size.height - (tableView.contentInset.top + tableView.contentInset.bottom)
        let size = CGSize(width: barAppearanceBuilder.barWidth, height: height)
        
        
        return CGRect(origin: origin, size: size)
    }
    
    
    
    func rectForBarBackgroundView() -> CGRect {
        return CGRect(x:barAppearanceBuilder.barWidth * 0.5 - barAppearanceBuilder.barBackgroundWidth * 0.5 + barAppearanceBuilder.barBackgroundOffset.horizontal,
                      y: 0,
                      width: barAppearanceBuilder.barBackgroundWidth,
                      height: self.frame.size.height)


    }
    
    func rectForTextArea() -> CGRect {
        let indexRowHeight = barAppearanceBuilder.textSpacing + lineHeight!
        let height = indexRowHeight * CGFloat(numberOfDisplayableRows) + barAppearanceBuilder.textSpacing * CGFloat(2)
        
        var yp: CGFloat = 0
        switch (barAppearanceBuilder.indexBarVerticalAlignment) {
        case .top:
            yp = barAppearanceBuilder.textOffset.vertical
            break;
            
        case .bottom:
            yp = self.frame.size.height - barAppearanceBuilder.textOffset.vertical - height
            break;
            
        default:
            yp = self.bounds.size.height * 0.5 - height * 0.5 + barAppearanceBuilder.textOffset.vertical
            break
        }
        
        yp = CGFloat(fmaxf(0.0, Float(yp)))
        
        return CGRect(x: 0, y: yp, width: barAppearanceBuilder.barWidth, height: height)
    }
}


// MARK: - Drawing.
extension TMIndexBar {
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        updateDisplaedIndexStrings()
        
        let indexCount = displayedIndexStrings?.count
        let barBackgroundRect = rectForBarBackgroundView()
        let textAreaRect = rectForTextArea()
        
        var yp = barAppearanceBuilder.textSpacing + textAreaRect.origin.y  + barAppearanceBuilder.textOffset.vertical
        let ctx = UIGraphicsGetCurrentContext()
        
        if TMIndexBar.kShowDebugOutlines {
            ctx!.setLineWidth(2)
            ctx!.setStrokeColor(UIColor.orange.cgColor)
            ctx!.stroke(textAreaRect)
        }
        
        if (barAppearanceBuilder.alwaysShowBarBackground || self.isHighlighted) {
            ctx?.translateBy(x: barBackgroundRect.origin.x, y: barBackgroundRect.origin.y)
            backgroundView?.layer.render(in: ctx!)
            ctx?.translateBy(x: -barBackgroundRect.origin.x, y: -barBackgroundRect.origin.y)
        }
        
        for  i in 0..<indexCount! {
            let text = displayedIndexStrings![i]
            let textSize = (text as NSString).size(withAttributes: [NSAttributedStringKey.font: barAppearanceBuilder.textFont])
            
            let point = CGPoint(x: rect.size.width * 0.5 - textSize.width * 0.5 + barAppearanceBuilder.textOffset.horizontal, y: yp)
            
            // draw normal color
            barAppearanceBuilder.textColor.set()
            
            (text as NSString).draw(in: CGRect(x: point.x, y: point.y, width: textSize.width, height: lineHeight!), withAttributes:  [NSAttributedStringKey.font: barAppearanceBuilder.textFont])
            
            yp += lineHeight! + barAppearanceBuilder.textSpacing
        }
    }
    
    func CGPointAdd(_ point1: CGPoint, _ point2: CGPoint) -> CGPoint {
        return CGPoint(x: point1.x + point2.x, y: point1.y + point2.y)
    }
    
}


// MARK: - Touch handling
extension TMIndexBar {
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = Array(touches).last else { return }
        if rectForTextArea().contains(touch.location(in: self)) {
            currentTouch = touch
            isHighlighted = rectForTextArea().contains(currentTouch!.location(in: self))
            handleTouch(currentTouch!)
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentTouch = currentTouch, touches.contains(currentTouch) else { return }
        
        isHighlighted = rectForTextArea().contains(currentTouch.location(in: self))
        handleTouch(currentTouch)
        
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentTouch = self.currentTouch, touches.contains(currentTouch) {
            isHighlighted = false
            self.currentTouch = nil
        }
        
        lastSelectedStringIndex = nil
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.contains(currentTouch!) {
            isHighlighted = false
            currentTouch = nil
        }
        
        lastSelectedStringIndex = nil
    }
    
    func handleTouch(_ touch: UITouch) {
        let touchPoint = touch.location(in: self)
        let textAreaRect = rectForTextArea()
        let progress = fmaxf(0, fminf( Float(touchPoint.y - textAreaRect.origin.y) / Float(textAreaRect.size.height), 0.999))
        
        let stringIndex = Int(floorf(progress * Float(indexStrings!.count)))
        
        if stringIndex != lastSelectedStringIndex {
            delegate?.indexBarDidSelect(index: stringIndex)
            lastSelectedStringIndex = stringIndex
        }
        
    }
    
    func initializeBackgroundView(){
        if (backgroundView == nil) {
            backgroundView = UIView(frame: CGRect.zero)
            backgroundView!.backgroundColor = self.barAppearanceBuilder.barBackgroundColor
            backgroundView!.layer.cornerRadius = self.barAppearanceBuilder.backgroundViewCornerRadius
        }
    }
}













