//
//  FirstViewController.swift
//  PastureMap
//
//  Created by Mike Yost on 2/19/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var createPastureButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var tapRecognizer:UITapGestureRecognizer?
    var inPolygonMode=false
    var pasture = Pasture()           // yeah, throw one away, curse these obnoxionals
    var finishPolygonButton:UIButton?
    var pastureList:[Pasture]=[]
    
    // -----------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }
    func configUI() {
        configMap()
        //spinner.isHidden = true
    }
    func configMap() {
        mapView.setRegion(getRegion(), animated: true)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
    }
    @objc func singleTap(sender:UITapGestureRecognizer) {
        if sender.state == .ended {
            NSLog("DID TAP")
            let point = sender.location(in: mapView)
            let touchLatLon = mapView.convert(point, toCoordinateFrom: mapView)
            //bottomLabel.text = "Got a tap at \(point.to_s()),\(touchLatLon.to_s())"
            if inPolygonMode {
                addToPolygon(coord: touchLatLon, isComplete: false)
                renderIncompletePolygon()
            }
        }
    }

    // --------------------------
    // @TODO - get current loc from CLLocationManager, asynchronously
    func getRegion() -> MKCoordinateRegion {
        let defaultXdelta = 5000.0
        let defaultYdelta = 5000.0
        return MKCoordinateRegionMakeWithDistance(getDefaultLoc(), defaultXdelta, defaultYdelta)
    }
    func getDefaultLoc() -> CLLocationCoordinate2D {
        let defaultLAT = 39.4
        let defaultLON = -77.8
        return CLLocationCoordinate2DMake(defaultLAT, defaultLON)
    }
    
    // --------------------------------------------
    // MARK: button event handlers
    @IBAction func createPastureButtonTapped(_ sender: UIButton) {
        inPolygonMode = true
        sender.isEnabled = false
        pasture = Pasture()
        pastureList.append(pasture)
        if let tapRec = tapRecognizer {
            mapView.addGestureRecognizer(tapRec)
        }
    }
    @objc func finishPolygonButtonTapped() {
        NSLog("Poly Origin Tapped - POLYGON COMPLETE!")
        if inPolygonMode {
            addToPolygon(coord: pasture.polygonVertices[0].coordinate, isComplete: true)
            renderCompletePolygon()
            pasture.polygonVertices.removeLast()
            finishPolygonButton?.isEnabled = false
            createPastureButton.isEnabled = true
            inPolygonMode = false
        }
    }
    
    // --------------------------------------------
    // MARK: MapView Delegate
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.ending || newState == MKAnnotationViewDragState.canceling {
            view.dragState = MKAnnotationViewDragState.none
            if let coo = view.annotation?.coordinate, let name = view.annotation?.title! {
                displayCoordinates(coord:coo, what:name)
                if name.isEqual("fence post") {     // need better way to detect, by type or tag or class..
                    if let fencepost = view.annotation as? MKPointAnnotation {
                        if let past = whatPastureIsThisPostIn(post:fencepost) {
                            pasture = past
                            redrawPasture(pasture: past)
                        }
                    }
                }
            }
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        NSLog(" View for annoation")
        if annotation is MKPointAnnotation {
            // Distinguish a polygon touchPoint from any other annotations we might add later
            let touchPointView = MKAnnotationView(annotation:annotation, reuseIdentifier: "touchPoint")
            if let title = annotation.title!, title.isEqual("fence post") {
                touchPointView.image = UIImage(named:"fencePost")
                if pasture.polygonVertices.count == 1 {
                    // add a button to this view which completes the polygon
                    finishPolygonButton = UIButton(type:.custom)
                    finishPolygonButton?.frame = touchPointView.bounds
                    finishPolygonButton?.addTarget(self, action: #selector(finishPolygonButtonTapped), for: UIControlEvents.touchUpInside)
                    touchPointView.addSubview(finishPolygonButton!)
                }
            }
            touchPointView.isDraggable = true
            return touchPointView
            
        }
        return nil
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 2.0
            renderer.strokeColor = UIColor.red
            return renderer
        } else if overlay is MKPolygon {
            if let sub = overlay.subtitle! {
                let renderer = MKPolygonRenderer(overlay: overlay)
                if sub.isEqual("complete") {
                    renderer.fillColor = UIColor.green
                } else if sub.isEqual("incomplete") {
                    renderer.fillColor = UIColor.yellow
                }
                renderer.alpha = 0.4
                return renderer
            }
        }
        return MKPolylineRenderer(overlay: overlay) // placeholder until I get the SHAPE
    }
    // ---------------------------------------------
    // MARK: Polygon handlers
    func addToPolygon(coord: CLLocationCoordinate2D, isComplete:Bool) {
        let polyAnnotation = MKPointAnnotation()
        polyAnnotation.coordinate = coord
        polyAnnotation.title = "fence post"
        pasture.polygonVertices.append(polyAnnotation)
        if polygonVerticesAreValid() {
            if !isComplete {
                mapView.addAnnotation(polyAnnotation)
            }
        }
        renderFencePosts()
        
        finishPolygonButton?.isEnabled = pasture.polygonVertices.count > 2
    }
    func renderFencePosts() {
        if pasture.polygonVertices.count < 2 { return }
        
        // draw a line between the last 2 vertices
        let p1 = pasture.polygonVertices[pasture.polygonVertices.count-2]
        let p2 = pasture.polygonVertices[pasture.polygonVertices.count-1]
        let line = MKPolyline(coordinates: [p1.coordinate,p2.coordinate], count: 2)
        mapView.addOverlays([line])
        pasture.polylines.append(line)
        
        let length = p2.coordinate.distanceFrom(p1.coordinate)  // dupe code, see redraw...
        line.title = "\(length) meters"
        bottomLabel.text = line.title
    }
    func renderIncompletePolygon() {
        renderPolygonWith(title:"Poly", subtitle:"incomplete")
    }
    func renderCompletePolygon() {
        renderPolygonWith(title:"Poly", subtitle:"complete")
    }
    func renderPolygonWith(title:String, subtitle:String) {
        if let over = pasture.polygonOverlay {
            mapView.removeOverlays( [over] )
        }
        let corners = pasture.polygonVertices.map { $0.coordinate }
        pasture.polygonOverlay = MKPolygon(coordinates: corners, count: corners.count)
        pasture.polygonOverlay?.title = title
        pasture.polygonOverlay?.subtitle = subtitle
        mapView.addOverlays([pasture.polygonOverlay!])
        
        // calculate area under polygon, display somewhere...
        let area = Pasture.regionArea(locations: corners)
        topLabel.text = "Area is \(area) acres"
        print("\(topLabel.text ?? "")")
    }
    func redrawPasture(pasture:Pasture) {
        if ( pasture.polylines.count > 0 ) {
            mapView.removeOverlays(pasture.polylines)
        }
        var index=0,index2=0
        while index < pasture.polygonVertices.count {
            let p1 = pasture.polygonVertices[index]
            if index == pasture.polygonVertices.count - 1 {
                index2 = 0                       // at last point, draw line to first point
            } else {
                index2 = index+1                 // otherwise, use next point in the array
            }
            let p2 = pasture.polygonVertices[index2]
            let line = MKPolyline(coordinates: [p1.coordinate,p2.coordinate], count: 2)
            mapView.addOverlays([line])
            pasture.polylines.append(line)
            
            let length = p2.coordinate.distanceFrom(p1.coordinate)  // SHOW THIS SOMEWHERE!!
            line.title = "\(length) meters"
            bottomLabel.text = line.title
            
            index += 1
        }
        renderCompletePolygon()
    }
    func polygonVerticesAreValid() -> Bool {
        if pasture.polygonVertices.count < 4 {
            return true
        }
        // @TODO: if any lines cross, return false
        //   show some kind of error - leave the fencepost there?  how to handle this?
        return true
    }
    
    // -------------------------
    // MARK: Utils
    func displayCoordinates(coord:CLLocationCoordinate2D, what:String) {
        bottomLabel.text = "\(what) at: \(coord.to_s())"
    }
    func whatPastureIsThisPostIn(post:MKPointAnnotation) -> Pasture? {
        for pasture in pastureList {
            for vertex in pasture.polygonVertices {
                if vertex == post {
                    return pasture
                }
            }
        }
        return nil
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

// ===============================================
// MARK: Extensions
extension CLLocationCoordinate2D {
    func to_s() -> String {
        return "\(String(format: "%.4f", latitude)),  \(String(format: "%.4f", longitude))"
    }
    func distanceFrom(_ coordinate:CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return loc2.distance(from:loc1)
    }
}
