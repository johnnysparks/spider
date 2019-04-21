//
//  ViewController.swift
//  spider
//
//  Created by Johnny Sparks  on 4/20/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // Utilities
    var centerX: CGFloat {
        return self.view.bounds.midX
    }

    // Views
    lazy var spider = SpiderView(frame: CGRect(x: self.centerX - 15, y: 0, width: 30, height: 30))
    lazy var thread: ThreadView = {
        let thread = ThreadView(frame: self.view.bounds)
        thread.spiderView = self.spider
        return thread
    }()

    lazy var background: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "background2.png"))
        imageView.contentMode = .scaleAspectFill
        imageView.frame = self.view.bounds.insetBy(dx: -50, dy: -50)
        return imageView
    }()

    // Interactions
    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))

    // UIDynamics
    lazy var animator = UIDynamicAnimator(referenceView: self.view)

    lazy var gravity = UIGravityBehavior(items: [self.spider])

    lazy var walls: UICollisionBehavior = {
        let walls = UICollisionBehavior(items: [self.spider])
        walls.addBoundary(withIdentifier: Boundary.top.identifier,
                          from: self.view.topLeftPoint,
                          to:  self.view.topRightPoint)
        walls.addBoundary(withIdentifier: Boundary.left.identifier,
                          from: self.view.topRightPoint,
                          to:  self.view.bottomRightPoint)
        walls.addBoundary(withIdentifier: Boundary.bottom.identifier,
                          from: self.view.bottomRightPoint,
                          to:  self.view.bottomLeftPoint)
        walls.addBoundary(withIdentifier: Boundary.right.identifier,
                          from: self.view.topLeftPoint,
                          to:  self.view.bottomLeftPoint)
        walls.collisionDelegate = self
        return walls
    }()

    var lastAttachmentBoundary: Boundary?

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
        [background, spider, thread].forEach { view.addSubview($0) }

        // Setup gestures
        view.addGestureRecognizer(tap)

        // Setup loop
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.growThread()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup behavior
        [gravity, attatchment, walls].forEach { self.animator.addBehavior($0) }
    }

    @objc
    private func onTap(_ g: UITapGestureRecognizer) {
        let location = g.location(in: view)

        gravity.gravityDirection = CGVector(dx: location.x - view.center.x, dy: location.y - view.center.y)
        UIView.animate(withDuration: 0.2) {
            self.background.transform = CGAffineTransform(rotationAngle: self.gravity.angle - CGFloat.pi / 2)
        }

        gravity.magnitude = 1
        thread.gravityVector = gravity.gravityDirection
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


// MARK: - UICollisionBehaviorDelegate
extension ViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {

        guard let boundary = Boundary.from(identifier), boundary != lastAttachmentBoundary else {
            return
        }

        attatchment.anchorPoint = p
        attatchment.length = 0
        lastAttachmentBoundary = boundary
        thread.attachmentPoints.append(p)
    }
}
