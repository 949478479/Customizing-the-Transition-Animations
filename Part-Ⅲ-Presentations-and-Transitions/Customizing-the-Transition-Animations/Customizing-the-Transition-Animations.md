# 自定义转场动画

从 `iOS 7` 开始，自定义转场动画变得非常方便，无论是以模态形式呈现视图控制器，还是使用导航控制器或是选项卡控制器，都可以实现自定义转场动画。即使是自定义的视图控制器容器，只要做一些额外的工作，也能实现自定义转场动画。

此篇笔记主要是结合相关文档对实现自定义转场动画的过程进行梳理，包含如下内容：

- [自定义转场动画涉及的协议](#protocols)
- [自定义转场动画时的流程](#The_Transition_Animation_Sequence)
- [实现自定义转场动画](Presenting_a_View_Controller_Using_Custom_Animations)
	- [实现转场代理](#Implementing_the_Transitioning_Delegate)
	- [实现转场动画对象](#Implementing_Your_Animator_Objects)
		- [获取动画参数](#Getting_the_Animation_Parameters)
		- [创建转场动画](#Creating_the_Transition_Animations)
		- [在转场动画结束后执行清理工作](#Cleaning_Up_After_the_Animations)
	- [实现转场交互对象](#Adding_Interactivity_to_Your_Transitions)
- [在转场过程中执行额外的动画](#Creating_Animations_that_Run_Alongside_a_Transition)
	
另外推荐如下干货：

- [View Controller 转场](http://objccn.io/issue-5-3/)
- [自定义 ViewController 容器转场](http://objccn.io/issue-12-3/)
- [关于自定义转场动画，我都告诉你](http://www.jianshu.com/p/38cd35968864)
- [iOS 7 中的 ViewController 切换](http://onevcat.com/2013/10/vc-transition-in-ios7/)

<a name="protocols"></a>
## 自定义转场动画涉及的协议

实现自定义转场动画主要涉及到如下几个协议：

- [UIViewControllerAnimatedTransitioning](#UIViewControllerAnimatedTransitioning)
- [UIViewControllerInteractiveTransitioning](#UIViewControllerInteractiveTransitioning)
- [UIViewControllerContextTransitioning](#UIViewControllerContextTransitioning)
- [UIViewControllerTransitioningDelegate & UINavigationControllerDelegate & UITabBarControllerDelegate](#UIViewControllerTransitioningDelegate)

### UIViewControllerAnimatedTransitioning

此协议中的方法旨在定义转场动画持续时间以及具体的转场动画效果。需要注意的是，实现此协议创建的转场动画是非交互型转场动画，若要创建交互型转场动画，还需要与实现 [UIViewControllerInteractiveTransitioning](#UIViewControllerInteractiveTransitioning) 协议的转场交互对象相互配合。

实现此协议时，实现 `transitionDuration:` 方法来指定转场动画持续时间，实现 `animateTransition:` 方法来实现转场动画效果。转场动画涉及到的相关对象的信息会由实现 [UIViewControllerContextTransitioning](#UIViewControllerContextTransitioning) 协议的转场上下文对象封装，并作为参数传入。

以模态视图形式呈现目标视图控制器时，为其设置 `transitioningDelegate` 属性，即转场代理。转场代理需实现 [UIViewControllerTransitioningDelegate](#UIViewControllerTransitioningDelegate) 协议中的相应代理方法来提供相应的转场动画对象和转场交互对象。

```swift
protocol UIViewControllerAnimatedTransitioning : NSObjectProtocol {
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval
	func animateTransition(transitionContext: UIViewControllerContextTransitioning)
	optional func animationEnded(transitionCompleted: Bool)
}
```

### UIViewControllerInteractiveTransitioning

若要实现交互型转场动画，需利用实现此协议的转场交互对象与实现 [UIViewControllerAnimatedTransitioning](#UIViewControllerAnimatedTransitioning) 协议的转场动画对象相互配合。此协议中的方法旨在根据用户交互控制转场动画时间，具体的转场动画效果则需由转场动画对象提供。

```swift
protocol UIViewControllerInteractiveTransitioning : NSObjectProtocol {
    func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning)
    optional func completionSpeed() -> CGFloat
    optional func completionCurve() -> UIViewAnimationCurve
}
```

`UIPercentDrivenInteractiveTransition` 这个类已经实现了此协议，可以直接拿来使用，也可根据需要进行子类化。该类会控制转场动画对象的动画过程，如果不使用该类就只能自己处理动画过程。

```swift
class UIPercentDrivenInteractiveTransition : NSObject, UIViewControllerInteractiveTransitioning {

   var duration: CGFloat { get }
   var percentComplete: CGFloat { get }
   var completionSpeed: CGFloat
   var completionCurve: UIViewAnimationCurve
    
   func updateInteractiveTransition(percentComplete: CGFloat)
   func cancelInteractiveTransition()
   func finishInteractiveTransition()
}
```

### UIViewControllerContextTransitioning

此协议中的方法旨在提供转场过程中的上下文信息。一般无需实现此协议，也不用创建实现此协议的对象。相反，在转场过程中，系统会提供一个实现了此协议的转场上下文对象，转场动画对象和转场交互对象都可以通过相应协议方法的参数来获取转场上下文对象。

转场上下文对象封装了转场过程涉及到的视图控制器和视图的信息。对于交互型转场动画，转场交互对象可以利用此协议中的相关方法来报告转场进度。在交互型转场动画开始时，转场交互对象需要保存转场上下文对象的引用，然后基于用户的交互进度，通过 `updateInteractiveTransition:`、`finishInteractiveTransition`、`cancelInteractiveTransition` 方法来报告转场进度直至转场完成或取消。

> 注意  
> 定义转场动画对象时，应该检查转场上下文对象的 `isAnimated` 方法的返回值，以此决定是否应该执行动画。在动画完成时，应该调用转场上下文对象的 `completeTransition:` 方法向系统报告转场动画是顺利完成还是被中途取消。

```swift
protocol UIViewControllerContextTransitioning : NSObjectProtocol {
  
   func containerView() -> UIView?
   func viewForKey(key: String) -> UIView?
   func viewControllerForKey(key: String) -> UIViewController?
   
   func initialFrameForViewController(vc: UIViewController) -> CGRect
   func finalFrameForViewController(vc: UIViewController) -> CGRect
   
   func isAnimated() -> Bool
   func isInteractive() -> Bool     
   func presentationStyle() -> UIModalPresentationStyle
    
   func updateInteractiveTransition(percentComplete: CGFloat)
   func finishInteractiveTransition()
   func completeTransition(didComplete: Bool)
   func cancelInteractiveTransition()
   func transitionWasCancelled() -> Bool
   
   // 可判断界面在转场结束后不会旋转，还是被旋转 +90°、-90°、180°
   func targetTransform() -> CGAffineTransform
}
```

下图展示了转场上下文对象在转场过程中所扮演的角色：

![](Images/VCPG_transitioning-context-object_10-2_2x.png)

### UIViewControllerTransitioningDelegate

以模态形式呈现视图控制器时，为目标视图控制器设置 `transitioningDelegate` 属性，并根据需求实现相应的代理方法来提供转场动画对象。若要支持交互型转场动画，则还需提供转场交互对象。

```swift
protocol UIViewControllerTransitioningDelegate : NSObjectProtocol {
    
    // 使用如下两个代理方法分别为 presenting 和 dismissing 转场阶段提供转场动画对象。
    // 如果不实现，或者返回 nil，则会使用系统的转场动画效果。
    
    optional func animationControllerForPresentedController(presented: UIViewController, 
    	presentingController presenting: UIViewController, 
    	sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    
    optional func animationControllerForDismissedController(dismissed: UIViewController)
    	-> UIViewControllerAnimatedTransitioning?
    
    // 使用如下两个代理方法分别为 presenting 和 dismissing 转场阶段提供转场交互对象。
    // 转场交互对象只是用于根据用户交互来控制转场动画时间，无论是否支持交互转场，转场动画对象均需由上述两个代理方法提供。
    // 如果不实现，或者返回 nil，则转场效果是非交互型的。
    
    optional func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning)
    	-> UIViewControllerInteractiveTransitioning?
    
    optional func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning)
    	-> UIViewControllerInteractiveTransitioning?
    
    // 此方法是 iOS 8 引入的，涉及到 UIPresentationController，而并非普通的模态形式
    // 当目标视图控制器的 modalPresentationStyle 属性设置为 UIModalPresentationCustom 时，
    // 实现此代理方法提供自定义的 UIPresentationController 子类。
    // 如果不实现，或者返回 nil，则会使用系统默认的 UIPresentationController。
    optional func presentationControllerForPresentedViewController(presented: UIViewController, 
    	presentingViewController presenting: UIViewController, 
    	sourceViewController source: UIViewController) -> UIPresentationController?
}
```

导航控制器和选项卡控制器也支持自定义转场动画以及交互型转场动画，通过如下代理方法提供转场动画对象和转场交互对象即可。

```swift
protocol UINavigationControllerDelegate : NSObjectProtocol {

    optional func navigationController(navigationController: UINavigationController, 
    	interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) 
    	-> UIViewControllerInteractiveTransitioning?
  
    optional func navigationController(navigationController: UINavigationController, 
    	animationControllerForOperation operation: UINavigationControllerOperation, 
    	fromViewController fromVC: UIViewController, 
    	toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
}
```

```swift
protocol UITabBarControllerDelegate : NSObjectProtocol {
 
    optional func tabBarController(tabBarController: UITabBarController,
    	interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning)
    	-> UIViewControllerInteractiveTransitioning?
    
    optional func tabBarController(tabBarController: UITabBarController, 
    	animationControllerForTransitionFromViewController fromVC: UIViewController, 
    	toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
}
```

下图展示了转场代理在转场过程中所扮演的角色：

![](Images/VCPG_custom-presentation-and-animator-objects_10-1_2x.png)

图中蓝色的方块即是目标视图控制器，它通过它的转场代理来提供相应的转场对象。虽然图中展示的是以模态形式呈现视图控制器时的情况，不过使用导航控制器和选项卡控制器时原理与此基本相同。

<a name="The_Transition_Animation_Sequence"></a>
## 自定义转场动画时的流程

以下流程仅针对以模态形式呈现视图控制器时的情况，使用导航控制器和选项卡控制器时大同小异。

当目标视图控制器设置了 `transitioningDelegate` 时，系统会在视图控制器呈现前调用转场代理的 `animationControllerForPresentedController:presentingController:sourceController:` 方法来获取相应的转场动画对象。如果转场代理提供了转场动画对象，则进入如下流程：

1. 继续调用转场代理的 `interactionControllerForPresentation:` 方法获取转场交互对象，若不提供，则执行非交互型的转场动画。
2. 调用转场动画对象的 `transitionDuration:` 方法获取转场动画持续时间。
3. 根据是否是交互型转场动画做不同处理：
    - 对于非交互型转场动画，调用转场动画对象的 `animateTransition:` 方法。
    - 对于交互型转场动画，调用转场交互对象的 `startInteractiveTransition:` 方法。
4. 等待转场动画对象调用转场上下文对象的 `completeTransition:` 方法。通常会在动画的完成闭包中调用此方法。之后，系统就会调用 `presentViewController:animated:completion:` 方法和转场动画对象的 `animationEnded:` 方法。

在 `dismissing` 阶段，系统会调用转场代理的 `animationControllerForDismissedController:` 方法获取相应的转场动画对象。如果转场代理提供了转场动画对象，则进入如下流程：

1. 继续调用转场代理的 `interactionControllerForDismissal:` 方法获取转场交互对象，若不提供，则执行非交互型的转场动画。
2. 调用转场动画对象的 `transitionDuration:` 方法获取转场动画持续时间。
3. 根据是否是交互型转场动画做不同处理：
    - 对于非交互型转场动画，调用转场动画对象的 `animateTransition:` 方法。
    - 对于交互型转场动画，调用转场交互对象的 `startInteractiveTransition:` 方法。
4. 等待转场动画对象调用转场上下文对象的 `completeTransition:` 方法。通常会在动画的完成闭包中调用此方法。之后，系统就会调用 `dismissViewControllerAnimated:completion:` 方法和转场动画对象的 `animationEnded:` 方法。

> 注意  
> 一定要在动画结束后调用转场上下文对象的 `completeTransition:` 方法，这样系统才会结束转场过程，并将控制权返还给应用。

<a name="Presenting_a_View_Controller_Using_Custom_Animations"></a>
## 实现自定义转场动画

以模态形式呈现视图控制器为例，导航控制器和选项卡控制器与此大同小异，主要步骤如下：

1. 创建要呈现的视图控制器。
2. 为要呈现的视图控制器设置 `transitioningDelegate` 属性，并通过相关代理方法提供转场动画对象和转场交互对象。
3. 调用 `presentViewController:animated:completion:` 方法呈现视图控制器。

调用 `presentViewController:animated:completion:` 方法后，系统会在下一运行循环开始转场过程，该过程一直会持续到转场动画对象调用转场上下文对象的 `completeTransition:` 方法。交互型转场动画可以在转场过程中处理用户交互，非交互型转场动画只会运行转场动画对象指定的持续时间。

<a name="Implementing_the_Transitioning_Delegate"></a>
### 实现转场代理

转场代理的目的是提供转场动画对象和转场交互对象，例如如下代码所示：

```swift
func animationControllerForPresentedController(presented: UIViewController, 
	presentingController presenting: UIViewController, 
	sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return MyAnimator()
}
```

其他代理方法与此基本相同。在实际使用中，可能需要根据应用的状态来返回不同的转场动画对象和转场交互对象。

<a name="Implementing_Your_Animator_Objects"></a>
### 实现转场动画对象

转场动画对象是实现了 `UIViewControllerAnimatedTransitioning` 协议的对象，关键方法是 `animateTransition:`，使用此方法来创建执行固定时间的转场动画。转场动画过程大致可分为如下阶段：

1. 获取动画参数。
2. 使用核心动画或视图动画来创建转场动画。
3. 在动画结束后报告动画完成并进行适当的清理工作。

<a name="Getting_the_Animation_Parameters"></a>
#### 获取动画参数

转场上下文对象会作为参数传入 `animateTransition:` 方法，应该总是从该上下文对象中获取信息，而不要缓存信息。有时候，转场动画会涉及到视图控制器之外的视图。例如，使用自定义的 `UIPresentationController` 时，转场动画可能会涉及到额外的背景视图，使用转场上下文能确保获取到正确的视图控制器和视图。

- 调用 `viewControllerForKey:` 方法来获取转场动画涉及到的视图控制器，而不要假设哪些视图控制器参与到了转场动画中。
- 调用 `containerView` 方法来获取转场动画所在的父视图，转场动画涉及的所有视图都是该视图的子视图。
- 在 `iOS 8` 之后，调用 `viewForKey:` 方法来获取转场动画涉及到的视图，而不要直接使用视图控制器的视图，以确保正确的行为。
- 调用 `finalFrameForViewController:` 方法获取视图控制器的视图的最终 `frame`。

转场上下文对象使用 `from` 和 `to` 来描述转场动画涉及到的视图控制器、视图以及视图的 `frame`。`from` 描述的是当前在屏幕上的对象，`to` 描述的则是转场结束后出现在屏幕上的对象。如下图所示：

![](Images/VCPG_from-and-to-objects_10-4_2x.png)

可以看到，在转场过程的不同阶段，这两个词语所描述的对象也有所不同。

<a name="Creating_the_Transition_Animations"></a>
#### 创建转场动画

- `presentation` 阶段：
	- 利用转场上下文对象的 `viewControllerForKey:` 和 `viewForKey:` 方法获取相关的视图控制器和视图。
	- 利用转场上下文对象的 `initialFrameForViewController` 和 `finalFrameForViewController:` 方法获取 `frame`。
	- 设置 `from` 视图和 `to` 视图在转场动画开始前的动画属性。
	- 将 `to` 视图添加到 `containerView` 上。
	- 创建动画。在动画完成时，调用转场上下文对象的 `completeTransition:` 方法，并根据需要执行清理工作。
		
- `dismissal ` 阶段：
	- 利用转场上下文对象的 `viewControllerForKey:` 和 `viewForKey:` 方法获取相关的视图控制器和视图。
	- 利用转场上下文对象的 `initialFrameForViewController` 和 `finalFrameForViewController:` 方法获取 `frame`。
	- 设置 `from` 视图和 `to` 视图在转场动画开始前的动画属性。
	- 将 `to` 视图添加到 `containerView` 上。因为此视图在 `presentation` 阶段完成后被移除了。
	- 创建动画。在动画完成时，调用转场上下文对象的 `completeTransition:` 方法，并根据需要执行清理工作。

下图演示了一种简单的自定义转场动画：

![](Images/VCPG_custom-presentation-and-dismissal_10-5_2x.png)

相应代码如下所示：

```swift
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
```

<a name="Cleaning_Up_After_the_Animations"></a>
#### 在转场动画结束后执行清理工作

在转场动画完成后，例如在完成闭包中，调用转场上下文对象的 `completeTransition:` 方法，告知系统转场动画已经完成。这也将导致 `presentViewController:animated:completion:` 方法和转场动画对象的 `animationEnded:` 方法被调用。

由于交互型转场过程可以被取消，因此应该使用转场上下文对象的 `transitionWasCancelled` 方法进行判断。若转场过程被取消，调用 `completeTransition:` 方法时则应该传入 `false`，并根据需要执行一些清理工作，例如将视图层级恢复到转场过程开始之前的状态。

<a name="Adding_Interactivity_to_Your_Transitions"></a>
### 实现转场交互对象

实现转场交互对象的最简单的方法是使用 `UIPercentDrivenInteractiveTransition` 对象，该对象实现了 `UIViewControllerInteractiveTransitioning` 协议，能够和转场动画对象配合，根据用户交互控制转场动画过程。选择子类化 `UIPercentDrivenInteractiveTransition` 对象时，可以在构造方法或者 `startInteractiveTransition:` 方法中进行初始化设置。在交互过程中，根据用户手势以一定的逻辑来计算转场完成度，并调用 `updateInteractiveTransition:` 方法进行更新。当判定交互完成时，调用 `finishInteractiveTransition` 方法。若交互被取消，则调用 `cancelInteractiveTransition` 方法。

相应代码如下所示：

```swift
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
```

<a name="Creating_Animations_that_Run_Alongside_a_Transition"></a>
## 在转场过程中执行额外的动画

在转场时，可以通过视图控制器的 `transitionCoordinator` 属性获取一个实现了 `UIViewControllerTransitionCoordinator` 协议的转场协调员对象。利用转场协调员对象所实现的协议方法，可以在转场过程中执行额外的动画。注意，转场协调员对象只存在于转场过程中，因此不要保存它。可以在视图控制器的 `viewWillAppear:` 方法中来获取转场协调员对象。

`UIViewControllerTransitionCoordinator` 协议声明如下：

```swift
protocol UIViewControllerTransitionCoordinator : UIViewControllerTransitionCoordinatorContext {
    
    // 在闭包中定义的动画会和转场动画一并执行，并同样支持交互。
    func animateAlongsideTransition(animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
    	completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?) -> Bool
    
    // 闭包中的动画发生在当前转场动画所涉及的视图层级之外的视图时，使用此方法而不是上面的方法，
    // 利用参数 view 来指定闭包中的动画所涉及的视图或其父视图。
    func animateAlongsideTransitionInView(view: UIView?, 
    	animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?) -> Bool
    
    // 转场动画执行完毕或被中途取消时，通过此方法注册的闭包会被调用，可以多次调用此方法来注册多个闭包。
    // 可通过闭包参数的 isCancelled 方法来判断转场是否被取消。
    // 当转场被取消时，目标视图控制器的 viewWillDisappear: 方法会被调用，
    // 接着源视图控制器的 viewWillAppear: 方法会被调用，而注册的闭包会在这两个方法之前被调用。
    func notifyWhenInteractionEndsUsingBlock(handler: (UIViewControllerTransitionCoordinatorContext) -> Void)
}
```

`UIViewControllerTransitionCoordinator` 协议的父协议和 `UIViewControllerContextTransitioning` 协议极其相似：

```swift
protocol UIViewControllerTransitionCoordinatorContext : NSObjectProtocol {
    
    func viewControllerForKey(key: String) -> UIViewController?
    func viewForKey(key: String) -> UIView?
    func containerView() -> UIView
    
    func presentationStyle() -> UIModalPresentationStyle
    func transitionDuration() -> NSTimeInterval
    func completionCurve() -> UIViewAnimationCurve 
    func completionVelocity() -> CGFloat 
    func percentComplete() -> CGFloat
    
    func initiallyInteractive() -> Bool
    func isAnimated() -> Bool
    func isCancelled() -> Bool
    func isInteractive() -> Bool
    
    func targetTransform() -> CGAffineTransform
}
```

下图展示了转场协调员对象在转场过程中所扮演的角色：

![](Images/VCPG_transition-coordinator-objects_10-3_2x.png)