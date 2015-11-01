//
//  LongPressButton.swift
//  LongPressButton
//
//  Created by apploft. GmbH on 27/10/15.
//  Copyright © 2015 apploft. GmbH. All rights reserved.
//

import UIKit

// MARK: Extensions

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

// MARK: ToolTip

private class ToolTip : CAShapeLayer {
    
    private let defaultMargin : CGFloat = 5.0
    private let defaultArrowSize : CGFloat = 5.0
    private let defaultCornerRadius : CGFloat = 5.0
    private var textLayer : CATextLayer!
    
    init(title: String, foregroundColor: UIColor, backgroundColor: UIColor, font: UIFont, rect: CGRect) {
        super.init()
        commonInit(title, foregroundColor: foregroundColor, backgroundColor: backgroundColor, font: font, rect: rect)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func commonInit(title: String, foregroundColor: UIColor, backgroundColor: UIColor, font: UIFont, rect: CGRect) {
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
    
    func toolTipPath(frame: CGRect, arrowSize: CGFloat, radius: CGFloat) -> UIBezierPath {
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
    
    func animation(fromTransform: CATransform3D, toTransform: CATransform3D) -> CASpringAnimation {
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
    
    func show(view: UIView?) {
        view?.layer.addSublayer(self)
        let show = animation(CATransform3DMakeScale(0, 0, 1), toTransform: CATransform3DIdentity)
        addAnimation(show, forKey: "show")
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        removeFromSuperlayer()
    }
}

// MARK: RecordButton

class LongPressRecordButton : UIControl {
    
    var minPressDuration : Double = 1.0
    
    var ringWidth : CGFloat = 4.0
    var ringColor = UIColor.whiteColor()
    
    var circleMargin : CGFloat = 0.0;
    var circleColor = UIColor.redColor()
    
    var toolTipText : String = "Tap and Hold"
    var toolTipFont : UIFont = UIFont.systemFontOfSize(12.0)
    var toolTipColor : UIColor = UIColor.whiteColor()
    var toolTipTextColor : UIColor = UIColor(white: 0.0, alpha: 0.8)
    
    // MARK: Private
    
    private var longPressRecognizer : UILongPressGestureRecognizer!
    private var touchesStarted : CFTimeInterval?
    private var touchesEnded : Bool = false
    private var shouldShowTooltip : Bool = true
    
    private var ringLayer : CAShapeLayer!
    private var circleLayer : CAShapeLayer!
    
    private var tooltip : ToolTip?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clearColor()
        
        let outerRect = CGRectMake(ringWidth/2, ringWidth/2, bounds.size.width-ringWidth, bounds.size.height-ringWidth)
        ringLayer = CAShapeLayer()
        ringLayer.fillColor = UIColor.clearColor().CGColor
        ringLayer.lineWidth = ringWidth
        ringLayer.path = UIBezierPath(ovalInRect: outerRect).CGPath
        ringLayer.strokeColor = ringColor.CGColor
        ringLayer.frame = bounds
        layer.addSublayer(ringLayer)
        
        circleLayer = CAShapeLayer()
        circleLayer.fillColor = circleColor.CGColor
        let innerX = outerRect.origin.x + (ringWidth/2) + circleMargin
        let innerY = outerRect.origin.y + (ringWidth/2) + circleMargin
        let innerWidth = outerRect.size.width - ringWidth - (circleMargin * 2)
        let innerHeight = outerRect.size.height - ringWidth - (circleMargin * 2)
        circleLayer.path = UIBezierPath(ovalInRect: CGRectMake(innerX, innerY, innerWidth, innerHeight)).CGPath
        layer.addSublayer(circleLayer)
        
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.minimumPressDuration = 0.3
        self.addGestureRecognizer(longPressRecognizer)
        addTarget(self, action: Selector("handleShortPress:"), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ringLayer.frame = bounds
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
            print("Short")
            tooltip = ToolTip(title: toolTipText, foregroundColor: toolTipTextColor, backgroundColor: toolTipColor, font: toolTipFont, rect: frame)
            tooltip!.show(superview)
        }
        shouldShowTooltip = true
    }
    
    private func buttonPressed() {
        if touchesStarted == nil {
            circleLayer.fillColor = circleColor.darkerColor().CGColor
            setNeedsDisplay()
            touchesStarted = CACurrentMediaTime()
            touchesEnded = false
            shouldShowTooltip = false
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(minPressDuration * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] in
                if let strongSelf = self {
                    if strongSelf.touchesEnded { strongSelf.buttonReleased() }
                }
            }
            print("Press")
        }
    }
    
    private func buttonReleased() {
        if let touchesStarted = touchesStarted where (CACurrentMediaTime() - touchesStarted) >= minPressDuration {
            self.touchesStarted = nil
            enabled = true
            circleLayer.fillColor = circleColor.CGColor
            print("Release")
        } else {
            touchesEnded = true
            enabled = false
        }
    }
    
    override var enabled: Bool {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func ringColorForState(state : UIControlState) -> UIColor? {
        return colorForState(ringColor, state: state)
    }
    
    func circleColorForState(state: UIControlState) -> UIColor? {
        return colorForState(circleColor, state: state)
    }
    
    func colorForState(color: UIColor, state : UIControlState) -> UIColor? {
        switch state {
        case UIControlState.Normal: return color
        case UIControlState.Highlighted: return color.colorWithAlphaComponent(0.5)
        case UIControlState.Disabled: return color.colorWithAlphaComponent(0.5)
        case UIControlState.Selected: return color.colorWithAlphaComponent(0.5)
        default: return nil
        }
    }
}
