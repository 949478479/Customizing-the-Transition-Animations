//
//  ViewController.swift
//  Diagonal Transition Demo
//
//  Created by 从今以后 on 16/2/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

import UIKit

class View: UIView {
	deinit {
		print(restorationIdentifier! + " delloc")
	}
}

class ViewController: UIViewController, UIViewControllerTransitioningDelegate {

	let animator = DiagonalTransitionAnimator()
	let interactor = DiagonalTransitionInteractor()

	deinit {
		print(restorationIdentifier! + " delloc")
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "PresentModally" {
			let destinationVC = segue.destinationViewController
			destinationVC.transitioningDelegate = self
			interactor.viewController = destinationVC
		}
	}

	@IBAction func unwindForSegue(unwindSegue: UIStoryboardSegue) { }

	func animationControllerForPresentedController(presented: UIViewController,
		presentingController presenting: UIViewController,
		sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
			animator.isPresenting = true
			return animator
	}

	func animationControllerForDismissedController(dismissed: UIViewController)
		-> UIViewControllerAnimatedTransitioning? {
			animator.isPresenting = false
			return animator
	}

	func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning)
		-> UIViewControllerInteractiveTransitioning? {
			// 在交互过程中再返回转场交互对象，否则返回 nil，从而让 dismiss 按钮也能正常工作
			return interactor.interacting ? interactor : nil
	}

	func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning)
		-> UIViewControllerInteractiveTransitioning? {
			return interactor.interacting ? interactor : nil
	}
}
