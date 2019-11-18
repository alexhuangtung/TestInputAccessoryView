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

private let toolbarHeight: CGFloat = 54

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
        view.backgroundColor = .randomLight
        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().inset(toolbarHeight + view.safeAreaInsets.bottom)
        }
        Driver.just(Array(1...100))
            .drive(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { row, i, cell in
                cell.backgroundColor = .clear
                cell.textLabel?.text = i.description
                cell.transform = CGAffineTransform(rotationAngle: .pi)
            }
            .disposed(by: bag)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        tableView.snp.updateConstraints {
            $0.bottom.equalToSuperview().inset(toolbarHeight + view.safeAreaInsets.bottom)
        }
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
    
    private let toolbarView: ToolbarView = {
        let v = ToolbarView()
        return v
    }()
    
    private let commentView: CommentView = {
        let v = CommentView()
        return v
    }()
    
    private func setup() {
        layer.borderWidth = 1
        autoresizingMask = .flexibleHeight
        addSubview(commentView)
        commentView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
}

class ToolbarView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let commentlabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lb.textColor = .white
        lb.backgroundColor = .randomDark
        lb.text = "Leave a message!"
        return lb
    }()
    
    private let shareButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(.black, for: .normal)
        btn.setTitle("Share", for: .normal)
        return btn
    }()
    
    private func setup() {
        snp.makeConstraints {
            $0.height.equalTo(toolbarHeight)
        }
        addSubview(commentlabel)
        addSubview(shareButton)
        commentlabel.layer.cornerRadius = 17
        commentlabel.layer.masksToBounds = true
        commentlabel.snp.makeConstraints {
            $0.height.equalTo(34)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(8)
        }
        shareButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(commentlabel.snp.right).offset(8)
            $0.right.equalToSuperview().inset(8)
        }
    }
}

class CommentView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let flexibleTextView: FlexibleTextView = {
        let tv = FlexibleTextView(minHeight: 34, maxHeight: 80)
        tv.font = .systemFont(ofSize: 20, weight: .regular)
        tv.textColor = .white
        tv.backgroundColor = .randomDark
        return tv
    }()
    
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(.black, for: .normal)
        btn.setTitle("Send", for: .normal)
        return btn
    }()
    
    func setup() {
        addSubview(flexibleTextView)
        addSubview(sendButton)
        flexibleTextView.layer.cornerRadius = 17
        flexibleTextView.layer.masksToBounds = true
        flexibleTextView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(10)
            $0.left.equalToSuperview().inset(8)
        }
        sendButton.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        sendButton.snp.makeConstraints {
            $0.height.equalTo(toolbarHeight)
            $0.left.equalTo(flexibleTextView.snp.right).offset(8)
            $0.right.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview()
        }
    }
}






enum KeyboardError: Error {
    case endFrameNotFound
}

typealias KeyboardEvent = (willShow: Bool, duration: TimeInterval, curve: UIView.AnimationOptions, keyboardEndFrame: CGRect)

extension Reactive where Base: NotificationCenter {
    var keyboardEvent: Observable<KeyboardEvent> {
        return notification(UIResponder.keyboardWillChangeFrameNotification)
            .map { $0.userInfo }
            .unwrap()
            .map { userInfo -> KeyboardEvent in
                let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
                let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
                let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions().rawValue
                let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
                let willShow = keyboardEndFrame.minY < UIScreen.main.bounds.height
                return (willShow, duration, animationCurve, keyboardEndFrame)
            }
    }
}









class FlexibleTextView: UITextView {
    private let minHeight: CGFloat
    private let maxHeight: CGFloat

    init(
        minHeight: CGFloat,
        maxHeight: CGFloat
    ) {
        guard minHeight > 0.0, maxHeight > 0.0 else { fatalError() }

        self.minHeight = minHeight
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
        
        if size.height > maxHeight {
            size.height = maxHeight
            isScrollEnabled = true
        } else if size.height > minHeight {
            isScrollEnabled = false
        } else {
            size.height = minHeight
            isScrollEnabled = false
        }
        
        return size
    }
    
    @objc private func textDidChange(_ note: Notification) {
        // needed incase isScrollEnabled is set to true which stops automatically calling invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
    }
}
