//
//  LargeImageVC.swift
//  NavigationTransitionDemo
//
//  Created by xiabob on 17/2/10.
//  Copyright © 2017年 xiabob. All rights reserved.
//

import UIKit

class LargeImageVC: UIViewController {
    
    internal lazy var cover: UIControl = {
        let cover = UIControl(frame: CGRect(x: 0, y: 0, width: 67*2, height: 96*2))
        cover.layer.borderWidth = 4
        cover.layer.borderColor = UIColor.white.cgColor
        cover.center = CGPoint(x: 80, y: 240)
        cover.layer.contents = UIImage(named: "cover")?.cgImage
        return cover
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = "详情"
        view.layer.contents = UIImage(named: "cover")?.cgImage
        view.addSubview(cover)
        
        navigationController?.attach(to: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension LargeImageVC: UIViewPushAnimationTransitionType {
    func transitionDurationForPush(from viewController: UIViewController) -> TimeInterval {
        return 0.25
    }
    
    func animationTypeForPush(from viewController: UIViewController) -> PushAnimationType {
        return .mask(cover.frame)
    }
}

extension LargeImageVC: UIViewPopAnimationTransitionType {
    func transitionDurationForPop(to viewController: UIViewController) -> TimeInterval {
        if viewController is DetailViewController {
            return 0.35
        }
        
        return 0.25
    }
    
    func animationTypeForPop(to viewController: UIViewController) -> PopAnimationType {
        if viewController is DetailViewController {
            return .custom
        }
        
        return .system
    }
    
    func customAnimationForPop(to viewController: UIViewController, using transitionContext: UIViewControllerContextTransitioning, in popTransitioning: NavigationPopAnimationTransitioning) {
        if let viewController = viewController as? DetailViewController {
            UIView.animate(withDuration: 0.25, animations: {
                self.cover.center = viewController.cover.center
            }, completion: { (finished) in
                if !transitionContext.transitionWasCancelled {
                    popTransitioning.maskAnimateTransition(using: transitionContext, in: self.cover.frame)
                } else {
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            })
        }
    }
}

extension LargeImageVC: UIViewInteractivePopAnimationTransitionType {
    func useInteractiveAnimation() -> Bool {
        return true
    }
    
    func interactiveTransitionDurationForPop(to viewController: UIViewController) -> TimeInterval {
        return 0.25
    }
    
    func interactiveAnimationTypeForPop(to viewController: UIViewController) -> InteractivePopAnimationType {
        return .system
    }
}
