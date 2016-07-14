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
    let n = node.nodeContaining(point) ?? node
    
    let (p, d) = closestPointInNode(n, toPoint: point)
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

func nearestNeighboursAlternate(toPoint point: QTRNodePoint, startingAt node:QTRNode, canUseParent parent: Bool, andApply map: (QTRNodePoint) -> ()) {
    let nodeContainer = node.nodeContaining(point)
    
    let nodeBoxSpan = parent ? nodeContainer!.parent!.bbox.span : nodeContainer!.bbox.span
    
    let bboxArray = bboxAroundCoordinate(point.coordinate2D, withSpan: nodeBoxSpan)
    let bbox = QTRBBox(bboxArray)
    
    node.get(pointsIn: bbox, andApply: map)
    
}

//var node: QTRNode? = QTRNode(QTRBBox([ -116,19,-53,72 ]),4)
let userPoint = QTRNodePoint(-84.477949, 42.725222 ,"userPoint")
//let userBox = QTRBBox(userPoint.coordinate2D, 92.0)

let randomBox = QTRBBox([ -84.5035622, 42.7127855, -84.4550801, 42.7367203 ])
//let pointArray = generateQTRPointArray(ofLength: 10, inRange: randomBox)
var pointArray = [QTRNodePoint]()

pointArray.append(QTRNodePoint(-84.480940, 42.724254,"Engineering"))
pointArray.append(QTRNodePoint(-84.493204, 42.731869,"Kellogg"))
pointArray.append(QTRNodePoint(-84.485011, 42.728123,"Spartan Stadium"))
pointArray.append(QTRNodePoint(-84.479267, 42.727068,"Erickson Hall"))
pointArray.append(QTRNodePoint(-84.473449, 42.729947,"Snyder Philips"))
pointArray.append(QTRNodePoint(-84.475382, 42.726726,"Shaw Hall"))
pointArray.append(QTRNodePoint(-84.481534, 42.729656,"Hannah Admin"))
pointArray.append(QTRNodePoint(-84.483243, 42.730860,"Main Library"))
pointArray.append(QTRNodePoint(-84.480358, 42.729150,"Computing Services"))

pointArray.append(QTRNodePoint(-84.477892, 42.733035,"Berkey"))
pointArray.append(QTRNodePoint(-84.474991, 42.728453,"Kresge Arts"))
pointArray.append(QTRNodePoint(-84.475371, 42.730594,"Psycho"))
pointArray.append(QTRNodePoint(-84.478599, 42.728548,"Bessey"))
pointArray.append(QTRNodePoint(-84.476482, 42.729834,"Giltner"))
pointArray.append(QTRNodePoint(-84.478660, 42.729828,"Kedzie"))
pointArray.append(QTRNodePoint(-84.476593, 42.728741,"Auditorium"))


let node: QTRNode? = QTRNode(pointArray, randomBox, 2)

var returnArray = [QTRNodePoint]()

//nearestNeighbours(toPoint: userPoint, startingAt: node!, andApply: { (nd: QTRNodePoint) -> () in
//    print(nd.name)
//    returnArray.append(nd)
//})

nearestNeighboursAlternate(toPoint: userPoint, startingAt: node!, canUseParent: true, andApply: { (nd: QTRNodePoint) -> () in
    print(nd.name)
    returnArray.append(nd)
})

//let tet = QTRNodePoint(-84.480940, 42.724254,"Engineering")
//let tit = QTRNodePoint(-84.477949, 42.725222 ,"userPoint")
//let testDistance = equiRectangularDistanceBetweenCoordinates(tit.coordinate2D, otherCoordinate: tet.coordinate2D)
//let parentBBox = QTRBBox([-5, -5, 5, 5])
//let parent = QTRNode(parentBBox, 2)
//let p1 = QTRNodePoint(1,1, "Point 1")
//let p2 = QTRNodePoint(-1,-1, "Point 2")
//let p3 = QTRNodePoint(-1,1, "Point 3")
//let p4 = QTRNodePoint(2,-2, "Point 4")
//let p5 = QTRNodePoint(-2,2, "Point 5")
//let p6 = QTRNodePoint(-3,3, "Point 6")
//
//parent.insert(p1)
//parent.insert(p2)
//parent.insert(p3)
//parent.insert(p4)
//parent.insert(p5)
//parent.insert(p6)
//
//let userPoint = QTRNodePoint(1, -1 ,"userPoint")
//let userNode = parent.nodeContaining(userPoint)
//userNode?.bbox.span.latitudeDelta
//userNode?.bbox.span.longitudeDelta
//let userBBox = bboxAroundCoordinate(userPoint.coordinate2D, withSpan: (userNode?.bbox.span)!)
//var returnArray = [QTRNodePoint]()


//nearestNeighbours(toPoint: userPoint, startingAt: parent, andApply: { (nd: QTRNodePoint) -> () in
//    print(nd.name)
//    returnArray.append(nd)
//})

//nearestNeighboursAlternate(toPoint: userPoint, startingAt: parent, canUseParent: true, andApply: { (nd: QTRNodePoint) -> () in
//    print(nd.name)
//    returnArray.append(nd)
//})
returnArray
