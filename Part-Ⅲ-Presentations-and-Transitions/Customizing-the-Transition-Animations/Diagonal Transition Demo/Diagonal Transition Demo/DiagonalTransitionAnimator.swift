//
//  DiagonalTransitionAnimator.swift
//  Diagonal Transition Demo
//
//  Created by 从今以后 on 16/2/12.
//  Copyright © 2016年 从今以后. All rights reserved.
//

import UIKit

class DiagonalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

	var isPresenting = true

	private let duratoin: NSTimeInterval = 0.5

	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return duratoin
	}

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

		let containerView = transitionContext.containerView()!
		let containerSize = containerView.frame.size

		let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
		let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
		let toViewFinalFrame = transitionContext.finalFrameForViewController(toVC)

		let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!

		if self.isPresenting {
			// 在动画开始前先将被呈现的视图移至屏幕右下角
			toView.frame = toViewFinalFrame.offsetBy(dx: containerSize.width, dy: containerSize.height)
			containerView.addSubview(toView)
		} else {
			// 如果没有修改过原视图的 frame，可以不写这句代码
			toView.frame = toViewFinalFrame
			// 在 dismissal 阶段，在动画开始前直接将原视图放置在最终位置，位于被呈现的视图之下
			containerView.insertSubview(toView, belowSubview: fromView)
		}

		UIView.animateWithDuration(duratoin, animations: { () -> Void in

			if self.isPresenting {
				// 在 presentation 阶段，将被 present 的视图移动至最终位置
				toView.frame = toViewFinalFrame
			} else {
				// 在 dismissal 阶段，将被 dismiss 的视图移出屏幕
				fromView.frame.offsetInPlace(dx: containerSize.width, dy: containerSize.height)
			}

		}, completion: { _ in
			let success = !transitionContext.transitionWasCancelled()
			if !success {
				// 转场被中途取消，将 toView 移除，恢复转场前的视图层级
				toView.removeFromSuperview()
			}
			// 报告转场动画结束
			transitionContext.completeTransition(success)
		})
	}
}
