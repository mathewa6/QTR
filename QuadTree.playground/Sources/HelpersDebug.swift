import Foundation
import CoreLocation

//Basic Conversion functions.From DSAlgorithm.
public func radianToDegrees(_ radians: Double) -> Double {
	return (radians * (180/Double.pi))
}

public func degreesToRadians(_ degrees: Double) -> Double {
	return (degrees * (Double.pi/180))
}

/// - Returns 1/-1 for non  zero values.
/// - Returns 0 for error
///
public func sgn(_ value: Double) -> Int {
	if value == 0 {
		return 0
	}
	return Int(abs(value)/value)
}

public func haversineDistanceBetweenCoordinates(_ coordinate: CLLocationCoordinate2D, otherCoordinate: CLLocationCoordinate2D) -> Double
{
	let R: Double = 6378137
	let deltaLat = degreesToRadians((otherCoordinate.latitude - coordinate.latitude))
	let deltaLong = degreesToRadians((otherCoordinate.longitude - coordinate.longitude))
	
	let radianLatCoordinate = degreesToRadians(coordinate.latitude)
	let radianLatOther = degreesToRadians(otherCoordinate.latitude)
	
	let a = pow(sin(deltaLat/2.0), 2) + cos(radianLatCoordinate)*cos(radianLatOther)*pow(sin(deltaLong/2.0), 2)
	let c = 2 * atan2(sqrt(a), sqrt(1-a))
	
	return (R * c)
	
}

public func equiRectangularDistanceBetweenCoordinates(_ coordinate: CLLocationCoordinate2D, otherCoordinate: CLLocationCoordinate2D) -> Double {
	let R: Double = 6378137
	let deltaLat = degreesToRadians((otherCoordinate.latitude - coordinate.latitude))
	let deltaLong = degreesToRadians((otherCoordinate.longitude - coordinate.longitude))
	
	let radianLatCoordinate = degreesToRadians(coordinate.latitude)
	let radianLatOther = degreesToRadians(otherCoordinate.latitude)
	
	let x = deltaLong * cos((radianLatCoordinate + radianLatOther)/2.0)
	let y = deltaLat
	
	return R * sqrt(pow(x, 2) + pow(y, 2))
}

func closestPointInNode(_ node: QTRNode, toPoint point: QTRNodePoint) -> (QTRNodePoint?, Double?) {
	var distance: Double?
	var returnPoint: QTRNodePoint?
	
	for p in node.points {
		let temp = point.distanceFrom(p.coordinate2D)
		if distance == nil || temp < distance! {
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

func scaledValue(_ x: Double, alpha: Double, beta: Double, max: Double) -> Double{
	return max*(exp(-1.0 * alpha * pow(x, beta)))
}

public func nearestNeighbours(toPoint point: QTRNodePoint, startingAt node:QTRNode, andApply map: (QTRNodePoint) -> ()) {
	let n = node.nodeContaining(point) ?? node
	
	let (p, d) = closestPointInNode(n, toPoint: point)
	let factor = scaledValue(d!, alpha: 0.03, beta: 0.65, max: 3.0)
	//    p?.name
	//
	//    d!
	//    d!*factor
	let userB = QTRBBox(aroundCoordinate: point.coordinate2D, withBreadth: factor * d!)
	//    node.getByTraversingUp(pointsIn: userB, andApply: { (nd: QTRNodePoint) -> () in
	//        print(nd.name)
	//    })
	node.get(pointsIn: userB, andApply: map)
	
}

public func nearestNeighboursAlternate(toPoint point: QTRNodePoint, startingAt node:QTRNode, canUseParent parent: Bool, andApply map: (QTRNodePoint) -> ()) {
	let nodeContainer = node.nodeContaining(point)
	
	let nodeBoxSpan = parent ? nodeContainer!.parent!.bbox.span : nodeContainer!.bbox.span
	
	let bbox = QTRBBox(aroundCoordinate: point.coordinate2D, withSpan: nodeBoxSpan)
	
	node.get(pointsIn: bbox, andApply: map)
	
}

func generateRandomPoint(inRange bbox: QTRBBox) -> CLLocationCoordinate2D {
	let p = Double(arc4random_uniform(250))*(bbox.highLatitude - bbox.lowLatitude)/100 + bbox.lowLatitude
	let q = Double(arc4random_uniform(250))*(bbox.highLongitude - bbox.lowLongitude)/100 + bbox.lowLongitude
	
	return CLLocationCoordinate2DMake(p, q)
}

func generateQTRPointArray(ofLength length: Int, inRange bbox: QTRBBox) -> [QTRNodePoint] {
	var returnArray = [QTRNodePoint]()
	
	for i in 0..<length {
		returnArray.append(QTRNodePoint(generateRandomPoint(inRange: bbox), "RandomPoint_" + "\(i)"))
	}
	
	return returnArray
}
