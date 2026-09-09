import UIKit

private struct ClipText: Decodable {
    let text: String
    let favorite: Bool
    let createdAt: Double
}

final class KeyboardViewController: UIInputViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let groupID = "group.com.lefu.xinxx.test"
    private var entries: [ClipText] = []
    private var filtered: [ClipText] = []
    private let status = UILabel()
    private let tabs = UISegmentedControl(items: ["全部", "收藏"])
    private let globe = UIButton(type: .system)
    private var collection: UICollectionView!
    private var refreshTimer: Timer?
    private var snapshot: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        let height = view.heightAnchor.constraint(equalToConstant: 300)
        height.priority = .defaultHigh
        height.isActive = true

        let title = UILabel()
        title.text = "ClipSync · 文本剪贴板"
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .label
        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refresh.accessibilityLabel = "刷新文本记录"
        refresh.addTarget(self, action: #selector(reloadEntries), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [title, refresh])
        header.spacing = 12
        refresh.widthAnchor.constraint(equalToConstant: 44).isActive = true
        header.heightAnchor.constraint(equalToConstant: 40).isActive = true
        tabs.selectedSegmentIndex = 0
        tabs.addTarget(self, action: #selector(filterEntries), for: .valueChanged)
        tabs.selectedSegmentTintColor = UIColor(red: 0.88, green: 0.91, blue: 1, alpha: 1)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.register(TextCell.self, forCellWithReuseIdentifier: "text")
        collection.dataSource = self
        collection.delegate = self
        collection.alwaysBounceVertical = false
        collection.alwaysBounceHorizontal = true
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isDirectionalLockEnabled = true
        collection.contentInsetAdjustmentBehavior = .never

        globe.setImage(UIImage(systemName: "globe"), for: .normal)
        globe.accessibilityLabel = "切换键盘"
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.widthAnchor.constraint(equalToConstant: 44).isActive = true
        let dismiss = UIButton(type: .system)
        dismiss.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismiss.accessibilityLabel = "收起键盘"
        dismiss.widthAnchor.constraint(equalToConstant: 44).isActive = true
        dismiss.addTarget(self, action: #selector(closeKeyboard), for: .touchUpInside)
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabel
        status.numberOfLines = 2
        status.textAlignment = .center
        let footer = UIStackView(arrangedSubviews: [globe, status, dismiss])
        footer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let stack = UIStackView(arrangedSubviews: [header, tabs, collection, footer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadEntries()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.reloadEntries()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        globe.isHidden = !needsInputModeSwitchKey
        collection.collectionViewLayout.invalidateLayout()
    }

    @objc private func reloadEntries() {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            showEmpty("无法读取历史，请检查 App Groups 配置")
            return
        }
        let url = root.appendingPathComponent("keyboard-texts.json")
        guard let data = try? Data(contentsOf: url) else {
            showEmpty("请先打开 ClipSync 保存文本")
            return
        }
        if data != snapshot {
            guard let decoded = try? JSONDecoder().decode([ClipText].self, from: data) else {
                showEmpty("历史读取失败，请打开 ClipSync 后重试")
                return
            }
            snapshot = data
            entries = decoded
            filterEntries()
        }

    }

    private func showEmpty(_ message: String) {
        snapshot = nil
        entries = []
        filtered = []
        collection.reloadData()
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 13)
        collection.backgroundView = label
        status.text = "仅展示本地文本记录"
    }

    @objc private func filterEntries() {
        filtered = tabs.selectedSegmentIndex == 1 ? entries.filter { $0.favorite } : entries
        collection.reloadData()
        let empty = UILabel()
        empty.text = tabs.selectedSegmentIndex == 1 ? "还没有收藏的文本" : "请先打开 ClipSync 保存文本"
        empty.textAlignment = .center
        empty.font = .systemFont(ofSize: 13)
        empty.textColor = .secondaryLabel
        collection.backgroundView = filtered.isEmpty ? empty : nil
        status.text = "点击卡片输入 · 最近 200 条文本"
    }

    @objc private func closeKeyboard() { dismissKeyboard() }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { filtered.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextCell
        let entry = filtered[indexPath.item]
        let date = Date(timeIntervalSince1970: entry.createdAt / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        cell.configure(text: entry.text, detail: formatter.localizedString(for: date, relativeTo: Date()), favorite: entry.favorite)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = collectionView.bounds.width > 600 ? 4 : 2
        // Fill the available height so the horizontal layout stays in one row.
        return CGSize(width: max(80, (collectionView.bounds.width - (columns - 1) * 8) / columns),
                      height: max(1, collectionView.bounds.height))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        textDocumentProxy.insertText(filtered[indexPath.item].text)
        status.text = "已插入输入框"
        UIAccessibility.post(notification: .announcement, argument: "已插入输入框")
    }
}

private final class TextCell: UICollectionViewCell {
    private let textLabel = UILabel()
    private let detailLabel = UILabel()
    private let icon = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.separator.cgColor
        icon.font = .systemFont(ofSize: 12, weight: .semibold)
        icon.textColor = .systemBlue
        textLabel.font = .systemFont(ofSize: 13)
        textLabel.numberOfLines = 3
        detailLabel.font = .systemFont(ofSize: 10)
        detailLabel.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [icon, textLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(text: String, detail: String, favorite: Bool) {
        icon.text = favorite ? "Aa  ★" : "Aa"
        textLabel.text = text
        detailLabel.text = detail
        accessibilityLabel = "输入：\(text)"
        accessibilityHint = "插入当前输入框的光标位置"
    }
}
