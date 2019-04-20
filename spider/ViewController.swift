//
//  ViewController.swift
//  spider
//
//  Created by Johnny Sparks  on 4/20/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit


class SpiderView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = .white
        self.layer.cornerRadius = self.bounds.height * 0.5
    }
}



class ViewController: UIViewController {

    var centerX: CGFloat {
        return self.view.bounds.midX
    }

    lazy var spider = SpiderView(frame: CGRect(x: self.centerX - 25, y: 0, width: 50, height: 50))
    lazy var animator = UIDynamicAnimator(referenceView: self.view)


    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))

    lazy var attatchment: UIAttachmentBehavior = {
        let attatchment = UIAttachmentBehavior(item: self.spider, attachedToAnchor: CGPoint(x: self.centerX, y: 0))
        attatchment.length = 1
        attatchment.damping = 0.8
        attatchment.frequency = 0.5
        return attatchment
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup views
        view.backgroundColor = .black
        view.addSubview(spider)

        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup behavior
        let gravity = UIGravityBehavior(items: [self.spider])
        self.animator.addBehavior(gravity)
        self.animator.addBehavior(attatchment)
    }

    @objc
    private func onTap(_ g: UITapGestureRecognizer) {
        attatchment.length += 20
    }


    func push(to location: CGPoint) {
        let push = UIPushBehavior(items: [spider], mode: .instantaneous)
        let dx = (location.x - spider.center.x) / 30
        let dy = (location.y - spider.center.y) / 30
        push.pushDirection = CGVector(dx: dx, dy: dy)

        animator.addBehavior(push)
    }
}

