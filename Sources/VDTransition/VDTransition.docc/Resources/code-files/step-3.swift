import UIKit
import VDTransition

class ViewController: UIViewController {

    @IBOutlet private var view1: UILabel!
    @IBOutlet private var view2: UILabel!
    @IBOutlet private var view3: UILabel!
    
    @IBAction private func replaceTap(_ sender: UIButton) {
        view2.set(
            hidden: true,
            transition: [.opacity, .scale(anchor: .topTrailing)],
            animation: .default(0.5)
        )
    }
}
