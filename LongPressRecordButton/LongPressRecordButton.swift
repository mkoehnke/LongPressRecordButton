//
// LongPressRecordButton.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit

//================================================
// MARK: Delegate
//================================================

/// The delegate protocol of LongPressRecordButton.
@objc public protocol LongPressRecordButtonDelegate {
    /// Tells the delegate that a long press has started.
    func longPressRecordButtonDidStartLongPress(_ button : LongPressRecordButton)
    /// Tells the delegate that a long press has finished.
    func longPressRecordButtonDidStopLongPress(_ button: LongPressRecordButton)
    /// Tells the delegate that a tool tip should be presented when a short press occured.
    @objc optional func longPressRecordButtonShouldShowToolTip(_ button : LongPressRecordButton) -> Bool
    /// Tells the delegate that a short press has occured and therefore a tooltip is shown.
    @objc optional func longPressRecordButtonDidShowToolTip(_ button : LongPressRecordButton)
}

//================================================
// MARK: RecordButton
//================================================

/// The LongPressRecordButton class.
@IBDesignable open class LongPressRecordButton : UIControl {
    
    /// The delegate of the LongPressRecordButton instance.
    open weak var delegate : LongPressRecordButtonDelegate?
    
    /// The minmal duration, that the record button is supposed
    /// to stay in the 'selected' state, once the long press has
    /// started.
    @IBInspectable open var minPressDuration : Float = 1.0
    
    /// The width of the outer ring of the record button.
    @IBInspectable open var ringWidth : CGFloat = 4.0 {
        didSet { redraw() }
    }
    
    /// The color of the outer ring of the record button.
    @IBInspectable open var ringColor : UIColor? = UIColor.white {
        didSet { redraw() }
    }
    
    /// The margin between the outer ring and inner circle
    /// of the record button.
    @IBInspectable open var circleMargin : CGFloat = 0.0 {
        didSet { redraw() }
    }
    
    /// The color of the inner circle of the record button.
    @IBInspectable open var circleColor : UIColor? = UIColor.red {
        didSet { redraw() }
    }
    
    /// The text that the tooltip is supposed to display,
    /// if the user did short-press the button.
    open lazy var toolTipText : String = {
        return "Tap and Hold"
    }()
    
    /// The font of the tooltip text.
    open var toolTipFont : UIFont = {
        return UIFont.systemFont(ofSize: 12.0)
    }()
    
    /// The background color of the tooltip.
    open var toolTipColor : UIColor = {
        return UIColor.white
    }()
    
    /// The text color of the tooltip.
    open var toolTipTextColor : UIColor = {
        return UIColor(white: 0.0, alpha: 0.8)
    }()
    
    /// Determines if the record button is enabled.
    override open var isEnabled: Bool {
        didSet {
            let state : UIControlState = isEnabled ? UIControlState() : .disabled
            circleLayer.fillColor = circleColorForState(state)?.cgColor
            ringLayer.strokeColor = ringColorForState(state)?.cgColor
        }
    }
    
    // MARK: Initializers
    
    /// Initializer
    override init (frame : CGRect) {
        super.init(frame : frame)
        commonInit()
    }
    
    /// Initializer
    convenience init () {
        self.init(frame:CGRect.zero)
    }
    
    /// Initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    
    // MARK: Private
    
    fileprivate var longPressRecognizer : UILongPressGestureRecognizer!
    fileprivate var touchesStarted : CFTimeInterval?
    fileprivate var touchesEnded : Bool = false
    fileprivate var shouldShowTooltip : Bool = true
    
    fileprivate var ringLayer : CAShapeLayer!
    fileprivate var circleLayer : CAShapeLayer!
    
    fileprivate var outerRect : CGRect {
        return CGRect(x: ringWidth/2, y: ringWidth/2, width: bounds.size.width-ringWidth, height: bounds.size.height-ringWidth)
    }
    
    fileprivate var innerRect : CGRect {
        let innerX = outerRect.origin.x + (ringWidth/2) + circleMargin
        let innerY = outerRect.origin.y + (ringWidth/2) + circleMargin
        let innerWidth = outerRect.size.width - ringWidth - (circleMargin * 2)
        let innerHeight = outerRect.size.height - ringWidth - (circleMargin * 2)
        return CGRect(x: innerX, y: innerY, width: innerWidth, height: innerHeight)
    }
    
    fileprivate func commonInit() {
        backgroundColor = UIColor.clear
        
        ringLayer = CAShapeLayer()
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.frame = bounds
        layer.addSublayer(ringLayer)
        
        circleLayer = CAShapeLayer()
        circleLayer.frame = bounds
        layer.addSublayer(circleLayer)
        
        redraw()
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LongPressRecordButton.handleLongPress(_:)))
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.minimumPressDuration = 0.3
        self.addGestureRecognizer(longPressRecognizer)
        addTarget(self, action: #selector(LongPressRecordButton.handleShortPress(_:)), for: UIControlEvents.touchUpInside)
    }
    
    fileprivate func redraw() {
        ringLayer.lineWidth = ringWidth
        ringLayer.strokeColor = ringColor?.cgColor
        ringLayer.path = UIBezierPath(ovalIn: outerRect).cgPath
        ringLayer.setNeedsDisplay()
        
        circleLayer.fillColor = circleColor?.cgColor
        circleLayer.path = UIBezierPath(ovalIn: innerRect).cgPath
        circleLayer.setNeedsDisplay()
    }
    
    /// Sublayer layouting
    override open func layoutSubviews() {
        super.layoutSubviews()
        ringLayer.frame = bounds
        circleLayer.frame = bounds
        redraw()
    }
    
    @objc fileprivate func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == .began) {
            buttonPressed()
        } else if (recognizer.state == .ended) {
            buttonReleased()
        }
    }
    
    @objc fileprivate func handleShortPress(_ sender: AnyObject?) {
        if shouldShowTooltip {
            if isTooltipVisible() == false {
                if let delegate = delegate , delegate.longPressRecordButtonShouldShowToolTip?(self) == false {
                    return
                }
                let tooltip = ToolTip(title: toolTipText, foregroundColor: toolTipTextColor, backgroundColor: toolTipColor, font: toolTipFont, recordButton: self)
                tooltip.show()
                delegate?.longPressRecordButtonDidShowToolTip?(self)
            }
        }
        shouldShowTooltip = true
    }
    
    fileprivate func isTooltipVisible() -> Bool {
        return layer.sublayers?.filter({ $0.isKind(of: ToolTip.self) }).first != nil
    }
    
    fileprivate func buttonPressed() {
        if touchesStarted == nil {
            circleLayer.fillColor = circleColor?.darkerColor().cgColor
            setNeedsDisplay()
            touchesStarted = CACurrentMediaTime()
            touchesEnded = false
            shouldShowTooltip = false
            
            let delayTime = DispatchTime.now() + Double(Int64(Double(minPressDuration) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                if let strongSelf = self {
                    if strongSelf.touchesEnded { strongSelf.buttonReleased() }
                }
            }
            delegate?.longPressRecordButtonDidStartLongPress(self)
        }
    }
    
    fileprivate func buttonReleased() {
        if let touchesStarted = touchesStarted , (CACurrentMediaTime() - touchesStarted) >= Double(minPressDuration) {
            self.touchesStarted = nil
            circleLayer.fillColor = circleColor?.cgColor
            delegate?.longPressRecordButtonDidStopLongPress(self)
        } else {
            touchesEnded = true
        }
    }
    
    fileprivate func ringColorForState(_ state : UIControlState) -> UIColor? {
        switch state {
        case UIControlState(): return ringColor
        case UIControlState.highlighted: return ringColor
        case UIControlState.disabled: return ringColor?.withAlphaComponent(0.5)
        case UIControlState.selected: return ringColor
        default: return nil
        }
    }
    
    fileprivate func circleColorForState(_ state: UIControlState) -> UIColor? {
        switch state {
        case UIControlState(): return circleColor
        case UIControlState.highlighted: return circleColor?.darkerColor()
        case UIControlState.disabled: return circleColor?.withAlphaComponent(0.5)
        case UIControlState.selected: return circleColor?.darkerColor()
        default: return nil
        }
    }
    
    /// @IBDesignable support
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        backgroundColor = UIColor.clear
    }
}


//================================================
// MARK: Extensions
//================================================

private extension NSAttributedString {
    func sizeToFit(_ maxSize: CGSize) -> CGSize {
        return boundingRect(with: maxSize, options:(NSStringDrawingOptions.usesLineFragmentOrigin), context:nil).size
    }
}

private extension Int {
    var radians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

private extension UIColor {
    func darkerColor() -> UIColor {
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: max(r - 0.2, 0.0), green: max(g - 0.2, 0.0), blue: max(b - 0.2, 0.0), alpha: a)
        }
        return UIColor()
    }
}


//================================================
// MARK: ToolTip
//================================================

private class ToolTip : CAShapeLayer, CAAnimationDelegate {
    
    fileprivate weak var recordButton : LongPressRecordButton?
    fileprivate let defaultMargin : CGFloat = 5.0
    fileprivate let defaultArrowSize : CGFloat = 5.0
    fileprivate let defaultCornerRadius : CGFloat = 5.0
    fileprivate var textLayer : CATextLayer!
    
    init(title: String, foregroundColor: UIColor, backgroundColor: UIColor, font: UIFont, recordButton: LongPressRecordButton) {
        super.init()
        commonInit(title, foregroundColor: foregroundColor, backgroundColor: backgroundColor, font: font, recordButton: recordButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func commonInit(_ title: String, foregroundColor: UIColor, backgroundColor: UIColor, font: UIFont, recordButton: LongPressRecordButton) {
        self.recordButton = recordButton
        
        let rect = recordButton.bounds
        let text = NSAttributedString(string: title, attributes: [NSFontAttributeName : font, NSForegroundColorAttributeName : foregroundColor])
        
        // TextLayer
        textLayer = CATextLayer()
        textLayer.string = text
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.contentsScale = UIScreen.main.scale
        
        // ShapeLayer
        let screenSize = UIScreen.main.bounds.size
        let basePoint = CGPoint(x: rect.origin.x + (rect.size.width / 2), y: rect.origin.y - (defaultMargin * 2))
        let baseSize = text.sizeToFit(screenSize)
        
        let x       = basePoint.x - (baseSize.width / 2) - (defaultMargin * 2)
        let y       = basePoint.y - baseSize.height - (defaultMargin * 2) - defaultArrowSize
        let width   = baseSize.width + (defaultMargin * 4)
        let height  = baseSize.height + (defaultMargin * 2) + defaultArrowSize
        frame = CGRect(x: x, y: y, width: width, height: height)
        
        path = toolTipPath(bounds, arrowSize: defaultArrowSize, radius: defaultCornerRadius).cgPath
        fillColor = backgroundColor.cgColor
        addSublayer(textLayer)
    }
    
    fileprivate func toolTipPath(_ frame: CGRect, arrowSize: CGFloat, radius: CGFloat) -> UIBezierPath {
        let mid = frame.midX
        let width = frame.maxX
        let height = frame.maxY
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: mid, y: height))
        path.addLine(to: CGPoint(x: mid - arrowSize, y: height - arrowSize))
        path.addLine(to: CGPoint(x: radius, y: height - arrowSize))
        path.addArc(withCenter: CGPoint(x: radius, y: height - arrowSize - radius), radius: radius, startAngle: 90.radians, endAngle: 180.radians, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: 180.radians, endAngle: 270.radians, clockwise: true)
        path.addLine(to: CGPoint(x: width - radius, y: 0))
        path.addArc(withCenter: CGPoint(x: width - radius, y: radius), radius: radius, startAngle: 270.radians, endAngle: 0.radians, clockwise: true)
        path.addLine(to: CGPoint(x: width, y: height - arrowSize - radius))
        path.addArc(withCenter: CGPoint(x: width - radius, y: height - arrowSize - radius), radius: radius, startAngle: 0.radians, endAngle: 90.radians, clockwise: true)
        path.addLine(to: CGPoint(x: mid + arrowSize, y: height - arrowSize))
        path.addLine(to: CGPoint(x: mid, y: height))
        path.close()
        return path
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        textLayer.frame = CGRect(x: defaultMargin, y: defaultMargin, width: bounds.size.width-(defaultMargin*2), height: bounds.size.height-(defaultMargin*2))
    }
    
    fileprivate func animation(_ fromTransform: CATransform3D, toTransform: CATransform3D) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: "transform")
        animation.damping = 15
        animation.initialVelocity = 10
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        animation.fromValue = NSValue(caTransform3D: fromTransform)
        animation.toValue = NSValue(caTransform3D: toTransform)
        animation.duration = animation.settlingDuration
        animation.delegate = self
        animation.autoreverses = true
        return animation
    }
    
    func show() {
        recordButton?.layer.addSublayer(self)
        let show = animation(CATransform3DMakeScale(0, 0, 1), toTransform: CATransform3DIdentity)
        add(show, forKey: "show")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        removeFromSuperlayer()
    }
}
