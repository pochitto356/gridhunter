import Foundation
import Capacitor
import GameKit
import UIKit

/// Game Center の認証・スコア送信・自分の順位取得・ランキング画面表示を Web 側へ公開する。
/// Web 側は www/index.html の GC オブジェクト(window.Capacitor.Plugins.GameCenter)。
@objc(GameCenterPlugin)
public class GameCenterPlugin: CAPPlugin, CAPBridgedPlugin, GKGameCenterControllerDelegate {
    public let identifier = "GameCenterPlugin"
    public let jsName = "GameCenter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "signIn", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "submit", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "ranks", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise)
    ]

    private var authStarted = false
    private var authInFlight = false
    private var waiting: [CAPPluginCall] = []

    // MARK: - 認証

    @objc func signIn(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let player = GKLocalPlayer.local
            if player.isAuthenticated {
                call.resolve(["ok": true])
                return
            }
            if self.authStarted && !self.authInFlight {
                // 一度キャンセルされた等。iOS は同じ起動中にログイン画面を再表示しない
                call.resolve(["ok": false])
                return
            }
            self.waiting.append(call)
            if self.authStarted { return }
            self.authStarted = true
            self.authInFlight = true
            player.authenticateHandler = { [weak self] vc, _ in
                guard let self = self else { return }
                if let vc = vc {
                    self.bridge?.viewController?.present(vc, animated: true)
                    return
                }
                self.authInFlight = false
                let ok = GKLocalPlayer.local.isAuthenticated
                let list = self.waiting
                self.waiting = []
                list.forEach { $0.resolve(["ok": ok]) }
            }
        }
    }

    // MARK: - スコア送信

    @objc func submit(_ call: CAPPluginCall) {
        let score = call.getInt("score") ?? 0
        let ids = (call.getArray("ids", String.self) ?? [])
        guard GKLocalPlayer.local.isAuthenticated, !ids.isEmpty, score > 0 else {
            call.resolve(["ok": false])
            return
        }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: ids) { error in
            call.resolve(["ok": error == nil])
        }
    }

    // MARK: - 自分の順位と1位(定期リーダーボードは今の期間)

    @objc func ranks(_ call: CAPPluginCall) {
        let ids = (call.getArray("ids", String.self) ?? [])
        guard GKLocalPlayer.local.isAuthenticated, !ids.isEmpty else {
            call.resolve(["ranks": [String: Any]()])
            return
        }
        GKLeaderboard.loadLeaderboards(IDs: ids) { boards, _ in
            guard let boards = boards, !boards.isEmpty else {
                call.resolve(["ranks": [String: Any]()])
                return
            }
            var out: [String: Any] = [:]
            let lock = NSLock()
            let group = DispatchGroup()
            for board in boards {
                group.enter()
                board.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1)) { local, top, total, _ in
                    var info: [String: Any] = ["total": total]
                    if let e = local {
                        info["rank"] = e.rank
                        info["score"] = e.score
                    }
                    if let first = top?.first {
                        info["topName"] = first.player.displayName
                        info["topScore"] = first.score
                    }
                    lock.lock()
                    out[board.baseLeaderboardID] = info
                    lock.unlock()
                    group.leave()
                }
            }
            group.notify(queue: .main) { call.resolve(["ranks": out]) }
        }
    }

    // MARK: - ランキング画面

    @objc func show(_ call: CAPPluginCall) {
        let id = call.getString("id") ?? ""
        DispatchQueue.main.async {
            guard let top = self.bridge?.viewController else {
                call.resolve(["ok": false])
                return
            }
            let vc: GKGameCenterViewController
            if !id.isEmpty {
                vc = GKGameCenterViewController(leaderboardID: id, playerScope: .global, timeScope: .allTime)
            } else {
                vc = GKGameCenterViewController(state: .leaderboards)
            }
            vc.gameCenterDelegate = self
            top.present(vc, animated: true)
            call.resolve(["ok": true])
        }
    }

    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
