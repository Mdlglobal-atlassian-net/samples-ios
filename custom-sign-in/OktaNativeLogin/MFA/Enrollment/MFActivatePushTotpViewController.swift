/*
 * Copyright 2019 Okta, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import OktaAuthSdk
import SVProgressHUD
import UIKit

class MFActivatePushTotpViewController: AuthBaseViewController {
    var factor: OktaFactor {
        let mfaActivate = status as! OktaAuthStatusFactorEnrollActivate
        return mfaActivate.factor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show(withStatus: "Downloading QR code...")
        if let qrCodeUrl = factor.factor.embedded?.activation?.links?.qrcode?.href{
            DispatchQueue.global().async {
                let imageData = try? Data(contentsOf: qrCodeUrl)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    guard let imageData = imageData else {
                        self.showError(message: "Can't download qr code from url: \(qrCodeUrl)")
                        return
                    }
                    self.qrCodeImageView.image = UIImage(data: imageData)
                }
            }
        }

        factorResultLabel.flash()

        if let factor = factor as? OktaFactorPush {
            codeTextField.removeFromSuperview()
            factor.activate(onStatusChange:
                { status in
                    self.flowCoordinatorDelegate?.onStatusChanged(status: status)
            },
                            onError:
                { error in
                    self.showError(message: error.description)
            },
                            onFactorStatusUpdate:
                { factorResult in
                    if factorResult != OktaAPISuccessResponse.FactorResult.waiting {
                        self.factorResultLabel.layer.removeAllAnimations()
                    }
                    self.factorResultLabel.text = factorResult.rawValue
            })
        } else {
            factorResultLabel.removeFromSuperview()
            let activateButton = UIBarButtonItem(title: "Activate",
                                             style: .plain,
                                             target: self,
                                             action: #selector(activateTotp))
            self.navigationItem.setRightBarButton(activateButton, animated: true)
        }
    }

    @objc func activateTotp() {
        guard let code = codeTextField.text, !code.isEmpty else { return }
        factor.activate(passCode: code,
                        onStatusChange:
            { status in
                self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        },
                        onError:
            { error in
                self.showError(message: error.description)
        },
                        onFactorStatusUpdate:
            { factorResult in
                if factorResult != OktaAPISuccessResponse.FactorResult.waiting {
                    self.factorResultLabel.layer.removeAllAnimations()
                }
                self.factorResultLabel.text = factorResult.rawValue
        })
    }
    
    @IBAction private func cancelTapped() {
        self.processCancel()
    }
    
    @IBOutlet private var qrCodeImageView: UIImageView!
    @IBOutlet private var factorResultLabel: UILabel!
    @IBOutlet private var codeTextField: UITextField!
}
