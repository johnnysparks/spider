//
//  ViewController.swift
//  spider
//
//  Created by Johnny Sparks  on 4/20/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit


extension UIDynamicItem where Self == UIView {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs == rhs
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - self.x, 2) + pow(point.y - self.y, 2))
    }

    func mid(to point: CGPoint) -> CGPoint {
        return self.point(percent: 0.5, approaching: point)
    }

    func point(percent: CGFloat, approaching point: CGPoint) -> CGPoint {
        return CGPoint(x: (max(self.x, point.x) - min(self.x, point.x)) * percent + min(self.x, point.x),
                       y: (max(self.y, point.y) - min(self.y, point.y)) * percent + min(self.y, point.y))
    }
}

class Intersection {
    var at: Date = Date()
    var begin: UIView
    var end: UIView
    var points: [UIView]

    init(begin: UIView, end: UIView, points: [UIView]) {
        self.begin = begin
        self.end = end
        self.points = points
    }
}

extension Intersection: Equatable {
    static func == (lhs: Intersection, rhs: Intersection) -> Bool {
        return lhs.begin == rhs.begin && lhs.end == rhs.end
    }
}

class TestWebViewController: UIViewController {
    var nodes: [UIView] = []
    var intersections: [Intersection] = []

    // Utilities
    var centerX: CGFloat {
        return self.view.bounds.midX
    }

    // Views
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

    lazy var gravity = UIGravityBehavior(items: [])

    func addChain(between items:(UIView, UIView)) {

        let linkDist: CGFloat = 10

        func makeLink() -> UIView {
            let midNode = UIView(frame: CGRect(x: 0, y: 0, width: 3, height: 3))
            midNode.backgroundColor = UIColor.white.withAlphaComponent(0.75)
            midNode.layer.cornerRadius = 1.5
            self.view.addSubview(midNode)

            return midNode
        }

        let dist = items.0.center.distance(to: items.1.center)

        let miniLinks: [UIView] = (0..<Int(dist / linkDist)).map({ _ in makeLink() })

        // every 10 pts
        let links: [UIView] = [items.0] + miniLinks + [items.1]

        links.enumerated().forEach { idx, curr in
            guard idx < links.count - 1 else { return }

            let next = links[idx + 1]

            let percent = CGFloat(idx) / (dist / linkDist)
            let linkLocation = items.0.center.point(percent: percent, approaching: items.1.center)
            curr.center = linkLocation

            let nextPercent = CGFloat(idx + 1) / (dist / linkDist)
            let nextLocation = items.0.center.point(percent: nextPercent, approaching: items.1.center)
            next.center = nextLocation

            let attatchment = UIAttachmentBehavior(item: curr, attachedTo: next)
            attatchment.length = linkDist * 0.9
            attatchment.damping = 1
            attatchment.frequency = 30

            self.animator.addBehavior(attatchment)
        }

        self.intersections.append(Intersection(begin: items.0, end: items.1, points: miniLinks))
    }

    func addIntersection(at point: CGPoint) {
        let node = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        node.backgroundColor = .white
        node.layer.cornerRadius = 5
        node.center = point
        view.addSubview(node)


        let attatchment = UIAttachmentBehavior(item: node, attachedToAnchor: point)
        attatchment.length = 0.0
        attatchment.damping = 0.9
        attatchment.frequency = 5
        attatchment.attachmentRange = UIFloatRange(minimum: -50, maximum: 50)

        animator.addBehavior(attatchment)
        gravity.addItem(node)

        if let last = nodes.last {
            addChain(between: (node, last))
            gravity.addItem(node)
        }

        nodes.append(node)
    }

    // Clean up all links in a chain, matching the first chain that is within some minimum distance
    // to the link.
    //
    // This includes cleaning up all
    // - behaviors
    // - intersections
    // - chain links
    //
    func removeChain(at location: CGPoint) {
        let minDist: CGFloat = 10

        self.intersections
            .map { i in (i, i.points.first(where: { $0.center.distance(to: location) < minDist })) }
            .first(where: { $0.1 != nil })
            .map { pair in
                pair.0.points.forEach { link in
                    self.animator.behaviors
                        .compactMap { $0 as? UIAttachmentBehavior }
                        .filter { $0.items.compactMap({ $0 as? UIView }).contains(link) }
                        .forEach { self.animator.removeBehavior($0) }

                    link.removeFromSuperview()
                }

                self.intersections.removeAll(where: { $0 == pair.0 })
            }
    }

    // Loop
    var timer: Timer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup views
        view.backgroundColor = .black
        [background].forEach { view.addSubview($0) }

        // Setup gestures
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup behavior
        [gravity].forEach { self.animator.addBehavior($0) }
    }

    func highlightLink(at location: CGPoint) {
        let minDist: CGFloat = 10
        let tappedLink = self.intersections
            .map { $0.points }
            .flatMap { $0 }
            .first(where: { $0.center.distance(to: location) < minDist })

        if let link = tappedLink {
            let oldCenter = link.center
            link.backgroundColor = .purple
            link.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            link.layer.cornerRadius = 10
            link.center = oldCenter
        }
    }


    @objc
    private func onTap(_ g: UITapGestureRecognizer) {
        let location = g.location(in: view)


//        removeChain(at: location)

        gravity.gravityDirection = CGVector(dx: location.x - view.center.x, dy: location.y - view.center.y)
        UIView.animate(withDuration: 0.2) {
            self.background.transform = CGAffineTransform(rotationAngle: self.gravity.angle - CGFloat.pi / 2)
        }

        gravity.magnitude = 0.5

        addIntersection(at: location)

        // This shit's for testing I guess?
        highlightLink(at: location)
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
