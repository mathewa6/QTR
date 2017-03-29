//
//  QuadTree.playground
//
//  Created by Adi Mathew on 3/16/16.
//  Copyright (c) 2016 RCPD. All rights reserved.
//

import Foundation
import MapKit
import PlaygroundSupport

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T, rhs: T) -> Bool {
  switch (lhs, rhs) {
  case let (l, r):
    return l < r
  }
}

//var node: QTRNode? = QTRNode(QTRBBox([ -116,19,-53,72 ]),4)
let userPoint = QTRNodePoint(-84.477949, 42.725222 ,"userPoint")
//let userBox = QTRBBox(userPoint.coordinate2D, 92.0)

let randomBox = QTRBBox(withArray: [ -84.5035622, 42.7127855, -84.4550801, 42.7367203 ])
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

func zoomLevel(fromScale scale: MKZoomScale) -> Int {
    let tileCount = MKMapSizeWorld.width / 256.0
    let zoomLevelMax = log2(tileCount)
    let zoomLevel = max(0, zoomLevelMax + Double(floor(log2(scale) + 0.5)))
    
    return Int(zoomLevel)
}

func cellSize(fromScale scale: MKZoomScale) -> Double {
    let level = zoomLevel(fromScale: scale)
    
    switch level {
    case 13,14,15:
        return 64.0
    case 16,17,18:
        return 32.0
    case 19:
        return 16.0
    default:
        return 88.0
    }
}

func clusteredAnnotations(in rect: MKMapRect,
                          atScale zoomScale: Double,
                          fromNode node: QTRNode) -> [MKAnnotation] {
    let size = cellSize(fromScale: MKZoomScale(zoomScale))
    let scaleFactor = zoomScale/size
    
    let minX: Double = floor(MKMapRectGetMinX(rect) * scaleFactor)
    let maxX: Double = floor(MKMapRectGetMaxX(rect) * scaleFactor);
    let minY = floor(MKMapRectGetMinY(rect) * scaleFactor);
    let maxY = floor(MKMapRectGetMaxY(rect) * scaleFactor);
    
    var annotations: [MKAnnotation] = []
    
    for x in stride(from: minX, through: maxX, by: 1.0) {
        for y in stride(from: minY, through: maxY, by: 1.0) {
            let mapRect: MKMapRect = MKMapRectMake(x/scaleFactor,
                                                   y/scaleFactor,
                                                   1.0/scaleFactor,
                                                   1.0/scaleFactor)
            var totalX = 0.0, totalY = 0.0, count = 0
            let box: QTRBBox = QTRBBox(forMapRect: mapRect)
            node.get(pointsIn: box,
                     andApply: { (point) in
                        totalX += point.coordinate.latitude
                        totalY += point.coordinate.longitude
                        count += 1
            })
            
            if count >= 1 {
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: totalX/Double(count),
                                                                                longitude: totalY/Double(count))
                let anno = QTRNodePoint(coordinate, String(count))
                annotations.append(anno)
            }
        }
    }
    
    return annotations
}


class QTRNodePointView: MKAnnotationView {
    
    private var countLabel: UILabel = UILabel(frame: .zero)
    
    public var count: Int = 0 {
        didSet {
            let newBounds: CGRect = CGRect(x: 0,
                                           y: 0,
                                           width: CGFloat(roundf(44.0 * scaledSize(forValue: self.count))),
                                           height: CGFloat(roundf(44.0 * scaledSize(forValue: self.count))))
            self.frame = centeredRect(forRect: newBounds, center: self.center)
            
            let newLabelBounds: CGRect = CGRect(x: 0,
                                                y: 0,
                                                width: newBounds.size.width/1.3,
                                                height: newBounds.size.height/1.3)
            self.countLabel.frame = centeredRect(forRect: newLabelBounds, center: CGPoint(x: newBounds.midX,
                                                                                          y: newBounds.midY))
            self.countLabel.text = String(self.count)
            
            self.setNeedsDisplay()
        }
    }
    
    private let alphax: Float = 0.3
    private let betax: Float = 0.4
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func centeredRect(forRect rect: CGRect, center: CGPoint) -> CGRect {
        return CGRect(x: center.x - rect.size.width/2.0,
                      y: center.y - rect.size.height/2.0,
                      width: rect.size.width,
                      height: rect.size.height)
    }
    
    private func scaledSize(forValue value: Int) -> Float {
        return 1.0/(1.0 + expf(-1 * alphax * powf(Float(value), betax)))
    }
    
    private func setup() {
        self.countLabel.frame = self.frame
        self.countLabel.backgroundColor = .clear
        self.countLabel.textColor = .white
        self.countLabel.textAlignment = .center
        self.countLabel.adjustsFontSizeToFitWidth = true
        self.countLabel.numberOfLines = 1
        self.countLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        self.countLabel.baselineAdjustment = .alignCenters
        
        self.addSubview(self.countLabel)
    }
    
    override func draw(_ rect: CGRect) {
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.setAllowsAntialiasing(true)
        
        let outerCircleStrokeColor: UIColor = UIColor(white: 0, alpha: 0.25)
        let innerCircleStrokeColor: UIColor = .white
        let innerCircleFillColor: UIColor = UIColor(red: 1.0, green: 95.0/255.0, blue: 42.0/255.0, alpha: 1.0)
        
        let circleFrame: CGRect = rect.insetBy(dx: 4.0, dy: 4.0)
        ctx.setStrokeColor(outerCircleStrokeColor.cgColor)
        ctx.setLineWidth(5.0)
        ctx.strokeEllipse(in: circleFrame)
        
        ctx.setStrokeColor(innerCircleStrokeColor.cgColor)
        ctx.setLineWidth(4.0)
        ctx.strokeEllipse(in: circleFrame)
        
        ctx.setFillColor(innerCircleFillColor.cgColor)
        ctx.fillEllipse(in: circleFrame)
    }
}

func update(mapView map: MKMapView, annotations: [QTRNodePoint]) {
    var before = Set<QTRNodePoint>(map.annotations as! [QTRNodePoint])
    let after = Set<QTRNodePoint>(annotations)
    
    var keep = Set(before)
    keep.intersection(after)
    
    var add = Set(after)
    add.subtract(keep)
    
    var remove = Set(before)
    remove.subtract(after)
    
    DispatchQueue.main.async {
//        map.removeAnnotations(map.annotations)
        map.addAnnotations(Array(add))
        map.removeAnnotations(Array(remove))
    }
}

func addBounceAnimation(toView view: UIView) {
    let bounce = CAKeyframeAnimation(keyPath: "transform.scale")
    bounce.values = [0.05, 1.1, 0.9, 1.0]
    bounce.duration = 0.6
    
    var timingFunctions: [CAMediaTimingFunction] = []
    
    for _ in 0..<4 {
        timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
    }
    bounce.timingFunctions = timingFunctions
    bounce.isRemovedOnCompletion = false
    
    view.layer.add(bounce, forKey: "bounce")
}

class TestDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapView.removeAnnotations(mapView.annotations)
        DispatchQueue.global(qos: .default).async {
            let scale = Double(mapView.bounds.size.width)/mapView.visibleMapRect.size.width
            zoomLevel(fromScale: MKZoomScale(scale))
            let annos = clusteredAnnotations(in: mapView.visibleMapRect, atScale: scale, fromNode: node!)
            update(mapView: mapView, annotations: annos as! [QTRNodePoint])
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let r = QTRNodePointView()
        let x = annotation as! QTRNodePoint
        r.count = Int(x.name)!
        
        return r
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            addBounceAnimation(toView: view)
        }
    }
}

let frame: CGRect = CGRect(x: 0, y: 0, width: 360, height: 360)
let map: MKMapView = MKMapView(frame: frame)
let region: MKCoordinateRegion = MKCoordinateRegion(center: userPoint.coordinate,
                                                    span: (node?.bbox.span.mapKitSpan)!)
let delegate: TestDelegate = TestDelegate()

map.region = region
map.delegate = delegate
// map.addAnnotations(pointArray)

let scale = Double(map.bounds.size.width)/map.visibleMapRect.size.width
zoomLevel(fromScale: MKZoomScale(scale))
let annos = clusteredAnnotations(in: map.visibleMapRect, atScale: scale, fromNode: node!)
map.addAnnotations(annos)

PlaygroundPage.current.liveView = map
