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
    private var language = "zh"
    private let titleLabel = UILabel()
    private let refresh = UIButton(type: .system)
    private let dismiss = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        let height = view.heightAnchor.constraint(equalToConstant: 250)
        height.priority = .defaultHigh
        height.isActive = true

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        refresh.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refresh.addTarget(self, action: #selector(reloadEntries), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [titleLabel, refresh])
        header.spacing = 8
        refresh.widthAnchor.constraint(equalToConstant: 36).isActive = true
        header.heightAnchor.constraint(equalToConstant: 32).isActive = true
        tabs.selectedSegmentIndex = 0
        tabs.addTarget(self, action: #selector(filterEntries), for: .valueChanged)
        tabs.selectedSegmentTintColor = UIColor(red: 0.88, green: 0.91, blue: 1, alpha: 1)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.register(TextCell.self, forCellWithReuseIdentifier: "text")
        collection.dataSource = self
        collection.delegate = self
        collection.alwaysBounceVertical = true
        collection.alwaysBounceHorizontal = false
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isDirectionalLockEnabled = true
        collection.contentInsetAdjustmentBehavior = .never

        globe.setImage(UIImage(systemName: "globe"), for: .normal)
        globe.accessibilityLabel = "切换键盘"
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.widthAnchor.constraint(equalToConstant: 38).isActive = true
        dismiss.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        dismiss.accessibilityLabel = "收起键盘"
        dismiss.widthAnchor.constraint(equalToConstant: 38).isActive = true
        dismiss.addTarget(self, action: #selector(closeKeyboard), for: .touchUpInside)
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabel
        status.numberOfLines = 2
        status.textAlignment = .center
        let footer = UIStackView(arrangedSubviews: [globe, status, dismiss])
        footer.heightAnchor.constraint(equalToConstant: 36).isActive = true
        let stack = UIStackView(arrangedSubviews: [header, tabs, collection, footer])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        applyLanguage()
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
            showEmpty(tr("groupError"))
            return
        }
        let languageURL = root.appendingPathComponent("keyboard-language.txt")
        let newLanguage = (try? String(contentsOf: languageURL, encoding: .utf8)) ?? "zh"
        if newLanguage != language {
            language = newLanguage.hasPrefix("en") ? "en" : "zh"
            applyLanguage()
        }
        let url = root.appendingPathComponent("keyboard-texts.json")
        guard let data = try? Data(contentsOf: url) else {
            showEmpty(tr("openApp"))
            return
        }
        if data != snapshot {
            guard let decoded = try? JSONDecoder().decode([ClipText].self, from: data) else {
                showEmpty(tr("readError"))
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
        status.text = tr("localOnly")
    }

    @objc private func filterEntries() {
        filtered = tabs.selectedSegmentIndex == 1 ? entries.filter { $0.favorite } : entries
        collection.reloadData()
        let empty = UILabel()
        empty.text = tabs.selectedSegmentIndex == 1 ? tr("noFavorites") : tr("openApp")
        empty.textAlignment = .center
        empty.font = .systemFont(ofSize: 13)
        empty.textColor = .secondaryLabel
        collection.backgroundView = filtered.isEmpty ? empty : nil
        status.text = tr("hint")
    }

    @objc private func closeKeyboard() { dismissKeyboard() }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { filtered.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextCell
        let entry = filtered[indexPath.item]
        let date = Date(timeIntervalSince1970: entry.createdAt / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: language == "en" ? "en_US" : "zh_CN")
        cell.configure(text: entry.text,
                       detail: formatter.localizedString(for: date, relativeTo: Date()),
                       favorite: entry.favorite,
                       accessibilityPrefix: language == "en" ? "Insert" : "输入",
                       accessibilityHint: language == "en" ? "Insert at the cursor" : "插入当前输入框的光标位置")
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: max(1, collectionView.bounds.width), height: 54)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        textDocumentProxy.insertText(filtered[indexPath.item].text)
        status.text = tr("inserted")
        UIAccessibility.post(notification: .announcement, argument: tr("inserted"))
    }

    private func applyLanguage() {
        titleLabel.text = tr("title")
        tabs.setTitle(tr("all"), forSegmentAt: 0)
        tabs.setTitle(tr("favorites"), forSegmentAt: 1)
        refresh.accessibilityLabel = tr("refresh")
        globe.accessibilityLabel = tr("switchKeyboard")
        dismiss.accessibilityLabel = tr("dismiss")
    }

    private func tr(_ key: String) -> String {
        let en = language == "en"
        let values: [String: (String, String)] = [
            "title": ("PasteLink · 文本剪贴板", "PasteLink · Text Clipboard"),
            "all": ("全部", "All"), "favorites": ("收藏", "Favorites"),
            "refresh": ("刷新文本记录", "Refresh text history"),
            "switchKeyboard": ("切换键盘", "Switch keyboard"),
            "dismiss": ("收起键盘", "Dismiss keyboard"),
            "groupError": ("无法读取历史，请检查 App Groups 配置", "Unable to read history. Check App Groups."),
            "openApp": ("请先打开 PasteLink 保存文本", "Open PasteLink and save some text first"),
            "readError": ("历史读取失败，请打开 PasteLink 后重试", "Unable to read history. Open PasteLink and retry."),
            "localOnly": ("仅展示本地文本记录", "Showing local text only"),
            "noFavorites": ("还没有收藏的文本", "No favorite text yet"),
            "hint": ("点击卡片输入 · 最近 200 条文本", "Tap to insert · Latest 200 texts"),
            "inserted": ("已插入输入框", "Inserted into text field")
        ]
        guard let value = values[key] else { return key }
        return en ? value.1 : value.0
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
        textLabel.numberOfLines = 2
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        detailLabel.font = .systemFont(ofSize: 10)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .right
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [icon, textLabel, detailLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),
            icon.widthAnchor.constraint(equalToConstant: 34),
            detailLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 54)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted
                ? UIColor.systemBlue.withAlphaComponent(0.16)
                : .secondarySystemGroupedBackground
            transform = isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }
    func configure(text: String, detail: String, favorite: Bool,
                   accessibilityPrefix: String, accessibilityHint: String) {
        icon.text = favorite ? "Aa  ★" : "Aa"
        textLabel.text = text
        detailLabel.text = detail
        accessibilityLabel = "\(accessibilityPrefix): \(text)"
        self.accessibilityHint = accessibilityHint
    }
}
