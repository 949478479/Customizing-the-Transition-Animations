//
//  DiagonalTransitionInteractor.swift
//  Diagonal Transition Demo
//
//  Created by 从今以后 on 16/2/13.
//  Copyright © 2016年 从今以后. All rights reserved.
//

import UIKit

class DiagonalTransitionInteractor: UIPercentDrivenInteractiveTransition {

	private(set) var interacting = false
	weak var viewController: UIViewController? {
		didSet {
			guard oldValue != viewController else { return }

			// 移除旧视图控制器的视图上添加的手势识别器
			if let panGR = panGestureRecognizer, oldValue = oldValue {
				oldValue.view.removeGestureRecognizer(panGR)
			}

			// 为新视图控制器的视图添加手势识别器
			if let viewController = viewController {
				let panGR = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
				panGestureRecognizer = panGR
				viewController.view.addGestureRecognizer(panGR)
			}
		}
	}

	private var shouldComplete = false
	private weak var panGestureRecognizer: UIPanGestureRecognizer?

	@objc private func handlePanGesture(panGR: UIPanGestureRecognizer) {
		switch panGR.state {
		case .Began:
			interacting = true
			shouldComplete = false
			// 启动转场过程
			viewController?.dismissViewControllerAnimated(true, completion: nil)
		case .Changed:
			// 根据拖动距离计算百分比，若超过一半则判断为可以完成
			let translation = panGR.translationInView(panGR.view!)
			let percentage = min(max(0, abs(translation.y / panGR.view!.bounds.height)), 1)
			shouldComplete = percentage > 0.5
			updateInteractiveTransition(percentage)
		default:
			interacting = false
			// 当手势被取消或者完成时，根据百分比决定是完成转场过程还是取消转场过程
			shouldComplete ? finishInteractiveTransition() : cancelInteractiveTransition()
		}
	}
}
