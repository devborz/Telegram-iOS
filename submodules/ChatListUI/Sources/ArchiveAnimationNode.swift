import UIKit
import AsyncDisplayKit
import Lottie
import Display

private let lightGrayColor: CGColor = UIColor(hexString: "D9D9DE")!.cgColor
private let darkGrayColor: CGColor = UIColor(hexString: "B1B7BE")!.cgColor

private let lightBlueColor: CGColor = UIColor(hexString: "76C6FD")!.cgColor
private let darkBlueColor: CGColor = UIColor(hexString: "0B86F3")!.cgColor

private let darkGray = Color(r: 0.69, g: 0.71, b: 0.74, a: 1)
private let darkBlue = Color(r: 0.043, g: 0.52, b: 0.95, a: 1)

private let fillKeypath = AnimationKeypath(keypath: "**.Fill 1.Color")
private let arrowKeypath = AnimationKeypath(keypath: "**.Stroke 1.Color")

private var showArchiveHeight: CGFloat {
    return 78
}

private var arrowTurnEndHeight: CGFloat {
    return 86
}

private var arrowCircleSize: CGFloat {
    return 20
}

private var arrowTrackLeftInset: CGFloat {
    return 30
}

private var arrowTrackTopInset: CGFloat {
    return 7
}

private var arrowTrackBottomInset: CGFloat {
    return 7
}

protocol ArchiveAnimationNodeDelegate: AnyObject {
    
    func changeTopInset(inset: CGFloat)
    
}

public final class ArchiveAnimationNode: ASDisplayNode {
    
    weak var delegate: ArchiveAnimationNodeDelegate?
    
    enum Mode {
        case swipe, release, animateArchive
    }
    
    private var grayGradientLayer: CAGradientLayer!
    
    private var blueGradientLayer: CAGradientLayer!
    
    private let blueGradientMaskLayer: CAShapeLayer = .init()
    
    private let blueBackgroundNode: ASDisplayNode = ASDisplayNode()
    
    private var animationNode: AnimationView!
    
    private let animationContainerNode = ASDisplayNode()

    private let trackNode = ASDisplayNode()
    
    private let swipeLabel = UILabel()
    
    private let releaseLabel = UILabel()
    
    var mode: Mode? = nil {
        didSet {
            if self.mode != oldValue {
                self.updateMode()
            }
        }
    }
    
    var lastMode: Mode = .swipe
    
    override init() {
        super.init()
        self.animationNode = .init(name: "archive")
        
        self.clipsToBounds = false
    }
    
    public override func didLoad() {
        super.didLoad()
        self.trackNode.backgroundColor = .white
        self.trackNode.alpha = 0.3
        self.trackNode.layer.cornerRadius = arrowCircleSize / 2
        self.trackNode.clipsToBounds = true
        
        self.addSubnode(self.blueBackgroundNode)
        self.addSubnode(self.trackNode)
        self.addSubnode(self.animationContainerNode)
        self.view.addSubview(self.swipeLabel)
        self.view.addSubview(self.releaseLabel)
    
        self.animationContainerNode.view.addSubview(self.animationNode)
        self.animationContainerNode.frame = CGRect(x: arrowTrackLeftInset - 3, y: 8,
                                                   width: arrowCircleSize + 6,
                                                   height: arrowCircleSize + 6)
        
        self.animationNode.frame = CGRect(x: 0, y: 0,
                                          width: arrowCircleSize + 6,
                                          height: arrowCircleSize + 6)
        self.animationNode.loopMode = .loop
        self.animationNode.animationSpeed = 1
        
        let whiteValueProvider = ColorValueProvider(Color(r: 1, g: 1, b: 1, a: 1))
        let arrowGrayValueProvider = ColorValueProvider(darkGray)
        self.animationNode.setValueProvider(whiteValueProvider, keypath: fillKeypath)
        self.animationNode.setValueProvider(arrowGrayValueProvider, keypath: arrowKeypath)
        
        self.grayGradientLayer = self.grayGradient()
        self.blueGradientLayer = self.blueGradient()
        self.layer.insertSublayer(self.grayGradientLayer, at: 0)
        
        self.blueBackgroundNode.layer.insertSublayer(self.blueGradientLayer, at: 0)
        self.blueGradientLayer.mask = self.blueGradientMaskLayer
        self.blueBackgroundNode.transform = CATransform3DMakeAffineTransform(.identity.rotated(by: .pi))
        self.blueBackgroundNode.clipsToBounds = true
        
        self.swipeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        self.swipeLabel.textColor = .white
        self.swipeLabel.text = "Swipe down for archive"
        self.swipeLabel.textAlignment = .center
        self.releaseLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        self.releaseLabel.textColor = .white
        self.releaseLabel.text = "Release for archive"
        self.releaseLabel.alpha = 0
        self.releaseLabel.textAlignment = .center
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFrame(frame: CGRect, transition: ContainedViewLayoutTransition) {
        if self.mode == .animateArchive {
            var frame = frame
            if frame.height < 0.5 {
                frame.size.height = 0
            }
            let diff = self.currentOffset - frame.height
            let progress = diff / self.currentOffset
            let newDiff = progress * (self.currentOffset - 76)
            let inset = self.currentTopInset - 76 + (diff - newDiff)
            self.delegate?.changeTopInset(inset: inset)
            
            let radius = (self.frame.width - 30) * (1 - progress) + 30
            let path: CGPath = .init(roundedRect: CGRect(x: self.frame.width - 40 - radius,
                                             y: 36 - radius,
                                             width: radius * 2,
                                             height: radius * 2),
                         cornerWidth: radius,
                         cornerHeight: radius,
                         transform: nil)
            self.blueGradientMaskLayer.path = path
            
            let newFrame = CGRect(x: 0, y: self.frame.origin.y,
                                  width: self.frame.width,
                                  height: self.currentOffset - newDiff)
            
            self.blueBackgroundNode.frame = .init(origin: .zero, size: newFrame.size)
            self.frame = newFrame
            
            self.releaseLabel.alpha = progress
            
            self.animationNode.currentProgress = progress
            
            let animationNodeFrame = CGRect(x: 25 + (arrowTrackLeftInset - 25) * (1 - progress),
                                            y: 23 + (self.currentOffset - arrowTrackBottomInset - arrowCircleSize - 23) * (1 - progress),
                                            width: arrowCircleSize + (30 - arrowCircleSize) * progress,
                                            height: arrowCircleSize + (30 - arrowCircleSize) * progress)
            self.animationContainerNode.frame = animationNodeFrame
            self.animationNode.frame = CGRect(origin: .zero, size: animationNodeFrame.size)
            
            let trackChangeProgress = progress > 0.2 ? 1 : progress / 0.2
            let trackFrame = CGRect(x: arrowTrackLeftInset,
                                    y: arrowTrackTopInset + 36 * trackChangeProgress,
                                    width: arrowCircleSize,
                                    height: (self.currentOffset - arrowTrackBottomInset - arrowTrackTopInset) * (1 - progress))
            self.trackNode.frame = trackFrame
            if frame.height == 0 {
                self.mode = .swipe
            }
        } else {
            self.frame = frame
            self.updateGradients(frame: frame)
            self.updateTrack(frame: frame)
            self.updateFrames(frame: frame)
        }
    }
    
    private func updateGradients(frame: CGRect) {
        let bounds = CGRect(x: 0, y: 0,
                            width: frame.width,
                            height: frame.width * 3)
        self.grayGradientLayer.frame = bounds
    }
    
    var currentOffset: CGFloat = 0
    
    var currentTopInset: CGFloat = 0
    
    private func updateMode() {
        guard let mode = self.mode else { return }
        
        if mode == .animateArchive {
            self.grayGradientLayer.opacity = 0
            return 
        }
        self.animationNode.currentProgress = 0
        self.grayGradientLayer.opacity = 1
        let bounds = CGRect(x: 0, y: 0,
                            width: self.frame.width,
                            height: self.frame.height)
        
        var arrowColorProvider: ColorValueProvider
        var transform: CGAffineTransform
        var radius: CGFloat = 0
        var offset: CGFloat = 0
        switch mode {
        case .release:
            radius = bounds.width
            transform = .identity
            arrowColorProvider = .init(darkBlue)
        case .swipe:
            offset = -bounds.width / 2
            radius = 0.5
            transform = .identity.rotated(by: .pi * 0.99999)
            arrowColorProvider = .init(darkGray)
        default:
            return
        }
    
        self.blueGradientMaskLayer.opacity = 1
        self.blueGradientMaskLayer.frame = bounds
        let path: CGPath = .init(roundedRect: CGRect(x: self.frame.width - arrowTrackLeftInset - arrowCircleSize / 2 - radius,
                                         y: arrowTrackBottomInset + arrowCircleSize / 2 - radius,
                                         width: radius * 2,
                                         height: radius * 2),
                     cornerWidth: radius,
                     cornerHeight: radius,
                     transform: nil)
        
        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = self.blueGradientMaskLayer.path
        anim.toValue = path
        anim.duration = 0.2
        anim.timingFunction = CAMediaTimingFunction(name: mode == .release ? CAMediaTimingFunctionName.easeIn : CAMediaTimingFunctionName.easeOut)

        UIView.animate(withDuration: 0.2, delay: 0.0, options: [mode == .release ? .curveEaseIn : .curveEaseOut ]) {
            self.animationNode.transform = transform
            self.animationNode.setValueProvider(arrowColorProvider, keypath: arrowKeypath)
            self.swipeLabel.alpha = mode == .swipe ? 1 : 0
            self.releaseLabel.alpha = mode == .release ? 1 : 0
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6) {
            self.swipeLabel.frame.origin.x = offset + bounds.width / 2
            self.releaseLabel.frame.origin.x = offset
        }
        
        // add animation
        self.blueGradientMaskLayer.add(anim, forKey: nil)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.blueGradientMaskLayer.path = path
        self.blueGradientMaskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.blueGradientMaskLayer.opacity = mode == .release ? 1 : 0
        }
        CATransaction.commit()
    }
    
    private func grayGradient() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [darkGrayColor, lightGrayColor]
        gradientLayer.startPoint = .init(x: 0, y: 0)
        gradientLayer.endPoint = .init(x: 1, y: 0)
        return gradientLayer
    }
    
    private func blueGradient() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [lightBlueColor, darkBlueColor]
        gradientLayer.startPoint = .init(x: 0, y: 0)
        gradientLayer.endPoint = .init(x: 1, y: 0)
        return gradientLayer
    }
    
    func updateTrack(frame: CGRect) {
        var trackFrame = CGRect(x: arrowTrackLeftInset, y: 0,
                                width: arrowCircleSize,
                                height: arrowCircleSize)
        if frame.height >= arrowTrackTopInset + arrowCircleSize + arrowTrackBottomInset {
            trackFrame.origin.y = arrowTrackTopInset
            trackFrame.size.height = frame.height - arrowTrackTopInset - arrowTrackBottomInset
        } else {
            trackFrame.origin.y = frame.height - arrowTrackBottomInset - arrowCircleSize
        }
        self.trackNode.frame = trackFrame
    }
    
    func updateFrames(frame: CGRect) {
        let bounds = CGRect(x: 0, y: 0,
                            width: frame.width,
                            height: frame.width * 3)
        
        if frame.height <= showArchiveHeight {
            self.mode = .swipe
            self.lastMode = .swipe
        } else if frame.height < arrowTurnEndHeight {
            self.mode = self.lastMode == .release ? .swipe : .release
        } else {
            self.mode = .release
            self.lastMode = .release
        }
        
        let rect = CGRect(x: 0, y: 0,
                            width: frame.width,
                            height: frame.height)
        self.blueBackgroundNode.frame = rect
        self.animationContainerNode.frame.origin.y = frame.height - arrowTrackBottomInset - arrowCircleSize - 3
        self.blueGradientLayer.frame = bounds
        
        self.swipeLabel.frame.origin.y = frame.height - arrowCircleSize - arrowTrackBottomInset
        self.swipeLabel.frame.size.height = arrowCircleSize
        self.swipeLabel.frame.size.width = frame.width
        
        self.releaseLabel.frame.origin.y = frame.height - arrowCircleSize - arrowTrackBottomInset
        self.releaseLabel.frame.size.height = arrowCircleSize
        self.releaseLabel.frame.size.width = frame.width
    }
    
}
