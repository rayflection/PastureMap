//
//  MapVC.swift
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
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!  // button above map, user taps to complete poly.
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!

    
    var tapRecognizer:UITapGestureRecognizer?
    var inPolygonMode=false
    var currentPasture = PastureViewModel()
    var finishPolygonButton:UIButton?       // button inside original fence post, user taps to complete poly.
    var pastureList:[PastureViewModel]=[]
    let locationManager = CLLocationManager()
    
    @IBAction func LoadDataTapped(_ sender: UIBarButtonItem) {
        print("Got Load")
        let pdl = PastureDataLoader()
        pdl.go(self)
    }
    // -----------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }
    func configUI() {
        configMap()
        //spinner.isHidden = true
        clearLabels()
        resetButtonsToDefaultState()
    }

    func configMap() {
        mapView.showsUserLocation = true
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        fetchCurrentUserLoc()
    }
    @objc func singleTap(sender:UITapGestureRecognizer) {
        if sender.state == .ended {
            NSLog("DID TAP")
            let point = sender.location(in: mapView)
            let touchLatLon = mapView.convert(point, toCoordinateFrom: mapView)
            //bottomLabel.text = "Got a tap at \(point.to_s()),\(touchLatLon.to_s())"
            if inPolygonMode {
                addToPolygon(pasture: currentPasture, coord: touchLatLon, isComplete: false)
            }
        }
    }

    // --------------------------
    func fetchCurrentUserLoc() {
        locationManager.requestWhenInUseAuthorization()
    }

    // --------------------------------------------
    // MARK: - button event handlers
    @IBAction func createPastureButtonTapped(_ sender: UIButton) {
        inPolygonMode = true
        createPastureButton.isEnabled = false
        finishButton.isHidden = false
        cancelButton.isHidden = false
        finishButton.isEnabled = false      // don't enable until we have at least 3 corners
        currentPasture = PastureViewModel()
        pastureList.append(currentPasture)
        if let tapRec = tapRecognizer {
            mapView.addGestureRecognizer(tapRec)
        }
        topLabel.text = "Tap the map to create a fence post"
        bottomLabel.text = ""
    }
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        clearPolylines(currentPasture)
        clearOverlays(currentPasture)
        clearFencePosts(currentPasture)
        pastureList.removeLast()
        currentPasture.clear()
        resetButtonsToDefaultState()
        showSelectAndDragMessage()
    }
    @IBAction func finishButtonTapped(_ sender: UIButton) {
        finishPolygonButtonTapped()
    }
    @objc func finishPolygonButtonTapped() {
        NSLog("Poly Origin Tapped - POLYGON COMPLETE!")
        if inPolygonMode {
            
            if let firstPost = finishPolygonButton?.superview as? MKAnnotationView {
                firstPost.image = UIImage(named:"fencePost")
            }
            if let finish = finishPolygonButton {
                finish.removeFromSuperview()
            }
            DBManager.shared().createPasture(currentPasture)
            
            renderCompletePolygon(currentPasture)
            resetButtonsToDefaultState()
        }
    }
    func resetButtonsToDefaultState() {
        finishButton.isHidden = true
        cancelButton.isHidden = true
        createPastureButton.isEnabled = true
        inPolygonMode = false
    }
    func clearLabels() {
        topLabel.text = ""
        bottomLabel.text = ""
        summaryLabel.text = ""
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
                            currentPasture = past
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
                if let postAnnotation = annotation as? MKPointAnnotation {
                    if let pasture = whatPastureIsThisPostIn(post:postAnnotation) {
                        if pasture.polygonVertices.count == 1 {
                            touchPointView.image = UIImage(named:"fencePostYellow")
                            // add a button to this view which allows user to complete the polygon
                            finishPolygonButton = UIButton(type:.custom)
                            finishPolygonButton?.frame = touchPointView.bounds  // make me bigger, more visual
                            finishPolygonButton?.addTarget(self, action: #selector(finishPolygonButtonTapped), for: UIControlEvents.touchUpInside)
                            touchPointView.addSubview(finishPolygonButton!)
                        }
                    }
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
    func addToPolygon(pasture: PastureViewModel, coord: CLLocationCoordinate2D, isComplete:Bool) {
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
        if let finish = finishPolygonButton {
            finish.isEnabled = pasture.polygonVertices.count > 2
        }
        finishButton.isEnabled = pasture.polygonVertices.count > 2
        
        renderIncompletePolygon(pasture)
    }
    func renderMostRecentTwoFencePosts(pasture:PastureViewModel) {
        if pasture.polygonVertices.count < 2 { return }
        
        // draw a line between the last 2 vertices
        let p1 = pasture.polygonVertices[pasture.polygonVertices.count-2].coordinate
        let p2 = pasture.polygonVertices[pasture.polygonVertices.count-1].coordinate
        let line = MKPolyline(coordinates: [p1,p2], count: 2)
        mapView.addOverlays([line])
        pasture.polylines.append(line)
        
        LineLengthRenderer.display(p1, p2, bottomLabel)
    }
    func renderIncompletePolygon(_ pasture:PastureViewModel) {
        renderWith(pasture, "Poly", "incomplete")
    }
    func renderCompletePolygon(_ pasture:PastureViewModel) {
        renderWith(pasture, "Poly", "complete")     // title doesn't show, find another way
        showSelectAndDragMessage()
    }
    func showSelectAndDragMessage() {
        if pastureList.count > 0 {
            topLabel.text = "Select and drag a fence post to reposition it."
        } else {
            topLabel.text = ""
        }
    }
    func renderWith(_ pasture:PastureViewModel,_ title:String,_ subtitle:String) {
        clearOverlays(pasture)
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
                topLabel.text = "Tap again, or to complete the pasture, tap the yellow post or tap Finsih."
            } else {
                topLabel.text = "Tap again to make the next one..."
            }
        }
    }
    func redrawPasture(pasture:PastureViewModel) {
        clearPolylines(pasture)
        renderCompletePolygon(pasture)
    }
    func clearOverlays(_ pasture:PastureViewModel) {
        if let over = pasture.polygonOverlay {
            mapView.removeOverlays( [over] )
        }
    }
    func clearPolylines(_ pasture:PastureViewModel) {
        if ( pasture.polylines.count > 0 ) {
            mapView.removeOverlays(pasture.polylines)
        }
    }
    func clearFencePosts(_ pasture:PastureViewModel) {
        mapView.removeAnnotations(pasture.polygonVertices)
    }
    func displayAreaInsidePolygon(pasture:PastureViewModel) {

        PastureRenderer.displayAcreageLabel(pasture: pasture, mapView: mapView)
        if pasture.polygonVertices.count > 2 {
            PastureSummaryRenderer.updateSummary(pastureList,summaryLabel)
        }
    }
    func polygonVerticesAreValid(_ vertices:[MKPointAnnotation]) -> Bool {
        if vertices.count < 4 {
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
    func whatPastureIsThisPostIn(post:MKPointAnnotation) -> PastureViewModel? {
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
