//
//  QuadTree.swift
//  DIRStage
//
//  Created by Adi Mathew on 8/7/14.
//  Copyright (c) 2014 RCPD. All rights reserved.
//

import CoreLocation

public enum QTRNodeQuadrant: Int {
    case NE = 0,
    SE,
    SW,
    NW
}

public struct QTRSpan {
    var longitudeDelta: CLLocationDegrees
    var latitudeDelta: CLLocationDegrees
    
    public init (_ longitudeDelta: CLLocationDegrees, _ latitudeDelta: CLLocationDegrees) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
    
    public init (_ bbox: [CLLocationDegrees]) {
        self.latitudeDelta = bbox[3] - bbox[1]
        self.longitudeDelta = bbox[2] - bbox[0]
    }
}

public class QTRNodePoint: CustomStringConvertible {
    var longitude: Double?
    var latitude: Double?
    
    public var name: String
    public var coordinate2D: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(self.latitude!, self.longitude!)
        }
    }
    
    public var description: String {
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
    
    public func distanceFrom(coordinate: CLLocationCoordinate2D) -> Double
    {
        var distance = equiRectangularDistanceBetweenCoordinates(self.coordinate2D, otherCoordinate: coordinate)
        
        if distance > 6000.0 {
            distance = haversineDistanceBetweenCoordinates(self.coordinate2D, otherCoordinate: coordinate)
        }
        
        return distance
    }

}

public class QTRBBox: CustomStringConvertible {
    public var lowLatitude: Double
    public var highLatitude: Double
    public var lowLongitude: Double
    public var highLongitude: Double
    
    public var center: CLLocationCoordinate2D {
        get {
            return centerOfBoundingBox([self.lowLongitude, self.lowLatitude, self.highLongitude, self.highLatitude])
        }
    }
    var span: QTRSpan
    
    public var description: String {
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
    
    public init (_ bbox: [CLLocationDegrees]) {
        self.lowLatitude = bbox[1]
        self.highLatitude = bbox[3]
        self.lowLongitude = bbox[0]
        self.highLongitude = bbox[2]
        self.span = QTRSpan(bbox)
    }
    
    public convenience init (_ midpoint: CLLocationCoordinate2D, _ radius: Double) {
        self.init(bboxAroundCoordinate(midpoint, withDistance: radius))
    }
    
    public func centerOfBoundingBox(bbox: [CLLocationDegrees]) -> CLLocationCoordinate2D
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
    
    private func asArray() -> [CLLocationDegrees] {
        return [self.lowLongitude, self.lowLatitude, self.highLongitude, self.highLatitude]
    }
    
    public func containsCoordinate(coordinate: CLLocationCoordinate2D ) -> Bool
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
    
    public func intersects(boundingBox bbox: QTRBBox) -> Bool
    {
        if !(sgn(self.highLongitude == 0.0 ? self.highLongitude + 0.1E6 : self.highLongitude) == sgn(self.lowLongitude == 0.0 ? self.lowLongitude + 0.1E6 : self.lowLongitude)) || !(self.lowLongitude < self.highLongitude) {
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

public class QTRNode: CustomStringConvertible {
    var ne: QTRNode?
    var se: QTRNode?
    var sw: QTRNode?
    var nw: QTRNode?
    
    public weak var parent: QTRNode?
    
    var bbox: QTRBBox
    var bucketCapacity: Int
    
    public var points: Array<QTRNodePoint>
    
    public var size: Int {
        return self.points.count
    }
    
    public var isLeaf: Bool {
        return self.ne == nil
    }
    
    public var description: String {
        return "\(size), \(ne), \(se), \(sw), \(se)"
    }
    
    public init (_ bbox: QTRBBox, _ bucketCapacity: Int) {
        self.bbox = bbox
        self.points = []
        self.bucketCapacity = bucketCapacity
    }
    
    public convenience init (_ points: [QTRNodePoint], _ bbox: QTRBBox, _ bucketCapacity: Int) {
        self.init(bbox, bucketCapacity)
        for p: QTRNodePoint in points {
            self.insert(p)
        }
    }
    
    private func split() {
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
    
    public func insert(point: QTRNodePoint) -> Bool {
        if !self.bbox.containsCoordinate(point.coordinate2D) && self.ne == nil {
            return false
        }
        
        if self.size < self.bucketCapacity && self.ne == nil {
            self.points.append(point)
            return true
        }
        
        if self.ne == nil  {
            self.split()
        }
        
        if self.ne!.insert(point) { return true }
        if self.se!.insert(point) { return true }
        if self.sw!.insert(point) { return true }
        if self.nw!.insert(point) { return true }
        
        return false
    }
    
    public func get(pointsIn range: QTRBBox, andApply map: (QTRNodePoint) -> ()) {
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
    
    public func traverse(andApply map: (QTRNode) -> ()) {
        map(self)
        
        if self.ne == nil {
            return
        }
        
        self.ne?.traverse(andApply: map)
        self.se?.traverse(andApply: map)
        self.sw?.traverse(andApply: map)
        self.nw?.traverse(andApply: map)
    }
    
    public func getByTraversingUp(pointsIn range: QTRBBox, andApply map: (QTRNodePoint) -> ()) {
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
    
    public func traverseUp(andApply map: (QTRNode) -> ()) {
        map(self)
        
        if self.parent == nil {
            return
        }
        
        self.parent?.traverseUp(andApply: map)
    }
    
    public func nodeContaining(point: QTRNodePoint) -> QTRNode? {
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
