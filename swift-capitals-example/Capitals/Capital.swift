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

import Foundation

struct Capital {
  let name: String
  let latitude: Double
  let longitude: Double

  init?(from dict: [String: Any]) {
    guard let name = dict["name"] as? String,
          let latitude = dict["lat"] as? Double,
          let longitude = dict["lon"] as? Double
    else { return nil }
    self.name = name
    self.latitude = latitude
    self.longitude = longitude
  }

  /// Loads the bundled capitals.plist (shared with the Obj-C example).
  static func loadAll() -> [Capital] {
    guard let url = Bundle.main.url(forResource: "capitals", withExtension: "plist"),
          let data = try? Data(contentsOf: url),
          let list = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [[String: Any]]
    else { return [] }
    return list.compactMap(Capital.init(from:))
  }
}
