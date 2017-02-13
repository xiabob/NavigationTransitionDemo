//
//  NavigationControllerDelegate.swift
//  NavigationTransitionDemo
//
//  Created by xiabob on 17/2/9.
//  Copyright © 2017年 xiabob. All rights reserved.
//

import UIKit

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    fileprivate var interactiveTransition: UIPercentDrivenInteractiveTransition?
    fileprivate var isInteractiveAnimation = false
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .push {
            if let type = toVC as? UIViewPushAnimationTransitionType {
                switch type.animationTypeForPush(from: fromVC) {
                case .system:
                    return nil
                default:
                    return NavigationPushAnimationTransitioning()
                }
            }
        }
        
        if operation == .pop {
            if isInteractiveAnimation {
                return NavigationPopAnimationTransitioning(isInteractiveAnimation: true)
            } else {
                if let type = fromVC as? UIViewPopAnimationTransitionType {
                    switch type.animationTypeForPop(to: toVC) {
                    case .system:
                        return nil
                    default:
                        return NavigationPopAnimationTransitioning()
                    }
                }
            }
            
        }
        
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
}

extension UINavigationController {
    private struct AssociatedKeys {
        static var animationDelegateKey = "xb_animationDelegateKey"
    }
    

    private var animationDelegate: NavigationControllerDelegate {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.animationDelegateKey) as? NavigationControllerDelegate ?? NavigationControllerDelegate()
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.animationDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    ///设置相应代理
    func initAnimationDelegate() {
        animationDelegate = NavigationControllerDelegate()
        delegate = animationDelegate
    }
    
    ///用于在对应的视图里添加pan手势
    func attach(to viewController: UIViewController) {
        guard let type = viewController as? UIViewInteractivePopAnimationTransitionType else {return}
        if type.useInteractiveAnimation() {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gestureRecognizer:)))
            viewController.view.addGestureRecognizer(pan)
        }
    }
    
    @objc private func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let viewTranslation = gestureRecognizer.translation(in: view)
        let viewLocation = gestureRecognizer.location(in: view)
        let d = fabs(viewTranslation.x / view.bounds.width)
        let limit: CGFloat = 80 / view.bounds.width
        if gestureRecognizer.state == .began {
            if viewLocation.x <= 80 && viewControllers.count > 1 {
                animationDelegate.interactiveTransition = UIPercentDrivenInteractiveTransition()
                animationDelegate.isInteractiveAnimation = true
                popViewController(animated: true)
            }
        } else if gestureRecognizer.state == .changed {
            animationDelegate.interactiveTransition?.update(d)
        } else if gestureRecognizer.state == .ended {
            if d >= limit {
                animationDelegate.interactiveTransition?.finish()
            } else {
                animationDelegate.interactiveTransition?.cancel()
            }
            
            animationDelegate.interactiveTransition = nil
            animationDelegate.isInteractiveAnimation = false
        } else {
            animationDelegate.interactiveTransition?.cancel()
            animationDelegate.interactiveTransition = nil
            animationDelegate.isInteractiveAnimation = false
        }
    }
}
