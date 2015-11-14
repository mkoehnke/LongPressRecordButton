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
    func longPressRecordButtonDidStartLongPress(button : LongPressRecordButton)
    /// Tells the delegate that a long press has finished.
    func longPressRecordButtonDidStopLongPress(button: LongPressRecordButton)
    /// Tells the delegate that a tool tip should be presented when a short press occured.
    optional func longPressRecordButtonShouldShowToolTip(button : LongPressRecordButton) -> Bool
    /// Tells the delegate that a short press has occured and therefore a tooltip is shown.
    optional func longPressRecordButtonDidShowToolTip(button : LongPressRecordButton)
}

//================================================
// MARK: RecordButton
//================================================

/// The LongPressRecordButton class.
@IBDesignable public class LongPressRecordButton : UIControl {
    
    /// The delegate of the LongPressRecordButton instance.
    public weak var delegate : LongPressRecordButtonDelegate?
    
    /// The minmal duration, that the record button is supposed
    /// to stay in the 'selected' state, once the long press has
    /// started.
    @IBInspectable public var minPressDuration : Float = 1.0
    
    /// The width of the outer ring of the record button.
    @IBInspectable public var ringWidth : CGFloat = 4.0 {
        didSet { redraw() }
    }
    
    /// The color of the outer ring of the record button.
    @IBInspectable public var ringColor : UIColor? = UIColor.whiteColor() {
        didSet { redraw() }
    }
    
    /// The margin between the outer ring and inner circle
    /// of the record button.
    @IBInspectable public var circleMargin : CGFloat = 0.0 {
        didSet { redraw() }
    }
    
    /// The color of the inner circle of the record button.
    @IBInspectable public var circleColor : UIColor? = UIColor.redColor() {
        didSet { redraw() }
    }
    
    /// The text that the tooltip is supposed to display,
    /// if the user did short-press the button.
    public lazy var toolTipText : String = {
        return "Tap and Hold"
    }()
    
    /// The font of the tooltip text.
    public var toolTipFont : UIFont = {
        return UIFont.systemFontOfSize(12.0)
    }()
    
    /// The background color of the tooltip.
    public var toolTipColor : UIColor = {
        return UIColor.whiteColor()
    }()
    
    /// The text color of the tooltip.
    public var toolTipTextColor : UIColor = {
        return UIColor(white: 0.0, alpha: 0.8)
    }()
    
    /// Determines if the record button is enabled.
    override public var enabled: Bool {
        didSet {
            let state : UIControlState = enabled ? .Normal : .Disabled
            circleLayer.fillColor = circleColorForState(state)?.CGColor
            ringLayer.strokeColor = ringColorForState(state)?.CGColor
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
    
    private var longPressRecognizer : UILongPressGestureRecognizer!
    private var touchesStarted : CFTimeInterval?
    private var touchesEnded : Bool = false
    private var shouldShowTooltip : Bool = true
    
    private var ringLayer : CAShapeLayer!
    private var circleLayer : CAShapeLayer!
    
    private var outerRect : CGRect {
        return CGRectMake(ringWidth/2, ringWidth/2, bounds.size.width-ringWidth, bounds.size.height-ringWidth)
    }
    
    private var innerRect : CGRect {
        let innerX = outerRect.origin.x + (ringWidth/2) + circleMargin
        let innerY = outerRect.origin.y + (ringWidth/2) + circleMargin
        let innerWidth = outerRect.size.width - ringWidth - (circleMargin * 2)
        let innerHeight = outerRect.size.height - ringWidth - (circleMargin * 2)
        return CGRectMake(innerX, innerY, innerWidth, innerHeight)
    }
    
    private func commonInit() {
        backgroundColor = UIColor.clearColor()
        
        ringLayer = CAShapeLayer()
        ringLayer.fillColor = UIColor.clearColor().CGColor
        ringLayer.frame = bounds
        layer.addSublayer(ringLayer)
        
        circleLayer = CAShapeLayer()
        circleLayer.frame = bounds
        layer.addSublayer(circleLayer)
        
        redraw()
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.minimumPressDuration = 0.3
        self.addGestureRecognizer(longPressRecognizer)
        addTarget(self, action: Selector("handleShortPress:"), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func redraw() {
        ringLayer.lineWidth = ringWidth
        ringLayer.strokeColor = ringColor?.CGColor
        ringLayer.path = UIBezierPath(ovalInRect: outerRect).CGPath
        ringLayer.setNeedsDisplay()
        
        circleLayer.fillColor = circleColor?.CGColor
        circleLayer.path = UIBezierPath(ovalInRect: innerRect).CGPath
        circleLayer.setNeedsDisplay()
    }
    
    /// Sublayer layouting
    override public func layoutSubviews() {
        super.layoutSubviews()
        ringLayer.frame = bounds
        circleLayer.frame = bounds
    }
    
    @objc private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        if (recognizer.state == .Began) {
            buttonPressed()
        } else if (recognizer.state == .Ended) {
            buttonReleased()
        }
    }
    
    @objc private func handleShortPress(sender: AnyObject?) {
        if shouldShowTooltip {
            if isTooltipVisible() == false && delegate?.longPressRecordButtonShouldShowToolTip?(self) == true {
                let tooltip = ToolTip(title: toolTipText, foregroundColor: toolTipTextColor, backgroundColor: toolTipColor, font: toolTipFont, recordButton: self)
                tooltip.show()
                delegate?.longPressRecordButtonDidShowToolTip?(self)
            }
        }
        shouldShowTooltip = true
    }
    
    private func isTooltipVisible() -> Bool {
        return layer.sublayers?.filter { $0.isKindOfClass(ToolTip.self) }.count > 0
    }
    
    private func buttonPressed() {
        if touchesStarted == nil {
            circleLayer.fillColor = circleColor?.darkerColor().CGColor
            setNeedsDisplay()
            touchesStarted = CACurrentMediaTime()
            touchesEnded = false
            shouldShowTooltip = false
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(minPressDuration) * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] in
                if let strongSelf = self {
                    if strongSelf.touchesEnded { strongSelf.buttonReleased() }
                }
            }
            delegate?.longPressRecordButtonDidStartLongPress(self)
        }
    }
    
    private func buttonReleased() {
        if let touchesStarted = touchesStarted where (CACurrentMediaTime() - touchesStarted) >= Double(minPressDuration) {
            self.touchesStarted = nil
            circleLayer.fillColor = circleColor?.CGColor
            delegate?.longPressRecordButtonDidStopLongPress(self)
        } else {
            touchesEnded = true
        }
    }
    
    private func ringColorForState(state : UIControlState) -> UIColor? {
        switch state {
        case UIControlState.Normal: return ringColor
        case UIControlState.Highlighted: return ringColor
        case UIControlState.Disabled: return ringColor?.colorWithAlphaComponent(0.5)
        case UIControlState.Selected: return ringColor
        default: return nil
        }
    }
    
    private func circleColorForState(state: UIControlState) -> UIColor? {
        switch state {
        case UIControlState.Normal: return circleColor
        case UIControlState.Highlighted: return circleColor?.darkerColor()
        case UIControlState.Disabled: return circleColor?.colorWithAlphaComponent(0.5)
        case UIControlState.Selected: return circleColor?.darkerColor()
        default: return nil
        }
    }
    
    /// @IBDesignable support
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        backgroundColor = UIColor.clearColor()
    }
}


//================================================
// MARK: Extensions
//================================================

private extension NSAttributedString {
    private func sizeToFit(maxSize: CGSize) -> CGSize {
        return boundingRectWithSize(maxSize, options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
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

private class ToolTip : CAShapeLayer {
    
    private weak var recordButton : LongPressRecordButton?
    private let defaultMargin : CGFloat = 5.0
    private let defaultArrowSize : CGFloat = 5.0
    private let defaultCornerRadius : CGFloat = 5.0
    private var textLayer : CATextLayer!
    
    init(title: String, foregroundColor: UIColor, backgroundColor: UIColor, font: UIFont, recordButton: LongPressRecordButton) {
        super.init()
        commonInit(title, foregroundColor: foregroundColor, backgroundColor: backgroundColor, font: font, recordButton: recordButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func commonInit(title: String, foregroundColor: UIColor, backgroundColor: UIColor, font: UIFont, recordButton: LongPressRecordButton) {
        self.recordButton = recordButton
        
        let rect = recordButton.bounds
        let text = NSAttributedString(string: title, attributes: [NSFontAttributeName : font, NSForegroundColorAttributeName : foregroundColor])
        
        // TextLayer
        textLayer = CATextLayer()
        textLayer.string = text
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.contentsScale = UIScreen.mainScreen().scale
        
        // ShapeLayer
        let screenSize = UIScreen.mainScreen().bounds.size
        let basePoint = CGPointMake(rect.origin.x + (rect.size.width / 2), rect.origin.y - (defaultMargin * 2))
        let baseSize = text.sizeToFit(screenSize)
        
        let x       = basePoint.x - (baseSize.width / 2) - (defaultMargin * 2)
        let y       = basePoint.y - baseSize.height - (defaultMargin * 2) - defaultArrowSize
        let width   = baseSize.width + (defaultMargin * 4)
        let height  = baseSize.height + (defaultMargin * 2) + defaultArrowSize
        frame = CGRectMake(x, y, width, height)
        
        path = toolTipPath(bounds, arrowSize: defaultArrowSize, radius: defaultCornerRadius).CGPath
        fillColor = backgroundColor.CGColor
        addSublayer(textLayer)
    }
    
    private func toolTipPath(frame: CGRect, arrowSize: CGFloat, radius: CGFloat) -> UIBezierPath {
        let mid = CGRectGetMidX(frame)
        let width = CGRectGetMaxX(frame)
        let height = CGRectGetMaxY(frame)
        
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(mid, height))
        path.addLineToPoint(CGPointMake(mid - arrowSize, height - arrowSize))
        path.addLineToPoint(CGPointMake(radius, height - arrowSize))
        path.addArcWithCenter(CGPointMake(radius, height - arrowSize - radius), radius: radius, startAngle: 90.radians, endAngle: 180.radians, clockwise: true)
        path.addLineToPoint(CGPointMake(0, radius))
        path.addArcWithCenter(CGPointMake(radius, radius), radius: radius, startAngle: 180.radians, endAngle: 270.radians, clockwise: true)
        path.addLineToPoint(CGPointMake(width - radius, 0))
        path.addArcWithCenter(CGPointMake(width - radius, radius), radius: radius, startAngle: 270.radians, endAngle: 0.radians, clockwise: true)
        path.addLineToPoint(CGPointMake(width, height - arrowSize - radius))
        path.addArcWithCenter(CGPointMake(width - radius, height - arrowSize - radius), radius: radius, startAngle: 0.radians, endAngle: 90.radians, clockwise: true)
        path.addLineToPoint(CGPointMake(mid + arrowSize, height - arrowSize))
        path.addLineToPoint(CGPointMake(mid, height))
        path.closePath()
        return path
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        textLayer.frame = CGRectMake(defaultMargin, defaultMargin, bounds.size.width-(defaultMargin*2), bounds.size.height-(defaultMargin*2))
    }
    
    private func animation(fromTransform: CATransform3D, toTransform: CATransform3D) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: "transform")
        animation.damping = 15
        animation.initialVelocity = 10
        animation.fillMode = kCAFillModeForwards
        animation.removedOnCompletion = false
        animation.fromValue = NSValue(CATransform3D: fromTransform)
        animation.toValue = NSValue(CATransform3D: toTransform)
        animation.duration = animation.settlingDuration
        animation.delegate = self
        animation.autoreverses = true
        return animation
    }
    
    func show() {
        recordButton?.layer.addSublayer(self)
        let show = animation(CATransform3DMakeScale(0, 0, 1), toTransform: CATransform3DIdentity)
        addAnimation(show, forKey: "show")
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        removeFromSuperlayer()
    }
}
