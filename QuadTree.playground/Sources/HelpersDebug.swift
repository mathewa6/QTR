import Foundation
import CoreLocation

//Basic Conversion functions.From DSAlgorithm.
public func radianToDegrees(radians: Double) -> Double {
    return (radians * (180/M_PI))
}

public func degreesToRadians(degrees: Double) -> Double {
    return (degrees * (M_PI/180))
}

/// - Returns 1/-1 for non  zero values.
/// - Returns 0 for error
///
public func sgn(value: Double) -> Int {
    if value == 0 {
        return 0
    }
    return Int(abs(value)/value)
}

/// Returns a box around a given coordinate with a normalized distance as it's side.
/// 
/// - note: The return array is formatted as [lowLongitude, lowLatitude, highLongitude, highLatitude]
/// - returns: An array of CLLocationDegrees.
public func bboxAroundCoordinate(coordinate: CLLocationCoordinate2D, withDistance distance: CLLocationDistance) -> [CLLocationDegrees] {
    let MIN_LAT = -M_PI_2
    let MAX_LAT = M_PI_2
    let MIN_LONG = -M_PI
    let MAX_LONG = M_PI
    
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
                longMin += 2.0 * M_PI
            }
            
            longMax = longRadian + deltaLong
            if longMax > MAX_LONG {
                longMax -= 2.0 * M_PI
            }
        }
        else {
            latMin = max(latMin, MIN_LAT)
            latMax = min(latMax, MAX_LAT)
            longMin = MIN_LONG
            longMax = MAX_LONG
        }
        
        return [longMin, latMin, longMax, latMax].map{
            (rads) -> CLLocationDegrees in
            return radianToDegrees(rads)
        }
        
    }
    
    return []
}

/// Returns a box around a given coordinate using the given span struct to calculate bounds.
///
/// - note: The return array is formatted as [lowLongitude, lowLatitude, highLongitude, highLatitude]
/// - returns: An array of CLLocationDegrees.
public func bboxAroundCoordinate(coordinate: CLLocationCoordinate2D, withSpan span: QTRSpan) -> [CLLocationDegrees] {
    if CLLocationCoordinate2DIsValid(coordinate) {
        let latitudeRadius = span.latitudeDelta/2.0
        let longitudeRadius = span.longitudeDelta/2.0
        
        //Check for wraparound cases. i.e 180 +/- x
        
        let latMin = coordinate.latitude - latitudeRadius
        let latMax = coordinate.latitude + latitudeRadius
        let longMin = coordinate.longitude - longitudeRadius
        let longMax = coordinate.longitude + longitudeRadius
        return [longMin, latMin, longMax, latMax]
    }
    
    return []
}

public func haversineDistanceBetweenCoordinates(coordinate: CLLocationCoordinate2D, otherCoordinate: CLLocationCoordinate2D) -> Double
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

public func equiRectangularDistanceBetweenCoordinates(coordinate: CLLocationCoordinate2D, otherCoordinate: CLLocationCoordinate2D) -> Double {
    let R: Double = 6378137
    let deltaLat = degreesToRadians((otherCoordinate.latitude - coordinate.latitude))
    let deltaLong = degreesToRadians((otherCoordinate.longitude - coordinate.longitude))
    
    let radianLatCoordinate = degreesToRadians(coordinate.latitude)
    let radianLatOther = degreesToRadians(otherCoordinate.latitude)
    
    let x = deltaLong * cos((radianLatCoordinate + radianLatOther)/2.0)
    let y = deltaLat
    
    return R * sqrt(pow(x, 2) + pow(y, 2))
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