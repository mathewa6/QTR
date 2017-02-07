QTR
===

A simple QuadTree in Swift, along with some useful tools to help create and work with a spatial index. 

Some code based on pseudocode from [Wikipedia](http://en.wikipedia.org/wiki/Quadtree)


##Usage##

- Create a `QTRNodePoint`object for User.
- Create a `QTRBBox` with the bounding box for the total area to be searched. (**TODO**: Update this to be calculated based on the input data.)
- Create an Array of `QTRNodePoint` for locations/landmarks.
- Initialize `QTRNode` with the above array and set the number of points in each bucket.
- Call nearestNeighbours() to query the QuadTree.

```swift
let userPoint: QTRNodePoint = QTRNodePoint(longitude, latitude, name)
let bbox: QTRBBox = QTRBBox(withArray: boundingArray)
let pointArray: [QTRNodePoint] = [pointa, pointb, pointc]

let node: QTRNode? = QTRNode(pointArray, bbox, bucketCount)

// Traverses the tree and prints elements in nodes that are closest to userPoint.
nearestNeighboursAlternate(toPoint: userPoint, startingAt: node!, canUseParent: true, andApply: { (nd: QTRNodePoint) -> () in
    print(nd.name)
})

```

##Note##

**QuadTree.swift** : Last tested in Xcode 7.2.1

**QuadTree.playground** : Contains an updated, more concise QuadTree that uses Swift 3. Last tested in Xcode 8.2.1.


##License##
See included LICENSE file.