//
//  UIViewPopAnimationTransitionType.swift
//  NavigationTransitionDemo
//
//  Created by xiabob on 17/2/10.
//  Copyright © 2017年 xiabob. All rights reserved.
//

import UIKit


//MARK: - UIViewPopAnimationTransitionType

public enum PopAnimationType {
    case system
    case scale
    case mask(CGRect?)
    case custom
}

public protocol UIViewPopAnimationTransitionType: NSObjectProtocol {
    func transitionDurationForPop(to viewController: UIViewController) -> TimeInterval
    func animationTypeForPop(to viewController: UIViewController) -> PopAnimationType
    func customAnimationForPop(to viewController: UIViewController,
                               using transitionContext: UIViewControllerContextTransitioning,
                               in popTransitioning: NavigationPopAnimationTransitioning)
    
}

extension UIViewPopAnimationTransitionType where Self: UIViewController {
    func transitionDurationForPop(to viewController: UIViewController) -> TimeInterval {return 0.25}
    func animationTypeForPop(to viewController: UIViewController) -> PopAnimationType {return .system}
    func customAnimationForPop(to viewController: UIViewController,
                               using transitionContext: UIViewControllerContextTransitioning,
                               in popTransitioning: NavigationPopAnimationTransitioning) {}
}


//MARK: - UIViewInteractivePopAnimationTransitionType

public enum InteractivePopAnimationType {
    case system
    case scale
    case custom
}

public protocol UIViewInteractivePopAnimationTransitionType: NSObjectProtocol {
    func useInteractiveAnimation() -> Bool
    func interactiveTransitionDurationForPop(to viewController: UIViewController) -> TimeInterval
    func interactiveAnimationTypeForPop(to viewController: UIViewController) -> InteractivePopAnimationType
    func customInteractiveAnimationForPop(to viewController: UIViewController,
                               using transitionContext: UIViewControllerContextTransitioning,
                               in popTransitioning: NavigationPopAnimationTransitioning)
    
}

extension UIViewInteractivePopAnimationTransitionType where Self: UIViewController {
    func useInteractiveAnimation() -> Bool {return true}
    func interactiveTransitionDurationForPop(to viewController: UIViewController) -> TimeInterval {return 0.25}
    func interactiveAnimationTypeForPop(to viewController: UIViewController) -> InteractivePopAnimationType {return .system}
    func customInteractiveAnimationForPop(to viewController: UIViewController,
                                          using transitionContext: UIViewControllerContextTransitioning,
                                          in popTransitioning: NavigationPopAnimationTransitioning) {}
}


//MARK: - NavigationPopAnimationTransitioning

open class NavigationPopAnimationTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    fileprivate var isInteractiveAnimation = false
    
    init(isInteractiveAnimation: Bool = false) {
        super.init()
        self.isInteractiveAnimation = isInteractiveAnimation
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { //并非动画实际执行的时间，animateTransition的时间是以自己设置的为准的，但是我们一般设置为transitionDuration
        if isInteractiveAnimation {
            guard let fromVC = transitionContext?.viewController(forKey: .from) as? UIViewPopAnimationTransitionType else {return 0.25}
            guard let toVC = transitionContext?.viewController(forKey: .to) else {return 0.25}
            return fromVC.transitionDurationForPop(to: toVC)
        } else {
            guard let fromVC = transitionContext?.viewController(forKey: .from) as? UIViewInteractivePopAnimationTransitionType else {return 0.25}
            guard let toVC = transitionContext?.viewController(forKey: .to) else {return 0.25}
            return fromVC.interactiveTransitionDurationForPop(to: toVC)
        }
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isInteractiveAnimation {
            interactiveAnimateTransition(using: transitionContext)
        } else {
            defaultAnimateTransition(using: transitionContext)
        }
        
    }
    
    fileprivate func defaultAnimateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? UIViewPopAnimationTransitionType else {return}
        guard let toVC = transitionContext.viewController(forKey: .to) else {return}
        let type = fromVC.animationTypeForPop(to: toVC)
        switch type {
        case .scale:
            return scaleAnimateTransition(using: transitionContext)
        case .mask(let rect):
            return maskAnimateTransition(using: transitionContext, in: rect)
        case .custom:
            return fromVC.customAnimationForPop(to: toVC, using: transitionContext, in: self)
        case .system:
            return systemAnimateTransition(using: transitionContext)
        }
    }
    
    fileprivate func interactiveAnimateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? UIViewInteractivePopAnimationTransitionType else {return}
        guard let toVC = transitionContext.viewController(forKey: .to) else {return}
        let type = fromVC.interactiveAnimationTypeForPop(to: toVC)
        switch type {
        case .scale:
            return scaleAnimateTransition(using: transitionContext)
        case .custom:
            return fromVC.customInteractiveAnimationForPop(to: toVC, using: transitionContext, in: self)
        case .system:
            return systemAnimateTransition(using: transitionContext)
        }
    }
    
    //MARK: - 具体的动画
    public func systemAnimateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
        let containerView = transitionContext.containerView;
        containerView.addSubview(toViewController.view)
        containerView.addSubview(fromViewController.view)

        toViewController.view.frame.origin = CGPoint(x: -fromViewController.view.frame.width, y: 0)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.frame.origin = CGPoint.zero
            fromViewController.view.frame.origin = CGPoint(x: fromViewController.view.frame.width, y: 0)
        }) { (finished) in
            //transitionWasCancelled判断转场动画是否执行完成，当调用cancelInteractiveTransition()时，取消了操作，通常是交互式动画中会使用
            if transitionContext.transitionWasCancelled {
                fromViewController.view.frame.origin = CGPoint.zero
            } else {
                toViewController.view.frame.origin = CGPoint.zero
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    public func scaleAnimateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
        let containerView = transitionContext.containerView;
        containerView.addSubview(toViewController.view)
        containerView.addSubview(fromViewController.view)
        
        toViewController.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        fromViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            fromViewController.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { (finished) in
            if transitionContext.transitionWasCancelled {
                fromViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
                toViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            } else {
                toViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    public func maskAnimateTransition(using transitionContext: UIViewControllerContextTransitioning, in rect: CGRect? = nil) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
        let containerView = transitionContext.containerView;
        let fromFrame = transitionContext.finalFrame(for: fromViewController)
        
        containerView.addSubview(toViewController.view)
        containerView.addSubview(fromViewController.view)
        
        //两个圆
        let centerRect = rect ?? CGRect(origin: toViewController.view.center, size: CGSize(width: 10, height: 10))
        let arcCenter = CGPoint(x: centerRect.midX, y: centerRect.midY)
        let viewCenter = toViewController.view.center
        var minRadius: CGFloat = 0
        var maxRadius: CGFloat = 0
        if arcCenter.x <= viewCenter.x && arcCenter.y <= viewCenter.y { //第1象限
            minRadius = sqrt(arcCenter.x * arcCenter.x + arcCenter.y * arcCenter.y)
            maxRadius = sqrt((fromFrame.size.width-arcCenter.x)*(fromFrame.size.width-arcCenter.x) + (fromFrame.size.height-arcCenter.y)*(fromFrame.size.height-arcCenter.y))
        } else if arcCenter.x > viewCenter.x && arcCenter.y < viewCenter.y { //第2象限
            minRadius = sqrt((fromFrame.size.width-arcCenter.x)*(fromFrame.size.width-arcCenter.x) + arcCenter.y * arcCenter.y)
            maxRadius = sqrt(arcCenter.x * arcCenter.x + (fromFrame.size.height-arcCenter.y)*(fromFrame.size.height-arcCenter.y))
        } else if arcCenter.x < viewCenter.x && arcCenter.y > viewCenter.y { //第3象限
            minRadius = sqrt(arcCenter.x * arcCenter.x + (fromFrame.size.height-arcCenter.y)*(fromFrame.size.height-arcCenter.y))
            maxRadius = sqrt((fromFrame.size.width-arcCenter.x)*(fromFrame.size.width-arcCenter.x) + arcCenter.y * arcCenter.y)
        } else if arcCenter.x > viewCenter.x && arcCenter.y > viewCenter.y { //第4象限
            minRadius = sqrt(arcCenter.x * arcCenter.x + (fromFrame.size.height-arcCenter.y)*(fromFrame.size.height-arcCenter.y))
            maxRadius = sqrt(arcCenter.x * arcCenter.x + arcCenter.y * arcCenter.y)
        }
        minRadius = min(minRadius, centerRect.size.width/2, centerRect.size.height/2)
        
        let startPath = UIBezierPath(arcCenter: arcCenter, radius: maxRadius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        let endPath = UIBezierPath(arcCenter: arcCenter, radius: minRadius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        
        //设置图层遮罩，显示为遮罩的样子
        let maskLayer = CAShapeLayer()
        fromViewController.view.layer.mask = maskLayer
        
        let maskAnimation = CABasicAnimation(keyPath: "path")
        maskAnimation.fromValue = startPath.cgPath
        maskAnimation.toValue = endPath.cgPath
        maskAnimation.duration = transitionDuration(using: transitionContext)
        maskLayer.add(maskAnimation, forKey: "path")
        //动画改变的只是presentation图层，动画结束最终还是会显示model图层的结果，你需要手动设置model图层的值
        maskLayer.path = endPath.cgPath
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+transitionDuration(using: transitionContext)) {
            maskLayer.path = startPath.cgPath
            transitionContext.completeTransition(true)
        }
    }
}
