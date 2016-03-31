//
// ViewController.swift
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

class ViewController: UIViewController, LongPressRecordButtonDelegate {

    @IBOutlet weak var recordButton : LongPressRecordButton?
    @IBOutlet weak var progressView : UIProgressView?
    
    let duration : Double = 5.0
    var progress : Double = 0.0
    var startTime : CFTimeInterval?
    
    lazy var displayLink : CADisplayLink? = {
        var instance = CADisplayLink(target: self, selector: #selector(ViewController.animateProgress(_:)))
        instance.paused = true
        instance.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        return instance
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recordButton?.delegate = self
        setupDisplayLink()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // MARK: LongPressRecordButton Delegate
    
    func longPressRecordButtonDidStartLongPress(button: LongPressRecordButton) {
        startTime = CACurrentMediaTime();
        displayLink?.paused = false
    }
    
    func longPressRecordButtonDidStopLongPress(button: LongPressRecordButton) {
        displayLink?.paused = true
    }
    
    // MARK: DisplayLink

    private func setupDisplayLink() {
        progress = 0.0
        startTime = CACurrentMediaTime();
        displayLink?.paused = true
        progressView?.progress = Float(progress)
    }
    
    @objc private func animateProgress(displayLink : CADisplayLink) {
        if (progress > duration) {
            setupDisplayLink()
            return
        }
        
        if let startTime = startTime {
            let elapsedTime = CACurrentMediaTime() - startTime
            self.progress += elapsedTime
            self.startTime = CACurrentMediaTime()
            self.progressView?.progress = Float(self.progress / self.duration)
        }
    }
}

