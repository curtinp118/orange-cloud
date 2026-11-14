//
//  OAuthConfig.swift
//  Orange Cloud
//
//  在 Cloudflare Dashboard 创建 OAuth Client 后，填入真实 clientID。
//  redirect_uri 必须与 Dashboard 中注册的完全一致。
//

import Foundation

nonisolated enum OAuthConfig {
    /// 自用 OAuth Client，限制为所属 Cloudflare 账号成员授权；PKCE 不需要 client secret。
    static let clientID = "82e013cb5721c4246342a56f3200c9f4"

    /// 自定义 scheme，供 Web 后端 302 跳回 App
    static let callbackScheme = "curtinp118orangecloud"

    // Cloudflare OAuth 只接受 https redirect_uri，指向 Web 后端回调中转（见 apps/web/README.md）
//    #if DEBUG
//    static let redirectURI = "http://localhost:3000/oauth/callback"
//    #else
    static let redirectURI = "https://orangecloud-personal-oauth.curtinp118.workers.dev/oauth/callback"
//    #endif

    // Cloudflare OAuth 端点
    static let authorizationURL = URL(string: "https://dash.cloudflare.com/oauth2/auth")!
    static let tokenURL         = URL(string: "https://dash.cloudflare.com/oauth2/token")!
    static let revokeURL        = URL(string: "https://dash.cloudflare.com/oauth2/revoke")!
    static let userInfoURL      = URL(string: "https://dash.cloudflare.com/oauth2/userinfo")!
}
