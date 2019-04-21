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

    // Utilities
    var centerX: CGFloat {
        return self.view.bounds.midX
    }

    // Views
    lazy var spider = SpiderView(frame: CGRect(x: self.centerX - 25, y: 0, width: 50, height: 50))

    // Interactions
    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))

    // UIDynamics
    lazy var animator = UIDynamicAnimator(referenceView: self.view)

    lazy var gravity = UIGravityBehavior(items: [self.spider])

    lazy var walls: UICollisionBehavior = {
        let walls = UICollisionBehavior(items: [self.spider])
        walls.translatesReferenceBoundsIntoBoundary = true
        return walls
    }()

    lazy var attatchment: UIAttachmentBehavior = {
        let attatchment = UIAttachmentBehavior(item: self.spider, attachedToAnchor: CGPoint(x: self.centerX, y: 0))
        attatchment.length = 1
        attatchment.damping = 0.8
        attatchment.frequency = 0.5
        return attatchment
    }()


    // Loop
    var timer: Timer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup views
        view.backgroundColor = .black
        view.addSubview(spider)
        view.addGestureRecognizer(tap)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.growThread()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup behavior
        self.animator.addBehavior(gravity)
        self.animator.addBehavior(attatchment)
        self.animator.addBehavior(walls)
    }

    @objc
    private func onTap(_ g: UITapGestureRecognizer) {
        let location = g.location(in: view)

        gravity.gravityDirection = CGVector(dx: location.x - view.center.x, dy: location.y - view.center.y)
        gravity.magnitude = 1
    }

    func growThread() {
        attatchment.length += 40
    }

    // Scratchpad
    func push(to location: CGPoint) {
        let push = UIPushBehavior(items: [spider], mode: .instantaneous)
        let dx = (location.x - spider.center.x) / 30
        let dy = (location.y - spider.center.y) / 30
        push.pushDirection = CGVector(dx: dx, dy: dy)

        animator.addBehavior(push)
    }
}

