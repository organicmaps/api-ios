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

final class CityDetailViewController: UIViewController {
  private let capital: Capital
  private let index: Int

  init(capital: Capital, index: Int) {
    self.capital = capital
    self.index = index
    super.init(nibName: nil, bundle: nil)
    title = capital.name
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let nameLabel = UILabel()
    nameLabel.text = capital.name
    nameLabel.font = .preferredFont(forTextStyle: .title1)
    nameLabel.textAlignment = .center

    let coordsLabel = UILabel()
    coordsLabel.text = String(format: "lat: %.4f, lon: %.4f", capital.latitude, capital.longitude)
    coordsLabel.font = .preferredFont(forTextStyle: .body)
    coordsLabel.textColor = .secondaryLabel
    coordsLabel.textAlignment = .center

    let mapButton = UIButton(type: .system)
    mapButton.setTitle("Show on map", for: .normal)
    mapButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    mapButton.addTarget(self, action: #selector(showOnMap), for: .touchUpInside)

    let wikiButton = UIButton(type: .system)
    wikiButton.setTitle("Show with Wikipedia link", for: .normal)
    wikiButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    wikiButton.addTarget(self, action: #selector(showWithWikipediaLink), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [nameLabel, coordsLabel, mapButton, wikiButton])
    stack.axis = .vertical
    stack.spacing = 24
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
    ])
  }

  @objc private func showOnMap() {
    OrganicMaps.showPin(
      latitude: capital.latitude,
      longitude: capital.longitude,
      title: capital.name,
      identifier: "\(index)")
  }

  @objc private func showWithWikipediaLink() {
    let urlSafeName = capital.name.replacingOccurrences(of: " ", with: "_")
    let wikipediaURL = "https://en.wikipedia.org/wiki/\(urlSafeName)"
    OrganicMaps.showPin(
      latitude: capital.latitude,
      longitude: capital.longitude,
      title: capital.name,
      // A valid URL in `identifier` makes Organic Maps' "More Info" open the page
      // instead of returning to our app.
      identifier: wikipediaURL)
  }
}
