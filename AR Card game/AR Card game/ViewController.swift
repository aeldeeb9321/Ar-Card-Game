//
//  ViewController.swift
//  AR Card game
//
//  Created by Ali Eldeeb on 9/20/22.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController {
    //MARK: - Properties
    
    @IBOutlet var arView: ARView!
    var cards: [Entity] = []
    var cancelable: AnyCancellable? = nil
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        cardSetup()
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
         
    }
    
    //MARK: - Helpers
    
    func cardSetup(){
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.4, 0.4])
        
        //creating our 12 cards
        for _ in 1...12{
            let box = MeshResource.generateBox(width: 0.06, height: 0.01, depth: 0.08)
            let material = SimpleMaterial(color: .systemIndigo, isMetallic: true)
            let model = ModelEntity(mesh: box, materials: [material])
            //To press on these boxes/ cards we generate collisionshapes so we can touch these objects
            model.generateCollisionShapes(recursive: true)
            cards.append(model)
        }
        
        //positioning our cards
        for (index,card) in cards.enumerated(){
            let x = Float(index % 4) - 1.5  //we used mod so the x goes from 0 to 3 alternating and we just have the z axis as the column
            let z = Float(index / 4) - 1.5
            card.position = [x*0.1, 0, z*0.1] //we multiplied it by 0.1 since its in meters I lowered the number so it isnt far away
            //adding the card as a child of the anchor
            anchor.addChild(card)
        }
        
        //creating an occlusion box- An invisible box that hides objects rendered behind it.
        let boxSize: Float = 0.7
        let occlusionBoxMesh = MeshResource.generateBox(size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])
        occlusionBox.position.y = -boxSize/2
        anchor.addChild(occlusionBox)
        
        //sink gives us a subscriber to our load request and allows us to use a closure that runs when the asset has loaded.
         // this ensures our load request is not deallocated until it is no longer need
        //loadModel asynchronously loads a request, works like a publisher in combine
        cancelable = ModelEntity.loadModelAsync(named: "01")
            .append(ModelEntity.loadModelAsync(named: "02"))
            .append(ModelEntity.loadModelAsync(named: "03"))
            .append(ModelEntity.loadModelAsync(named: "04"))
            .append(ModelEntity.loadModelAsync(named: "05"))
            .append(ModelEntity.loadModelAsync(named: "06"))
            .collect() //Collects all received elements, and emits a single array of the collection when the upstream publisher finishes.
            .sink(receiveCompletion: { [weak self] error in
                print("Error: \(error)")
                self?.cancelable?.cancel()
            }, receiveValue: { entities in
                //scale them down, generate collision shapes
                var objects: [ModelEntity] = []
                
                for entity in entities{
                    entity.setScale(SIMD3<Float>(0.002,0.002,0.002), relativeTo: anchor)
                    entity.generateCollisionShapes(recursive: true)
                    for _ in 1...2{
                        objects.append(entity.clone(recursive: true))
                    }
                }
                
                objects.shuffle() //shuffles the collection in place
                
                for (index, object) in objects.enumerated(){
                    self.cards[index].addChild(object)
                    //rotated it so we dont see models when app starts
                    self.cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
                }
                // When implementing Cancellable in support of a custom publisher, implement cancel() to request that your publisher stop calling its downstream subscribers. Canceling should also eliminate any strong references it currently holds.
                self.cancelable?.cancel()
                
            })
        
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
    
    //MARK: - Selectors
    
    //When the user taps the card it flipts, if its already been flipped we flip it the other way
    @objc func handleTap(sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: arView)
        //arView.entity gets the closest entity in the AR scene at the specified point on screen. So below we are checking if the entity is at the tap location and if it is we will rotate it, if its already rotated then we flip it down.
        if let card = arView.entity(at: tapLocation){
            if card.transform.rotation.angle ==  .pi{ //the card is already rotated 180 degrees
                var flipDownTransform = card.transform //start with the current transform card has
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1,0,0]) //since its already flipped we want to make the angle 0 so we can make it vertical again to flip
                //.move method moves an entity over a period of time to a new location given by a transform.
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
