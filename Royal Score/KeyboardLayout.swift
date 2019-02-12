//
//  KeyboardLayout.swift
//  Codea
//
//  Created by Simeon on 24/7/17.
//  Copyright © 2017 Two Lives Left. All rights reserved.
//

import UIKit

@objc public class KeyboardLayout: NSObject {
    private let viewForKeyboardIntersection: () -> UIView
    private let layoutForKeyboardFrameChange: (CGFloat, TimeInterval) -> ()
    private var tokens: [NSObjectProtocol] = []
    
    private static var lastEndFrame: CGRect?
    
    @objc public var keyboardHeight: CGFloat = 0.0
    @objc public var keyboardShowing: Bool = false
    
    @objc public var didShow: ()->() = {}
    @objc public var didHide: ()->() = {}

    @objc public var performLayoutOnWillShow: Bool = false
    @objc public var performLayoutOnWillHide: Bool = false
    
    @objc public var performLayoutOnDidShow: Bool = false
    @objc public var performLayoutOnDidHide: Bool = false
    
    @objc public init(viewForKeyboardIntersection: @escaping () -> UIView, layoutForKeyboardFrameChange: @escaping (CGFloat, TimeInterval) -> ()) {
        self.viewForKeyboardIntersection = viewForKeyboardIntersection
        self.layoutForKeyboardFrameChange = layoutForKeyboardFrameChange
        
        super.init()
        
        observeKeyboardNotifications()
    }
    
    deinit {
        removeKeyboardObservers()
    }
    
    @objc public func recomputeLayout() {
        if let frame = KeyboardLayout.lastEndFrame {
            let height = keyboardHeight(fromEndFrame: frame)
            layoutForKeyboardFrameChange(height, 0.0)
        }
    }
    
    private func observeKeyboardNotifications() {
        let computeHeightAndTriggerLayout: (Notification) -> () = {
            [weak self] notification in
            
            if let height = self?.keyboardHeight(fromNotification: notification) {
                let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.0 as TimeInterval
                
                self?.keyboardHeight = height                
                self?.layoutForKeyboardFrameChange(height, duration)
            }
        }
        
        removeKeyboardObservers()
        
        tokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) {
            [weak self] notification in
            
            self?.keyboardShowing = true
            
            if let layout = self?.performLayoutOnWillShow, layout == true {
                computeHeightAndTriggerLayout(notification)
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: OperationQueue.main) {
            [weak self] notification in
            
            if let layout = self?.performLayoutOnDidShow, layout == true {
                computeHeightAndTriggerLayout(notification)
            }
            
            self?.didShow()
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) {
            [weak self] notification in
            
            if let layout = self?.performLayoutOnWillHide, layout == true {
                computeHeightAndTriggerLayout(notification)
            }
            
            self?.keyboardShowing = false
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: OperationQueue.main) {
            [weak self] notification in

            if let layout = self?.performLayoutOnDidHide, layout == true {
                computeHeightAndTriggerLayout(notification)
            }
            
            self?.didHide()
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: OperationQueue.main) {
            notification in
            
            computeHeightAndTriggerLayout(notification)
        })
    }
    
    private func removeKeyboardObservers() {
        tokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        
        tokens.removeAll()
    }
    
    private func keyboardHeight(fromNotification notification: Notification) -> CGFloat {
        if let info = notification.userInfo,
            let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            
            KeyboardLayout.lastEndFrame = frame
            return keyboardHeight(fromEndFrame: frame)
        }
        
        return 0
    }
    
    private func keyboardHeight(fromEndFrame frame: CGRect) -> CGFloat {
        let view = viewForKeyboardIntersection()
        
        let convertedFrame = view.convert(view.bounds, to: UIScreen.main.coordinateSpace)
        
        let intersection = frame.intersection(convertedFrame)
        
        return intersection.size.height
    }
}
