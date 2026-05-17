/*******************************************************************************

 Copyright (c) 2026, Organic Maps OÜ
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 ******************************************************************************/

import UIKit

final class MasterViewController: UITableViewController {
  private static let cellID = "CapitalCell"

  let capitals: [Capital] = Capital.loadAll()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "World Capitals"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Show All", style: .plain, target: self, action: #selector(showAllOnMap))
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Status updates whenever the user returns to this screen — Organic Maps may
    // have been installed/uninstalled while the app was in the background.
    tableView.reloadSections(IndexSet(integer: 0), with: .none)
  }

  @objc private func showAllOnMap() {
    let pins = capitals.enumerated().map { index, city in
      OMPin(latitude: city.latitude, longitude: city.longitude,
            title: city.name,
            // The id is echoed back on pin selection; we'll use the city index
            // to look up the right detail screen in AppDelegate.
            identifier: "\(index)")
    }
    OrganicMaps.showPins(pins)
  }

  func pushDetail(for index: Int, animated: Bool) {
    guard capitals.indices.contains(index) else { return }
    let detail = CityDetailViewController(capital: capitals[index], index: index)
    navigationController?.pushViewController(detail, animated: animated)
  }

  // MARK: - UITableViewDataSource / Delegate

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    OrganicMaps.isInstalled ? "Organic Maps is installed" : "Organic Maps is not installed"
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    capitals.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
    cell.textLabel?.text = capitals[indexPath.row].name
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    pushDetail(for: indexPath.row, animated: true)
  }
}
