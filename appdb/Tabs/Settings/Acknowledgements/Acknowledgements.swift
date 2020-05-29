//
//  Acknowledgements.swift
//  appdb
//
//  Created by ned on 12/05/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

struct License {
    var title: String
    var text: String
}

class Acknowledgements: LoadingTableView {

    var licenses: [License] = [] {
        didSet {
            tableView.spr_endRefreshingAll()
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Acknowledgements".localized()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "license")
        tableView.estimatedRowHeight = 500
        tableView.rowHeight = UITableView.automaticDimension

        tableView.theme_separatorColor = Color.borderColor
        tableView.theme_backgroundColor = Color.tableViewBackgroundColor
        view.theme_backgroundColor = Color.tableViewBackgroundColor

        animated = false
        showsErrorButton = false
        showsSpinner = false

        // Hide last separator
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))

        if Global.isIpad {
            // Add 'Dismiss' button for iPad
            let dismissButton = UIBarButtonItem(title: "Dismiss".localized(), style: .done, target: self, action: #selector(self.dismissAnimated))
            self.navigationItem.rightBarButtonItems = [dismissButton]
        }

        // Refresh action
        tableView.spr_setIndicatorHeader { [weak self] in
            self?.parseLicenses()
        }

        tableView.spr_beginRefreshing()
    }

    // Parse 'Acknowledgements.plist' into an array of Licenses
    private func parseLicenses() {
        guard let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "plist") else { fail(); return }

        // Debug
        //debugLog("SHA1 of acknowledgements file is \(SHA1.hexString(fromFile: url.path)!)")

        guard SHA1.hexString(fromFile: url.path) == "AFB2D061 CD29BC3D 8DBF4E1C 776147C1 C97CA35A" else { fail(); return }

        do {
            let data = try Data(contentsOf: url)
            guard let items = try PropertyListSerialization.propertyList(from: data, format: nil)
                as? [[String: String]] else { fail(); return }

            var tmpLicenses: [License] = []
            for item in items {
                if let title = item["Title"], let text = item["Copyright"] {
                    tmpLicenses.append(License(title: title, text: text))
                }
            }
            self.licenses = tmpLicenses.sorted(by: { $0.title.lowercased() < $1.title.lowercased() })
        } catch {
            fail(error)
        }
    }

    private func fail(_ error: Error? = nil) {
        licenses = []
        if let error = error {
            self.showErrorMessage(text: "Cannot connect".localized(), secondaryText: error.localizedDescription, animated: false)
        } else {
            self.showErrorMessage(text: "An error has occurred".localized(), secondaryText: "Could not parse plist file.".localized(), animated: false)
        }
    }

    @objc func dismissAnimated() { dismiss(animated: true) }

    override func numberOfSections(in tableView: UITableView) -> Int {
        licenses.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.theme_textColor = Color.title
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "license", for: indexPath)
        cell.textLabel?.text = licenses[indexPath.section].text
        cell.textLabel?.font = .systemFont(ofSize: (15 ~~ 14))
        cell.textLabel?.theme_textColor = Color.darkGray
        cell.textLabel?.makeDynamicFont()
        cell.setBackgroundColor(Color.veryVeryLightGray)
        cell.theme_backgroundColor = Color.veryVeryLightGray
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        licenses[section].title
    }
}
