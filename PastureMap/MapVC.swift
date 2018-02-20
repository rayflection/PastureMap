//
//  FirstViewController.swift
//  PastureMap
//
//  Created by Mike Yost on 2/19/18.
//  Copyright © 2018 CageFreeSoftware. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var createPastureButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var summaryLabel: UILabel!
    
    var tapRecognizer:UITapGestureRecognizer?
    var inPolygonMode=false
    var pasture = Pasture()           // yeah, throw one away, curse these obnoxionals
    var finishPolygonButton:UIButton?
    var pastureList:[Pasture]=[]
    let locationManager = CLLocationManager()
    
    // -----------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }
    func configUI() {
        configMap()
        //spinner.isHidden = true
        topLabel.text = ""
        bottomLabel.text = ""
        summaryLabel.text = ""
    }

    func configMap() {
        mapView.showsUserLocation = true
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        fetchCurrentLoc()
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
    func fetchCurrentLoc() {
        locationManager.requestWhenInUseAuthorization()
    }

    // --------------------------------------------
    // MARK: - button event handlers
    @IBAction func createPastureButtonTapped(_ sender: UIButton) {
        inPolygonMode = true
        sender.isEnabled = false
        pasture = Pasture()
        pastureList.append(pasture)
        if let tapRec = tapRecognizer {
            mapView.addGestureRecognizer(tapRec)
        }
        topLabel.text = "Tap the map to create a fence post"
        bottomLabel.text = ""
        //
        // @TODO: change button text to "Cancel", detect Cancel, delete pasture, wipe map.
        //
    }
    @objc func finishPolygonButtonTapped() {
        NSLog("Poly Origin Tapped - POLYGON COMPLETE!")
        if inPolygonMode {
            
            if let firstPost = finishPolygonButton?.superview as? MKAnnotationView {
                firstPost.image = UIImage(named:"fencePost")
            }
            renderCompletePolygon()
            pasture.isComplete = true

            finishPolygonButton?.isEnabled = false
            createPastureButton.isEnabled = true
            inPolygonMode = false
        }
    }
    @IBAction func optionsMenuTapped(_ sender: UIButton) {
        self.present(OptionsHandler().getOptionsMenuActionSheet(sender,mapView), animated:true, completion:nil)
    }
    // --------------------------------------------
    // MARK: - MapView Delegate
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 5000.0, 5000.0)
        mapView.setRegion(region , animated: true)
        displayCoordinates(coord: mapView.userLocation.coordinate, what: "User loc" )
        perform(#selector(disableLocationManager), with: nil, afterDelay: 5.0)  // time for a couple of updates.
    }
    @objc func disableLocationManager() {
        locationManager.stopUpdatingLocation()
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        for pasture in pastureList {
            displayAreaInsidePolygon(pasture: pasture)
        }
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.ending || newState == MKAnnotationViewDragState.canceling {
            view.dragState = MKAnnotationViewDragState.none
            if let coo = view.annotation?.coordinate, let name = view.annotation?.title! {
                displayCoordinates(coord:coo, what:name)
                if name.isEqual("fence post") {     // @TODO - need better way to detect, by type or tag or class..
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
        if annotation is MKUserLocation {
            return nil
        }
        if annotation is MKPointAnnotation {
            // Distinguish a polygon touchPoint from any other annotations we might add later
            let touchPointView = MKAnnotationView(annotation:annotation, reuseIdentifier: "touchPoint")
            if let title = annotation.title!, title.isEqual("fence post") {
                touchPointView.image = UIImage(named:"fencePost")
                if pasture.polygonVertices.count == 1 {
                    touchPointView.image = UIImage(named:"fencePostYellow")
                    // add a button to this view which allows user to complete the polygon
                    finishPolygonButton = UIButton(type:.custom)
                    finishPolygonButton?.frame = touchPointView.bounds  // make me bigger, more visual
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
            return PolylineRendererFactory.rendererFor(overlay:overlay)
        } else if overlay is MKPolygon {
            return PolygonRendererFactory.rendererFor(overlay: overlay)
        }
        return MKPolylineRenderer(overlay: overlay) // placeholder until I get the SHAPE
    }
    // ---------------------------------------------
    // MARK: - Polygon handlers
    func addToPolygon(coord: CLLocationCoordinate2D, isComplete:Bool) {
        let polyAnnotation = MKPointAnnotation()
        polyAnnotation.coordinate = coord
        polyAnnotation.title = "fence post"
        pasture.polygonVertices.append(polyAnnotation)
        if polygonVerticesAreValid(pasture.polygonVertices) {
            if !isComplete {
                mapView.addAnnotation(polyAnnotation)
            }
        }
        renderMostRecentTwoFencePosts(pasture:pasture)
        finishPolygonButton?.isEnabled = pasture.polygonVertices.count > 2
    }
    func renderMostRecentTwoFencePosts(pasture:Pasture) {
        if pasture.polygonVertices.count < 2 { return }
        
        // draw a line between the last 2 vertices
        let p1 = pasture.polygonVertices[pasture.polygonVertices.count-2].coordinate
        let p2 = pasture.polygonVertices[pasture.polygonVertices.count-1].coordinate
        let line = MKPolyline(coordinates: [p1,p2], count: 2)
        mapView.addOverlays([line])
        pasture.polylines.append(line)
        
        LineLengthRenderer.display(p1, p2, bottomLabel)
    }
    func renderIncompletePolygon() {
        renderPolygonWith(title:"Poly", subtitle:"incomplete")
    }
    func renderCompletePolygon() {
        renderPolygonWith(title:"Poly", subtitle:"complete")     // title doesn't show
        topLabel.text = "Select and drag a fence post to reposition it."
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
        displayAreaInsidePolygon(pasture: pasture)

        if pasture.isComplete {
            topLabel.text = ""
        } else {
            if corners.count > 2 {
                topLabel.text = "Tap again, or tap the yellow post to complete the pasture."
            } else {
                topLabel.text = "Tap again to make the next one..."
            }
        }
    }
    func redrawPasture(pasture:Pasture) {
        if ( pasture.polylines.count > 0 ) {
            mapView.removeOverlays(pasture.polylines)
        }
        renderCompletePolygon()
    }
    func displayAreaInsidePolygon(pasture:Pasture) {

        PastureRenderer.displayAcreageLabel(pasture: pasture, mapView: mapView)
        if pasture.polygonVertices.count > 2 {
            PastureSummaryRenderer.updateSummary(pastureList,summaryLabel)
        }
    }
    func polygonVerticesAreValid(_ vertices:[MKPointAnnotation]) -> Bool {
        if pasture.polygonVertices.count < 4 {
            return true
        }
        // @TODO: if any lines cross, return false
        //   show some kind of error - leave the fencepost there?  how to handle this?
        
        return true
    }
    // -------------------------
    // MARK: - Utils
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
