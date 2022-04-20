//
//  QuadTree.swift
//  DIRStage
//
//  Created by Adi Mathew on 8/7/14.
//  Copyright (c) 2014 RCPD. All rights reserved.
//

// TODO: - http://stackoverflow.com/questions/24047991/does-swift-have-documentation-comments-or-tools

import CoreLocation
import MapKit

public enum QTRNodeQuadrant: Int {
	case ne = 0,
		 se,
		 sw,
		 nw
}

// MARK: - QTRSpan class methods
public struct QTRSpan: CustomStringConvertible {
	public var longitudeDelta: CLLocationDegrees
	public var latitudeDelta: CLLocationDegrees
	public var mapKitSpan: MKCoordinateSpan {
		return MKCoordinateSpan(latitudeDelta: self.latitudeDelta,
								longitudeDelta: self.longitudeDelta)
	}
	
	public init (_ longitudeDelta: CLLocationDegrees, _ latitudeDelta: CLLocationDegrees) {
		self.latitudeDelta = latitudeDelta
		self.longitudeDelta = longitudeDelta
	}
	
	public init (_ bbox: [CLLocationDegrees]) {
		self.latitudeDelta = bbox[3] - bbox[1]
		self.longitudeDelta = bbox[2] - bbox[0]
	}
	
	public var description: String {
		return "\(self.longitudeDelta), \(self.latitudeDelta)"
	}
}

// MARK: - QTRNodePoint methods
open class QTRNodePoint: NSObject, MKAnnotation {
	
	public var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(latitude: self.latitude!,
									  longitude: self.longitude!)
	}
	
	var longitude: Double?
	var latitude: Double?
	
	open var name: String
	open var coordinate2D: CLLocationCoordinate2D {
		get {
			return CLLocationCoordinate2DMake(self.latitude!, self.longitude!)
		}
	}
	
	override open var description: String {
		return "(\(longitude ?? 0), \(latitude ?? 0)): \(name)"
	}
	
	public init (_ longitude: Double, _ latitude: Double, _ name: String) {
		self.longitude = longitude
		self.latitude = latitude
		self.name = name
		
		//        super.init()
	}
	
	public init (_ coordinate: CLLocationCoordinate2D, _ name: String) {
		self.longitude = coordinate.longitude
		self.latitude = coordinate.latitude
		self.name = name
	}
	
	public init(_ coordinate: [CLLocationDegrees]) {
		self.longitude = coordinate[0]
		self.latitude = coordinate[1]
		self.name = "Unknown"
	}
	
	open func distanceFrom(_ coordinate: CLLocationCoordinate2D) -> Double
	{
		var distance = equiRectangularDistanceBetweenCoordinates(self.coordinate2D, otherCoordinate: coordinate)
		
		if distance > 6000.0 {
			distance = haversineDistanceBetweenCoordinates(self.coordinate2D, otherCoordinate: coordinate)
		}
		
		return distance
	}
	
}

// MARK: - QTRBBox methods
open class QTRBBox: CustomStringConvertible {
	open var lowLatitude: Double
	open var highLatitude: Double
	open var lowLongitude: Double
	open var highLongitude: Double
	
	open var center: CLLocationCoordinate2D {
		get {
			return centerOfBoundingBox([self.lowLongitude, self.lowLatitude, self.highLongitude, self.highLatitude])
		}
	}
	open var span: QTRSpan
	
	public var mapRect: MKMapRect {
		let topLeft: MKMapPoint = MKMapPoint(CLLocationCoordinate2D(latitude: self.highLatitude,
																	longitude: self.lowLongitude))
		let bottomRight: MKMapPoint = MKMapPoint(CLLocationCoordinate2D(latitude: self.lowLatitude,
																		longitude: self.highLongitude))
		
		return MKMapRect(x: topLeft.x,
						 y: bottomRight.y,
						 width: fabs(bottomRight.x - topLeft.x),
						 height: fabs(bottomRight.y - topLeft.y))
		
	}
	
	open var description: String {
		return "\(lowLongitude), \(lowLatitude), \(highLongitude), \(highLatitude)"
	}
	
	public init (_ lowLongitude: Double, _ lowLatitude: Double, _ highLongitude: Double, _ highLatitude: Double) {
		self.lowLatitude = lowLatitude
		self.highLatitude = highLatitude
		self.lowLongitude = lowLongitude
		self.highLongitude = highLongitude
		self.span = QTRSpan([lowLongitude, lowLatitude, highLongitude, highLatitude])
		
		//        super.init()
	}
	
	public init (withArray bbox: [CLLocationDegrees]) {
		var assignment: [CLLocationDegrees] = bbox
		if assignment.isEmpty {
			assignment = [0, 0, 0, 0]
		}
		
		self.lowLatitude = assignment[1]
		self.highLatitude = assignment[3]
		self.lowLongitude = assignment[0]
		self.highLongitude = assignment[2]
		self.span = QTRSpan(assignment)
	}
	
	/// Returns a box around a given coordinate with a normalized distance as it's side.
	///
	/// - note: The return array is formatted as [lowLongitude, lowLatitude, highLongitude, highLatitude]
	/// - returns: An array of CLLocationDegrees.
	public convenience init(aroundCoordinate coordinate: CLLocationCoordinate2D, withBreadth distance: CLLocationDistance) {
		let MIN_LAT = -Double.pi/2
		let MAX_LAT = Double.pi/2
		let MIN_LONG = -Double.pi
		let MAX_LONG = Double.pi
		
		let R: Double = 6378137
		let r = distance/R
		
		if CLLocationCoordinate2DIsValid(coordinate) {
			let latRadian = degreesToRadians(coordinate.latitude)
			let longRadian = degreesToRadians(coordinate.longitude)
			
			
			var latMin = latRadian - r
			var latMax = latRadian + r
			var longMin = 0.0
			var longMax = 0.0
			
			if latMin > MIN_LAT && latMax < MAX_LAT {
				let deltaLong = asin(sin(r)/cos(latRadian))
				
				longMin = longRadian - deltaLong
				if longMin < MIN_LONG {
					longMin += 2.0 * Double.pi
				}
				
				longMax = longRadian + deltaLong
				if longMax > MAX_LONG {
					longMax -= 2.0 * Double.pi
				}
			}
			else {
				latMin = max(latMin, MIN_LAT)
				latMax = min(latMax, MAX_LAT)
				longMin = MIN_LONG
				longMax = MAX_LONG
			}
			
			let initArray: [CLLocationDegrees] = [longMin, latMin, longMax, latMax].map{
				(rads) -> CLLocationDegrees in
				return radianToDegrees(rads)
			}
			self.init(withArray: initArray)
		} else {
			self.init(withArray: [])
		}
	}
	
	public convenience init(forMapRect mapRect: MKMapRect) {
		let topLeft: CLLocationCoordinate2D = mapRect.origin.coordinate
		let xMax = mapRect.maxX
		let yMax = mapRect.maxY
		let bottomRight: CLLocationCoordinate2D = MKMapPoint(x: xMax, y: yMax).coordinate
		
		let latMin = bottomRight.latitude
		let latMax = topLeft.latitude
		let longMin = topLeft.longitude
		let longMax = bottomRight.longitude
		
		self.init(withArray: [longMin, latMin, longMax, latMax])
	}
	
	/// Returns a box around a given coordinate using the given span struct to calculate bounds.
	///
	/// - note: The return array is formatted as [lowLongitude, lowLatitude, highLongitude, highLatitude]
	/// - returns: An array of CLLocationDegrees.
	public convenience init(aroundCoordinate coordinate: CLLocationCoordinate2D, withSpan span: QTRSpan) {
		if CLLocationCoordinate2DIsValid(coordinate) {
			let latitudeRadius = span.latitudeDelta/2.0
			let longitudeRadius = span.longitudeDelta/2.0
			
			//Check for wraparound cases. i.e 180 +/- x
			
			let latMin = coordinate.latitude - latitudeRadius
			let latMax = coordinate.latitude + latitudeRadius
			let longMin = coordinate.longitude - longitudeRadius
			let longMax = coordinate.longitude + longitudeRadius
			
			self.init(withArray: [longMin, latMin, longMax, latMax])
		} else {
			self.init(withArray: [])
		}
	}
	
	open func centerOfBoundingBox(_ bbox: [CLLocationDegrees]) -> CLLocationCoordinate2D
	{
		//        let upperRight = CLLocationCoordinate2DMake(bbox[3], bbox[2])
		//        let lowerLeft = CLLocationCoordinate2DMake(bbox[1],  bbox[0])
		
		//        if (CLLocationCoordinate2DIsValid(upperRight) && CLLocationCoordinate2DIsValid(lowerLeft) ){
		//            //Using C functions. Try Swift's trig functions too. USE Radians.
		//            if (upperRight.latitude - lowerLeft.latitude >= 3.0) || (upperRight.longitude - lowerLeft.longitude >= 3.0) {
		//                let longitudeDelta = degreesToRadians((upperRight.longitude - lowerLeft.longitude))
		//
		//                let bX = cos(degreesToRadians(upperRight.latitude)) * cos(longitudeDelta)
		//                let bY = cos(degreesToRadians(upperRight.latitude)) * sin(longitudeDelta)
		//
		//                let midLatitude = atan2(sin(degreesToRadians(lowerLeft.latitude)) + sin(degreesToRadians(upperRight.latitude)), sqrt(pow(cos(degreesToRadians(lowerLeft.latitude)) + bX, 2) + pow(bY, 2)))
		//                let midLongitude = degreesToRadians(lowerLeft.longitude) + atan2(bY, cos(degreesToRadians(lowerLeft.latitude)) + bX)
		//
		//                return CLLocationCoordinate2DMake(radianToDegrees(midLatitude), radianToDegrees(midLongitude))
		//            }
		//        }
		return CLLocationCoordinate2DMake((bbox[3] + bbox[1])/2.0, (bbox[2] + bbox[0])/2.0)
	}
	
	fileprivate func asArray() -> [CLLocationDegrees] {
		return [self.lowLongitude, self.lowLatitude, self.highLongitude, self.highLatitude]
	}
	
	open func containsCoordinate(_ coordinate: CLLocationCoordinate2D ) -> Bool
	{
		var isWithinLongitudes: Bool = false
		var isWithinLatitudes: Bool = false
		
		//for Latitudes
		if self.lowLatitude < coordinate.latitude && coordinate.latitude <= self.highLatitude {
			isWithinLatitudes = true
		}
		
		//for Longitudes
		if sgn(self.highLongitude == 0.0 ? self.highLongitude + 0.1E6 : self.highLongitude) == sgn(self.lowLongitude == 0.0 ? self.lowLongitude + 0.1E6 : self.lowLongitude) || self.lowLongitude < self.highLongitude {
			if self.lowLongitude < coordinate.longitude && coordinate.longitude <= self.highLongitude {
				isWithinLongitudes = true
			}
		} else {
			if abs(self.highLongitude) <= abs(coordinate.longitude) && abs(coordinate.longitude) > abs(self.lowLongitude) {
				isWithinLongitudes = true
			}
		}
		
		return isWithinLatitudes && isWithinLongitudes
	}
	
	open func intersects(boundingBox bbox: QTRBBox) -> Bool
	{
		if !(sgn(self.highLongitude == 0.0 ? self.highLongitude + 0.1E6 : self.highLongitude) == sgn(self.lowLongitude == 0.0 ? self.lowLongitude + 0.1E6 : self.lowLongitude)) || !(self.lowLongitude < self.highLongitude) {
			// Remove !(sgn(bbox.highLongitude) == sgn(bbox.lowLongitude)) for flat(debug)coordinate and not wrapped around systems.
			if !(sgn(bbox.highLongitude) == sgn(bbox.lowLongitude)) || !(bbox.lowLongitude < bbox.highLongitude) {
				return false
			}
		}
		
		if self.lowLatitude <= bbox.highLatitude && self.highLatitude > bbox.lowLatitude {
			if self.lowLongitude <= bbox.highLongitude && self.highLongitude > bbox.lowLongitude {
				return true
			}
		}
		
		return false
	}
}

// MARK: - QTRNode methods
open class QTRNode: CustomStringConvertible {
	var ne: QTRNode?
	var se: QTRNode?
	var sw: QTRNode?
	var nw: QTRNode?
	
	open weak var parent: QTRNode?
	
	open var bbox: QTRBBox
	var bucketCapacity: Int
	
	open var points: Array<QTRNodePoint>
	
	open var size: Int {
		return self.points.count
	}
	
	open var isLeaf: Bool {
		return self.ne == nil
	}
	
	open var description: String {
		let split = self.ne != nil ? "Yes" : "No"
		return "pointsContained: \(size), hasChildren: \(split), boundingBox: \(bbox)"
	}
	
	public init (_ bbox: QTRBBox, _ bucketCapacity: Int) {
		self.bbox = bbox
		self.points = []
		self.bucketCapacity = bucketCapacity
	}
	
	public convenience init (_ points: [QTRNodePoint], _ bbox: QTRBBox, _ bucketCapacity: Int) {
		self.init(bbox, bucketCapacity)
		for p: QTRNodePoint in points {
			_ = self.insert(p)
		}
	}
	
	fileprivate func split() {
		let box = self.bbox
		let c = box.center
		
		let ne = QTRBBox(c.longitude, c.latitude, box.highLongitude, box.highLatitude)
		self.ne = QTRNode(ne, self.bucketCapacity)
		self.ne?.parent = self
		
		let se = QTRBBox(c.longitude, box.lowLatitude, box.highLongitude, c.latitude)
		self.se = QTRNode(se, self.bucketCapacity)
		self.se?.parent = self
		
		let sw = QTRBBox(box.lowLongitude, box.lowLatitude, c.longitude, c.latitude)
		self.sw = QTRNode(sw, self.bucketCapacity)
		self.sw?.parent = self
		
		let nw = QTRBBox(box.lowLongitude, c.latitude, c.longitude, box.highLatitude)
		self.nw = QTRNode(nw, self.bucketCapacity)
		self.nw?.parent = self
		
		if self.size == bucketCapacity {
			for point in self.points {
				if self.ne!.insert(point) { continue }
				else if self.se!.insert(point) { continue }
				else if self.sw!.insert(point) { continue }
				else if !self.nw!.insert(point) {print("ERROR: Split Failed")}
			}
			self.points = []
		}
	}
	
	open func insert(_ point: QTRNodePoint) -> Bool {
		if !self.bbox.containsCoordinate(point.coordinate2D) && self.ne == nil {
			return false
		}
		
		if self.size < self.bucketCapacity && self.ne == nil {
			self.points.append(point)
			return true
		}
		
		if self.size == self.bucketCapacity && self.ne == nil  {
			self.split()
		}
		
		if self.ne!.insert(point) { return true }
		if self.se!.insert(point) { return true }
		if self.sw!.insert(point) { return true }
		if self.nw!.insert(point) { return true }
		
		return false
	}
	
	open func get(pointsIn range: QTRBBox, andApply map: (QTRNodePoint) -> ()) {
		if !self.bbox.intersects(boundingBox: range) {
			return
		}
		
		for p in self.points {
			if range.containsCoordinate(p.coordinate2D) {
				map(p)
			}
		}
		
		if self.ne == nil {
			return
		}
		
		self.ne?.get(pointsIn: range, andApply: map)
		self.se?.get(pointsIn: range, andApply: map)
		self.sw?.get(pointsIn: range, andApply: map)
		self.nw?.get(pointsIn: range, andApply: map)
	}
	
	open func traverse(andApply map: (QTRNode) -> ()) {
		map(self)
		
		if self.ne == nil {
			return
		}
		
		self.ne?.traverse(andApply: map)
		self.se?.traverse(andApply: map)
		self.sw?.traverse(andApply: map)
		self.nw?.traverse(andApply: map)
	}
	
	open func getByTraversingUp(pointsIn range: QTRBBox, andApply map: (QTRNodePoint) -> ()) {
		if !self.bbox.intersects(boundingBox: range) {
			return
		}
		
		for p in self.points {
			if range.containsCoordinate(p.coordinate2D) {
				map(p)
			}
		}
		
		if self.parent == nil {
			return
		}
		
		self.parent?.getByTraversingUp(pointsIn: range, andApply: map)
	}
	
	open func traverseUp(andApply map: (QTRNode) -> ()) {
		map(self)
		
		if self.parent == nil {
			return
		}
		
		self.parent?.traverseUp(andApply: map)
	}
	
	open func nodeContaining(_ point: QTRNodePoint) -> QTRNode? {
		var n: QTRNode?
		
		if self.bbox.containsCoordinate(point.coordinate2D) {
			n = self
			
			if self.ne != nil {
				var c: QTRNode? = self.ne?.nodeContaining(point)
				c = c == nil ? self.se?.nodeContaining(point) : c
				c = c == nil ? self.sw?.nodeContaining(point) : c
				c = c == nil ? self.nw?.nodeContaining(point) : c
				if c != nil {
					n = c
				}
			}
		}
		return n
	}
	
	deinit {
		print("DeInitializing")
		self.ne = nil
		self.se = nil
		self.sw = nil
		self.nw = nil
	}
}
