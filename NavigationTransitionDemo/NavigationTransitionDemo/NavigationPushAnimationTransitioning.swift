//
//  NavigationAnimation.swift
//  NavigationTransitionDemo
//
//  Created by xiabob on 17/2/9.
//  Copyright © 2017年 xiabob. All rights reserved.
//

import UIKit

public enum PushAnimationType {
    case system
    case scale
    case mask(CGRect?)
    case custom
}

public protocol UIViewPushAnimationTransitionType: NSObjectProtocol {
    func transitionDurationForPush(from viewController: UIViewController) -> TimeInterval
    func animationTypeForPush(from viewController: UIViewController) -> PushAnimationType
    func customAnimationForPush(from viewController: UIViewController, using transitionContext: UIViewControllerContextTransitioning)
}

extension UIViewPushAnimationTransitionType where Self: UIViewController {
    func transitionDurationForPush(from viewController: UIViewController) -> TimeInterval {return 0.25}
    func animationTypeForPush(from viewController: UIViewController) -> PushAnimationType {return .system}
    func customAnimationForPush(from viewController: UIViewController, using transitionContext: UIViewControllerContextTransitioning) {}
}

class NavigationPushAnimationTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let toViewController = transitionContext?.viewController(forKey: .to) as? UIViewPushAnimationTransitionType else {return 0.25}
        guard let fromViewController = transitionContext?.viewController(forKey: .from) else {return 0.25}
        return toViewController.transitionDurationForPush(from: fromViewController)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) as? UIViewPushAnimationTransitionType else {return}
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
        switch toViewController.animationTypeForPush(from: fromViewController) {
        case .scale:
            return scaleAnimateTransition(using: transitionContext)
        case .mask(let rect):
            return maskAnimateTransition(using: transitionContext,
                                         in: rect)
        case .custom:
            return toViewController.customAnimationForPush(from: fromViewController,
                                                           using: transitionContext)
        case .system: //不做处理，因为是系统默认的push动画方式，不是自定义行为，上层处理
            return
        }
        
    }
    
    //MARK: - 具体的动画
    fileprivate func scaleAnimateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
        let containerView = transitionContext.containerView;
        containerView.addSubview(toViewController.view)
        
        toViewController.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        fromViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            fromViewController.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { (finished) in
            fromViewController.view.transform = CGAffineTransform.identity
            transitionContext.completeTransition(true)
        }
    }
    
    fileprivate func maskAnimateTransition(using transitionContext: UIViewControllerContextTransitioning, in rect: CGRect? = nil) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else {return}
        guard let fromViewController = transitionContext.viewController(forKey: .from) else {return}
        let containerView = transitionContext.containerView;
        let toFrame = transitionContext.finalFrame(for: toViewController)
        
        containerView.addSubview(fromViewController.view)
        containerView.addSubview(toViewController.view)
        
        //两个圆
        let centerRect = rect ?? CGRect(origin: toViewController.view.center, size: CGSize(width: 10, height: 10))
        let arcCenter = CGPoint(x: centerRect.midX, y: centerRect.midY)
        let viewCenter = toViewController.view.center
        var minRadius: CGFloat = 0
        var maxRadius: CGFloat = 0
        if arcCenter.x <= viewCenter.x && arcCenter.y <= viewCenter.y { //第1象限
            minRadius = sqrt(arcCenter.x * arcCenter.x + arcCenter.y * arcCenter.y)
            maxRadius = sqrt((toFrame.size.width-arcCenter.x)*(toFrame.size.width-arcCenter.x) + (toFrame.size.height-arcCenter.y)*(toFrame.size.height-arcCenter.y))
        } else if arcCenter.x > viewCenter.x && arcCenter.y < viewCenter.y { //第2象限
            minRadius = sqrt((toFrame.size.width-arcCenter.x)*(toFrame.size.width-arcCenter.x) + arcCenter.y * arcCenter.y)
            maxRadius = sqrt(arcCenter.x * arcCenter.x + (toFrame.size.height-arcCenter.y)*(toFrame.size.height-arcCenter.y))
        } else if arcCenter.x < viewCenter.x && arcCenter.y > viewCenter.y { //第3象限
            minRadius = sqrt(arcCenter.x * arcCenter.x + (toFrame.size.height-arcCenter.y)*(toFrame.size.height-arcCenter.y))
            maxRadius = sqrt((toFrame.size.width-arcCenter.x)*(toFrame.size.width-arcCenter.x) + arcCenter.y * arcCenter.y)
        } else if arcCenter.x > viewCenter.x && arcCenter.y > viewCenter.y { //第4象限
            minRadius = sqrt(arcCenter.x * arcCenter.x + (toFrame.size.height-arcCenter.y)*(toFrame.size.height-arcCenter.y))
            maxRadius = sqrt(arcCenter.x * arcCenter.x + arcCenter.y * arcCenter.y)
        }
        minRadius = min(minRadius, centerRect.size.width/2, centerRect.size.height/2)
        
        let startPath = UIBezierPath(arcCenter: arcCenter, radius: minRadius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        let endPath = UIBezierPath(arcCenter: arcCenter, radius: maxRadius, startAngle: 0, endAngle: CGFloat(M_PI*2), clockwise: true)
        
        //设置图层遮罩，显示为遮罩的样子
        let maskLayer = CAShapeLayer()
        toViewController.view.layer.mask = maskLayer
        
        let maskAnimation = CABasicAnimation(keyPath: "path")
        maskAnimation.fromValue = startPath.cgPath
        maskAnimation.toValue = endPath.cgPath
        maskAnimation.duration = transitionDuration(using: transitionContext)
        maskLayer.add(maskAnimation, forKey: "path")
        //动画改变的只是presentation图层，动画结束最终还是会显示model图层的结果，你需要手动设置model图层的值
        maskLayer.path = endPath.cgPath
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+transitionDuration(using: transitionContext)) {
            toViewController.view.layer.mask = nil
            transitionContext.completeTransition(true)
        }
    }
}
