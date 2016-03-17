//
//  QuadTree.playground
//
//  Created by Adi Mathew on 3/16/16.
//  Copyright (c) 2016 RCPD. All rights reserved.
//

import Foundation

func closestPointInNode(node: QTRNode, toPoint point: QTRNodePoint) -> (QTRNodePoint?, Double?) {
    var distance: Double?
    var returnPoint: QTRNodePoint?
    
    for p in node.points {
        let temp = point.distanceFrom(p.coordinate2D)
        if distance == nil || temp < distance {
            if temp > 80.0 {
                distance = temp
                returnPoint = p
            }
        }
    }
    
    if returnPoint == nil && distance == nil && node.parent != nil{
        (returnPoint,distance) = closestPointInNode(node.parent!, toPoint: point)
    }
    
    return (returnPoint,distance ?? 80.0)
}

func scaledValue(x: Double, alpha: Double, beta: Double, max: Double) -> Double{
    return max*(exp(-1.0 * alpha * pow(x, beta)))
}

func nearestNeighbours(toPoint point: QTRNodePoint, startingAt node:QTRNode, andApply map: (QTRNodePoint) -> ()) {
    let n = node.nodeContaining(point)
    
    let (p, d) = closestPointInNode(n!, toPoint: point)
    let factor = scaledValue(d!, alpha: 0.03, beta: 0.65, max: 3.0)
//    p?.name
//    
//    d!
//    d!*factor
    let userB = QTRBBox(point.coordinate2D, factor * d!)
//    node.getByTraversingUp(pointsIn: userB, andApply: { (nd: QTRNodePoint) -> () in
//        print(nd.name)
//    })
    node.get(pointsIn: userB, andApply: map)
    
}


//var node: QTRNode? = QTRNode(QTRBBox([ -116,19,-53,72 ]),4)
let userPoint = QTRNodePoint(42.725222, -84.477949 ,"userPoint")
//let userBox = QTRBBox(userPoint.coordinate2D, 92.0)

let randomBox = QTRBBox([ -84.5035622, 42.7127855, -84.4550801, 42.7367203 ])
//let pointArray = generateQTRPointArray(ofLength: 10, inRange: randomBox)
var pointArray = [QTRNodePoint]()

pointArray.append(QTRNodePoint(42.724254, -84.480940,"Engineering"))
pointArray.append(QTRNodePoint(42.731869, -84.493204,"Kellogg"))
pointArray.append(QTRNodePoint(42.728123, -84.485011,"Spartan Stadium"))
pointArray.append(QTRNodePoint(42.727068, -84.479267,"Erickson Hall"))
pointArray.append(QTRNodePoint(42.729947, -84.473449,"Snyder Philips"))
pointArray.append(QTRNodePoint(42.726726, -84.475382,"Shaw Hall"))
pointArray.append(QTRNodePoint(42.729656, -84.481534,"Hannah Admin"))
pointArray.append(QTRNodePoint(42.730860, -84.483243,"Main Library"))
pointArray.append(QTRNodePoint(42.729150, -84.480358,"Computing Services"))

pointArray.append(QTRNodePoint(42.733035, -84.477892,"Berkey"))
pointArray.append(QTRNodePoint(42.728453, -84.474991,"Kresge Arts"))
pointArray.append(QTRNodePoint(42.730594, -84.475371,"Psycho"))
pointArray.append(QTRNodePoint(42.728548, -84.478599,"Bessey"))
pointArray.append(QTRNodePoint(42.729834, -84.476482,"Giltner"))
pointArray.append(QTRNodePoint(42.729828, -84.478660,"Kedzie"))
pointArray.append(QTRNodePoint(42.728741, -84.476593,"Auditorium"))


let node: QTRNode? = QTRNode(pointArray, randomBox, 2)

var returnArray = [QTRNodePoint]()

nearestNeighbours(toPoint: userPoint, startingAt: node!, andApply: { (nd: QTRNodePoint) -> () in
    print(nd.name)
    returnArray.append(nd)
})