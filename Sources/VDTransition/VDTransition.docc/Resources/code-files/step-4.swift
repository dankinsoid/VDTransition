import UIKit
import VDTransition

class ViewController: UIViewController {
    
    @IBOutlet private var view1: UILabel!
    @IBOutlet private var view2: UILabel!
    @IBOutlet private var view3: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view2.isHidden = true
    }
    
    @IBAction private func replaceTap(_ sender: UIButton) {
        view2.set(
            hidden: false,
            transition: [.opacity, .move(edge: .bottom)],
            animation: .spring(1, damping: 0.2, initialVelocity: 5)
        )
    }
}
