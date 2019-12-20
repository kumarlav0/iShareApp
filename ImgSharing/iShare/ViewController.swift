//
//  AppDelegate.swift
//  iShare
//
//  Created by Kumar Lav on 19/08/2019.
//
// Email:- kumarstslav@gmail.com

import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var logoImg: UIImageView!
    
    
    var images = [UIImage]()

	var peerID: MCPeerID!
	var mcSession: MCSession!
	var mcAdvertiserAssistant: MCAdvertiserAssistant!

    // it is for collectionView
    let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    var itemsPerRow: CGFloat = 3.1 // Take this value from your desire.
    
    
    
	override func viewDidLoad() {
		super.viewDidLoad()

		title = "iShare"

		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))

		peerID = MCPeerID(displayName: UIDevice.current.name)
		mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
		mcSession.delegate = self
        
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if images.count == 0{
            self.logoImg.isHidden = false
        }
        else{
               self.logoImg.isHidden = true
        }
		return images.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)

		if let imageView = cell.viewWithTag(1000) as? UIImageView {
			imageView.image = images[indexPath.item]
		}

		return cell
	}

    //========================================
      
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
          // here you work out the total amount of space taken up by padding
          // there will be n + 1 evenly sized spaces, where n is the number of items in the row
          // the space size can be taken from the left section inset
          // subtracting this from the view's width and dividing by the number of items in a row gives you the width for each item
          let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
          let availableWidth = view.frame.width - paddingSpace
          let widthPerItem = availableWidth / itemsPerRow
          // return the size as a square
          return CGSize(width: widthPerItem, height: widthPerItem)
      }
      
      // return the spacing between the cells, headers, and footers. Used a constant for that
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
          return sectionInsets
      }
      
      // controls the spacing between each line in the layout. this should be matched the padding at the left and right
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
          return sectionInsets.left
      }
    
    
    
    
    
	@objc func importPicture() {
		let picker = UIImagePickerController()
		picker.allowsEditing = true
		picker.delegate = self
		present(picker, animated: true)
	}

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		guard let image = info[.editedImage] as? UIImage else { return }

		dismiss(animated: true)

		images.insert(image, at: 0)
		collectionView?.reloadData()

		// 1
		if mcSession.connectedPeers.count > 0 {
			// 2
			if let imageData = image.pngData() {
				// 3
				do {
					try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
				} catch {
					let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
					ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					present(ac, animated: true)
				}
			}
		}
	}

	@objc func showConnectionPrompt() {
		let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
		ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
		ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(ac, animated: true)
	}

	func startHosting(action: UIAlertAction) {
		mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
		mcAdvertiserAssistant.start()
	}

	func joinSession(action: UIAlertAction) {
		let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
		mcBrowser.delegate = self
		present(mcBrowser, animated: true)
	}

	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

	}

	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

	}

	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

	}

	func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		dismiss(animated: true)
	}

	func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		dismiss(animated: true)
	}

	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		switch state {
		case MCSessionState.connected:
			print("Connected: \(peerID.displayName)")

		case MCSessionState.connecting:
			print("Connecting: \(peerID.displayName)")

		case MCSessionState.notConnected:
			print("Not Connected: \(peerID.displayName)")
		}
	}  // End of session didChange

    
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		if let image = UIImage(data: data) {
			DispatchQueue.main.async { [unowned self] in
				self.images.insert(image, at: 0)
				self.collectionView?.reloadData()
			}
		}
	}  // End of session didReceive

    
    
	func sendImage(img: UIImage) {
		if mcSession.connectedPeers.count > 0 {
			if let imageData = img.pngData() {
				do {
					try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
				} catch let error as NSError {
					let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
					ac.addAction(UIAlertAction(title: "OK", style: .default))
					present(ac, animated: true)
				}
			}
		}
	}  // End of sendImage
    
    
    
    
}

