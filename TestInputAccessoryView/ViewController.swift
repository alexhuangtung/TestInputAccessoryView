//
//  ViewController.swift
//  TestInputAccessoryView
//
//  Created by Alex Huang on 2019/11/15.
//  Copyright © 2019 Alex Huang. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxSwiftExt

class ViewController: UIViewController {
    
    private let fooView = FooView()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.tableFooterView = UIView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.keyboardDismissMode = .interactive
        tv.contentInsetAdjustmentBehavior = .never
        tv.transform = CGAffineTransform(rotationAngle: .pi)
        return tv
    }()
    
    override var inputAccessoryView: UIView? {
        return fooView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.right.bottom.equalToSuperview()
        }
        Driver.just(Array(1...100))
            .drive(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { row, i, cell in
                cell.textLabel?.text = i.description
                cell.transform = CGAffineTransform(rotationAngle: .pi)
            }
            .disposed(by: bag)
        KeyboardEventListener.keyboardWillChangeFrame
            .subscribe(onNext: { [unowned self] willShow, duration, curve, keyboardEndFrame in
                let topInset = keyboardEndFrame.height
                if self.tableView.contentOffset.y <= -self.tableView.contentInset.top {
                    self.tableView.contentOffset = CGPoint(x: 0, y: -topInset)
                }
                self.tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
                self.tableView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: UIScreen.main.bounds.width - 8)
            })
            .disposed(by: bag)
    }

}











class FooView: UIView {
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let flexibleTextView: FlexibleTextView = {
        let tv = FlexibleTextView(maxHeight: 80)
        tv.layer.borderWidth = 1
        tv.font = .systemFont(ofSize: 20, weight: .regular)
        return tv
    }()
    
    private func setup() {
        layer.borderWidth = 1
        autoresizingMask = .flexibleHeight
        backgroundColor = .white
        addSubview(flexibleTextView)
        flexibleTextView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview().inset(8)
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(8)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
}






enum KeyboardError: Error {
    case endFrameNotFound
}

typealias KeyboardInfo = (
    willShow: Bool,
    duration: TimeInterval,
    curve: UIView.AnimationOptions,
    keyboardEndFrame: CGRect
)

struct KeyboardEventListener {

    static let keyboardWillChangeFrame =
        NotificationCenter.default
        .rx.notification(UIResponder.keyboardWillChangeFrameNotification)
        .map { $0.userInfo }
        .unwrap()
        .map { (userInfo) -> KeyboardInfo in
            guard let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { throw KeyboardError.endFrameNotFound }
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions().rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            let willShow = keyboardEndFrame.minY < UIScreen.main.bounds.height
            return (willShow, duration, animationCurve, keyboardEndFrame)
        }
        .share()
}









class FlexibleTextView: UITextView {
    private let maxHeight: CGFloat

    init(maxHeight: CGFloat) {
        self.maxHeight = maxHeight
        super.init(frame: .zero, textContainer: nil)
        textContainer.lineFragmentPadding = 0
        textContainerInset = .zero
        isScrollEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        NotificationCenter.default.addObserver(self, selector: #selector(UITextInputDelegate.textDidChange(_:)), name: UITextView.textDidChangeNotification, object: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var text: String! {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var font: UIFont? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        if size.height == UIView.noIntrinsicMetric {
            // force layout
            layoutManager.glyphRange(for: textContainer)
            size.height = layoutManager.usedRect(for: textContainer).height + textContainerInset.top + textContainerInset.bottom
        }
        
        if maxHeight > 0.0 && size.height > maxHeight {
            size.height = maxHeight
            isScrollEnabled = true
        } else {
            isScrollEnabled = false
        }
        
        return size
    }
    
    @objc private func textDidChange(_ note: Notification) {
        // needed incase isScrollEnabled is set to true which stops automatically calling invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
    }
}
