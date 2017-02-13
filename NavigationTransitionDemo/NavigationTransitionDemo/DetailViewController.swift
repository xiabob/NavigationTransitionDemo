//
//  DetailViewController.swift
//  NavigationTransitionDemo
//
//  Created by xiabob on 17/2/9.
//  Copyright © 2017年 xiabob. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    lazy var cover: UIControl = {
        let cover = UIControl(frame: CGRect(x: 0, y: 0, width: 67*2, height: 96*2))
        cover.center = CGPoint(x: 200, y: 300)
        cover.layer.contents = UIImage(named: "cover")?.cgImage
        cover.addTarget(self, action: #selector(pushLargeImageVC), for: .touchUpInside)
        return cover
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = "封面"
        view.backgroundColor = UIColor.red
        view.addSubview(cover)
        
        navigationController?.attach(to: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.backgroundColor = UIColor.red
        cover.center = CGPoint(x: 200, y: 300)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func pushLargeImageVC() {
        view.backgroundColor = UIColor.white
        UIView.animate(withDuration: 0.25, animations: { 
            self.cover.center = CGPoint(x: 80, y: 240)
        }) { (finished) in
            self.navigationController?.pushViewController(LargeImageVC(), animated: true)
        }
    }
}

extension DetailViewController: UIViewPushAnimationTransitionType {
    func transitionDurationForPush(from viewController: UIViewController) -> TimeInterval {
        if viewController is ViewController {
            return 0.35
        }
        
        return 0.25
    }
    
    func animationTypeForPush(from viewController: UIViewController) -> PushAnimationType {
        if viewController is ViewController {
            return .scale
        }
        
        return .system
    }
}

extension DetailViewController: UIViewInteractivePopAnimationTransitionType {
    func useInteractiveAnimation() -> Bool {
        return true
    }
    
    func interactiveTransitionDurationForPop(to viewController: UIViewController) -> TimeInterval {
        return 0.25
    }
    
    func interactiveAnimationTypeForPop(to viewController: UIViewController) -> InteractivePopAnimationType {
        return .stackScale
    }
}
