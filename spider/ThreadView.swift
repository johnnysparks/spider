//
//  ThreadView.swift
//  spider
//
//  Created by Johnny Sparks  on 4/21/19.
//  Copyright © 2019 Johnny Sparks . All rights reserved.
//

import UIKit

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
