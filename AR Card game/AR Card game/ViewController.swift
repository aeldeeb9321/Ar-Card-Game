//
//  ViewController.swift
//  AR Card game
//
//  Created by Ali Eldeeb on 9/20/22.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    var cards: [Entity] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        cardSetup()
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        
    }
    
    func cardSetup(){
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.4, 0.4])

        for _ in 1...12{
            let box = MeshResource.generateBox(width: 0.06, height: 0.01, depth: 0.08)
            let material = SimpleMaterial(color: .systemIndigo, isMetallic: true)
            let model = ModelEntity(mesh: box, materials: [material])
            //Top press on these boxes/ cards we generate collisionshapes so we can touch these objects
            model.generateCollisionShapes(recursive: true)
            cards.append(model)
        }
        
        for (index,card) in cards.enumerated(){
            let x = Float(index % 4) //we used mode so the x goes from 0 to 1 alternating and we just have the z act as the column
            let z = Float(index / 4)
            card.position = [x*0.1, 0, z*0.1] //we multiplied it by 0.1 since its in meters we lowers the number so it isnt far away
            //adding the card as a child of the anchor
            anchor.addChild(card)
        }
        arView.scene.addAnchor(anchor)
        
    }
    
    func setup(){
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.debugOptions = .showAnchorGeometry
        arView.session.run(configuration)
    }
    
    //When the user taps the card it flipts, if its already been flipped we flip it the other way
    @objc func handleTap(sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: arView)
        //arView.entity gets the closest entity in the AR scene at the specified point on screen. So below we are checking if the entity is at the tap location and if it is we will rotate it, if its already rotated then we flip it down.
        if let card = arView.entity(at: tapLocation){
            if card.transform.rotation.angle ==  .pi{ //the card is already rotated 180 degrees
                var flipDownTransform = card.transform //start with the current transform card has
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1,0,0]) //since its already flipped we want to make the angle 0 so we can make it vertical again to flip
                //The timing function that controls the progress of the animation. We are making our card move to the transform we just made
                card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }else{ //if the card hasnt been rotated yet
                var flipUpTransform = card.transform
                flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
                card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
        }
        
    }
}
