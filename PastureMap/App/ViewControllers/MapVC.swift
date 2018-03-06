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

//
// TODO: - prevent polygon overlap, preferrably in real time- detect if any lines cross / polygons overlap
//       - delete last point while creating polygons.
// TODO: Realm db.
// TODO: - cleaner separation, use, purpose for dataModel vs ViewModel, and how they inter-change.
//
class MapVC: UIViewController, MKMapViewDelegate {
    
    var dbi:DataBaseInterface?
    
    @IBOutlet weak var createPastureButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!  // button above map, user taps to complete poly.
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dummyiPadAnchor: UIView!
    
    @IBOutlet weak var mapView: MKMapView!

    var tapRecognizer:UITapGestureRecognizer?
    var inPolygonMode=false
    var currentPasture = PastureViewModel()
    var finishPolygonButton:UIButton?  // button inside original fence post, user taps to complete poly.
    var pastureList:[PastureViewModel]=[]
    let locationManager = CLLocationManager()
    
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
            NSLog("DID TAP - polygonMode is \(inPolygonMode)")
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
    // MARK: - button and event handlers
    @IBAction func createPastureButtonTapped(_ sender: UIButton) {

        currentPasture = PastureViewModel()
        pastureList.append(currentPasture)
        finishUpCreation()
    }
    func installExistingPastureIfNotAlreadyThere(_ data:PastureDataModel) -> Bool {
        var alreadyInstalled = false
        for p in pastureList {
            if p.id == data.pasture_id {
                alreadyInstalled = true
                p.pastureName = data.name
                break
            }
        }
        if !alreadyInstalled {
            currentPasture = PastureViewModel()
            currentPasture.id = data.pasture_id
            pastureList.append(currentPasture)
        }
        
        finishUpCreation()
        
        return alreadyInstalled
    }
    func finishUpCreation() {
        print ("In finishUpCreation() - setting inPolyMode to true from \(inPolygonMode)")
        inPolygonMode = true
        createPastureButton.isEnabled = false
        finishButton.isHidden = false
        cancelButton.isHidden = false
        finishButton.isEnabled = false      // don't enable until we have at least 3 corners
        if let tapRec = tapRecognizer {
            mapView.addGestureRecognizer(tapRec)
        }
        topLabel.text = "Tap the map to create a fence post"
        bottomLabel.text = ""
    }
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        clearPastureGraphics(currentPasture)
        pastureList.removeLast()
        currentPasture.clear()
        resetButtonsToDefaultState()
        showSelectAndDragMessage()
    }
    @IBAction func finishButtonTapped(_ sender: Any) {
        finishPolygonButtonTapped(sender)
    }
    @objc func finishPolygonButtonTapped(_ sender:Any) {
        NSLog("Poly Origin Tapped - POLYGON COMPLETE! - mode is \(inPolygonMode)")
        if inPolygonMode {
            
            if let firstPost = finishPolygonButton?.superview as? MKAnnotationView {
                firstPost.image = UIImage(named:"fencePost")
            }
            if let finish = finishPolygonButton {
                finish.removeFromSuperview()
            }
            if sender is PastureDataModel {
                // generated programmatically by injectPasture
                if let past = sender as? PastureDataModel {
                    currentPasture.pastureName = past.name
                }
            } else {
                // if sender is a UIView - it's from loadTestData
                if let dbi=dbi {
                    dbi.create(currentPasture)
                }
                if sender is UIButton {     // real user interaction
                    promptUserForBetterPastureName(currentPasture)
                }

            }
            
            renderCompletePolygon(currentPasture)
            resetButtonsToDefaultState()
            
            let deleteButtonAnn = AnnotationWithPasture()
            deleteButtonAnn.pasture = currentPasture
            deleteButtonAnn.title = "deleteButton"
            deleteButtonAnn.coordinate = calcDeleteButtonAnnotationLocation(pasture: currentPasture)
            currentPasture.deleteAnnotation = deleteButtonAnn
            mapView.addAnnotation(deleteButtonAnn)
        }
    }
    func calcDeleteButtonAnnotationLocation(pasture:PastureViewModel) -> CLLocationCoordinate2D{
        let endOfSizeLabelLoc = CGPoint(x:pasture.sizeLabel.frame.maxX,
                                        y:(pasture.sizeLabel.frame.maxY +
                                           pasture.sizeLabel.frame.minY)/2.0)
        return mapView.convert(endOfSizeLabelLoc, toCoordinateFrom: mapView)
    }
    func resetButtonsToDefaultState() {
        finishButton.isHidden = true
        cancelButton.isHidden = true
        createPastureButton.isEnabled = true
        inPolygonMode = false
        if let tapRec = tapRecognizer {
            mapView.removeGestureRecognizer(tapRec)
        }
    }
    func clearLabels() {
        topLabel.text = ""
        bottomLabel.text = ""
        summaryLabel.text = ""
    }
    //

    func promptUserForBetterPastureName(_ pasture:PastureViewModel) {
        let ac = UIAlertController (title:"Pasture Name", message:"", preferredStyle: .alert)
        ac.addTextField { (textField) in
            textField.text = pasture.pastureName
        }
        ac.addAction(UIAlertAction(title:"OK", style: .destructive,
                                   handler: {(action) in
                                    if let textField = ac.textFields?.first {
                                        if textField.text != pasture.pastureName {
                                            if let pid=pasture.id, let newName=textField.text, let dbi=self.dbi {
                                                pasture.pastureName = newName
                                                dbi.update(pid, name:newName)
                                                self.renderCompletePolygon(pasture)
                                            }
                                        }
                                    }
        }))
        if UI_USER_INTERFACE_IDIOM() == .pad {
            ac.popoverPresentationController?.sourceView = pasture.sizeLabel
        } else {
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in }))
        }
        self.present(ac, animated:true, completion:nil)
    }
    // ------------------------------------
    // MARK: Menu handlers
    @IBAction func optionsMenuTapped(_ sender: UIButton) {
        self.present(OptionsHandler().getOptionsMenuActionSheet(sender,mapView), animated:true, completion:nil)
    }
    @IBAction func dataMenuTapped(_ sender: UIBarButtonItem) {
        self.present(OptionsHandler().getDataMenuActionSheet(dummyiPadAnchor,self), animated:true, completion: nil)
    }
    func loadPastureDataFromDatabase() {
        PastureDataLoader().loadDataFromDB(self)
    }
    func refreshAllPastures() {
        let _ = pastureList.map { erasePasture($0) }
        loadPastureDataFromDatabase()
    }
    func loadRandomTestData() {
        let pdl = PastureDataLoader()
        pdl.loadTestData(self)
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
        mapView.showsUserLocation = false
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        for pasture in pastureList {
            displayAreaInsidePolygon(pasture: pasture)
        }
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.ending || newState == MKAnnotationViewDragState.canceling {
            view.dragState = MKAnnotationViewDragState.none
            if let coo = view.annotation?.coordinate {
                if let name = view.annotation?.title! {
                    displayCoordinates(coord:coo, what:name)
                }
                if view.annotation is FencePostAnnotation {
                    if let fencepost = view.annotation as? MKPointAnnotation {
                        if let past = whatPastureIsThisPostIn(post:fencepost) {
                            currentPasture = past
                            redrawPasture(pasture: past)
                            if let rank = rankOfAnnotation(post: fencepost, inPasture: past), let pastID = past.id, let dbi=dbi {
                                dbi.update(pastID, rank: rank, coordinate: coo)
                            }
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
            let touchPointView = MKAnnotationView(annotation:annotation, reuseIdentifier: "touchPoint")
            if annotation is FencePostAnnotation {
                touchPointView.image = UIImage(named:"fencePost")
                if let postAnnotation = annotation as? MKPointAnnotation {
                    if let pasture = whatPastureIsThisPostIn(post:postAnnotation) {
                        if pasture.polygonVertices.count == 1 {
                            touchPointView.image = UIImage(named:"fencePostYellow")
                            finishPolygonButton = UIButton(type:.custom)
                            finishPolygonButton?.frame = touchPointView.bounds
                            finishPolygonButton?.addTarget(self, action: #selector(finishPolygonButtonTapped), for: UIControlEvents.touchUpInside)
                            touchPointView.addSubview(finishPolygonButton!)
                        }
                    }
                }
                touchPointView.isDraggable = true
                return touchPointView
            } // fence post
            //
            if let title = annotation.title!, title.isEqual("deleteButton") {
                if annotation is AnnotationWithPasture {
                    let ann =  annotation as! AnnotationWithPasture
                    if let annPasture = ann.pasture {
                        let deleteButton = ButtonWithPasture(type:.custom)
                        deleteButton.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
                        deleteButton.setTitleColor(UIColor.red, for: UIControlState.normal)
                        deleteButton.setTitle("(X)", for: UIControlState.normal)
                        deleteButton.addTarget(self,
                                               action:#selector(deleteButtonTapped),
                                               for:UIControlEvents.touchUpInside)
                        deleteButton.pasture = annPasture
                        
                        let annView = MKAnnotationView()
                        annView.frame = CGRect(x:0,y:0,width:30,height:20)
                        annView.backgroundColor = UIColor.clear
                        annView.addSubview(deleteButton)
                        annView.annotation = annotation
                        return annView
                    }
                }
            }
        }
        return nil
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            return PolylineRendererFactory.rendererFor(overlay:overlay)
        } else if overlay is MKPolygon {
            return PolygonRendererFactory.rendererFor(overlay: overlay)
        }
        return MKPolylineRenderer(overlay: overlay) // placeholder until I need more SHAPEs
    }
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        loadPastureDataFromDatabase()
    }

    @objc func deleteButtonTapped(sender:UIButton) {
        print ("Delete button tapped")
        if let sender = sender as? ButtonWithPasture {
            if let pasture = sender.pasture {
                let ac = UIAlertController (title:"Delete \(pasture.pastureName)?", message:
                    "Really delete this pasture: \(pasture.pastureName)?", preferredStyle: .actionSheet)
                ac.addAction(UIAlertAction(title:"Yes, Delete it!", style: .destructive,
                                           handler: {(action) in
                                            self.deletePasture(pasture) }))
                if UI_USER_INTERFACE_IDIOM() == .pad {
                    ac.popoverPresentationController?.sourceView = sender
                } else {
                    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in }))
                }
                self.present(ac, animated:true, completion:nil)
            }
        }
    }
    func deletePasture(_ pasture: PastureViewModel) {
        if let pk = pasture.id, let dbi=dbi {
            dbi.delete(pk)
            erasePasture(pasture)
        }
    }
    func erasePasture(_ pasture:PastureViewModel) {
        clearPastureGraphics(pasture)
        if let da = pasture.deleteAnnotation {
            mapView.removeAnnotation(da)
        }
        pasture.sizeLabel.removeFromSuperview()
        if let killIndex = pastureList.findIndexOf(pasture) {
            pastureList.remove(at: killIndex)
        }
        PastureSummaryRenderer.updateSummary(pastureList,summaryLabel)
    }
    // ---------------------------------------------
    // MARK: - Polygon handlers
    func addToPolygon(pasture: PastureViewModel, coord: CLLocationCoordinate2D, isComplete:Bool) {
        let polyAnnotation = FencePostAnnotation()
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

        if pasture.isComplete() {
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
    func clearPastureGraphics(_ pasture:PastureViewModel) {
        clearOverlays(pasture)
        clearPolylines(pasture)
        clearFencePosts(pasture)
    }
    func displayAreaInsidePolygon(pasture:PastureViewModel) {
        PastureRenderer.displayAcreageLabel(pasture: pasture, mapView: mapView)
        if pasture.polygonVertices.count > 2 {
            PastureSummaryRenderer.updateSummary(pastureList,summaryLabel)
            if let ann = pasture.deleteAnnotation {
                ann.coordinate = calcDeleteButtonAnnotationLocation(pasture: pasture)
            }
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
    func rankOfAnnotation(post:MKPointAnnotation,inPasture:PastureViewModel) -> Int64? {
        for index in 0..<inPasture.polygonVertices.count {
            if inPasture.polygonVertices[index] == post {
                return Int64(index)
            }
        }
        return nil
    }
}
