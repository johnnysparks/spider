//
//  ViewController.swift
//  spider
//
//  Created by Johnny Sparks  on 4/20/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit

extension UIView {
    var topLeftPoint: CGPoint { return frame.origin }
    var topRightPoint: CGPoint { return CGPoint(x: frame.minX, y: frame.maxY) }
    var bottomLeftPoint: CGPoint { return CGPoint(x: frame.maxX, y: frame.minY) }
    var bottomRightPoint: CGPoint { return CGPoint(x: frame.maxX, y: frame.maxY) }
}

class SpiderView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = .white
        self.layer.cornerRadius = self.bounds.height * 0.5
    }
}


enum Boundary: String {
    case top = "top"
    case left = "left"
    case bottom = "bottom"
    case right = "right"

    var identifier: NSString {
        return self.rawValue as NSString
    }

    static func from(_ identifier: NSCopying?) -> Boundary? {
        guard let string = identifier as? NSString else {
            return nil
        }

        return Boundary(rawValue: string as String)
    }
}

class ThreadView: UIView {
    weak var spiderView: SpiderView?
    var gravityVector: CGVector = .zero
    var attachmentPoints: [CGPoint] = []

    lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        self.layer.addSublayer(layer)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.refresh()
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refresh() {

        let allPoints: [CGPoint] = (self.attachmentPoints + [spiderView?.center]).compactMap { $0 }

        let pairs = (0..<allPoints.count)
            .map { idx -> (CGPoint, CGPoint)? in
                let nextIdx = idx.advanced(by: 1)
                guard nextIdx < allPoints.count else {
                    return nil
                }

                return (allPoints[idx], allPoints[nextIdx])
            }
            .compactMap { $0 }


        guard pairs.count > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.refresh()
            }
            return
        }

        let path = UIBezierPath()
        path.move(to: allPoints.first!)
        path.lineWidth = 3

        let vector = CGVector(dx: gravityVector.dx * 60, dy: gravityVector.dy * 60)

        pairs.forEach {
            let a = CGPoint(x: $0.0.x + vector.dx, y: $0.0.y + vector.dy)
            let b = CGPoint(x: $0.1.x + vector.dx, y: $0.1.y + vector.dy)
            let quarterPoint = CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
            let threeQuaterPoint = CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
            path.addCurve(to: $0.1, controlPoint1: quarterPoint, controlPoint2: threeQuaterPoint)
        }

        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.path = path.cgPath

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.refresh()
        }
    }
}

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
