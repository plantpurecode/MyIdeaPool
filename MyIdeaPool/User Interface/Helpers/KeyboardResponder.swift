//
//  KeyboardResponder.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 20/10/2019.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

class KeyboardResponder: ObservableObject {
    private var _center: NotificationCenter
    
    @Published var currentHeight: CGFloat = 0
    @Published var isActive = false
    
    var keyboardDuration: TimeInterval = 0

    init(center: NotificationCenter = .default) {
        _center = center
        _center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        _center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        _center.removeObserver(self)
    }

    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            withAnimation(animation(from: notification, outDuration: &keyboardDuration)) {
                currentHeight = keyboardSize.height
                isActive = true
            }

        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        withAnimation(animation(from: notification)) {
            currentHeight = 0
            isActive = false
        }
    }
    
    private func animation(from notification: Notification) -> Animation {
        var duration: TimeInterval = 0
        return animation(from: notification, outDuration: &duration)
    }
    
    private func animation(from notification: Notification, outDuration: inout TimeInterval) -> Animation {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return .linear
        }
        
        outDuration = duration
        
        guard let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UIView.AnimationCurve else {
            return .easeOut(duration: duration)
        }
        
        switch curve {
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .linear:
            return .linear
        @unknown default:
            return .linear
        }
    }
}
