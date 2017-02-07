import Foundation
import CoreLocation

//Basic Conversion functions.From DSAlgorithm.
public func radianToDegrees(_ radians: Double) -> Double {
    return (radians * (180/M_PI))
}

public func degreesToRadians(_ degrees: Double) -> Double {
    return (degrees * (M_PI/180))
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
