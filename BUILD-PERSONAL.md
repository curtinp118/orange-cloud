# 自用 iOS IPA

此分支在主 App 的 Debug、Release 配置中启用了作者提供的
`OPENSOURCE_UNLOCKED`，使用上游自编译版的 Pro 解锁逻辑。
域名详情页的各个分区、页面修饰器和弹窗绑定已拆为独立表达式，避免
Xcode 26.6 在 Release 归档时对原有超长 SwiftUI `body` 类型推断超时。

本机构建需要完整 Xcode 26 或更高版本、iOS SDK、watchOS SDK：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash scripts/build-personal-ipa.sh
```

输出保存在 `artifacts/personal-ipa-<时间>/`，包括未签名 IPA、SHA-256、
构建日志和构建信息。一次性中间文件在脚本结束时清理。

`self-build` 和 `codex/personal-ipa-*` 分支的相关源码变更也会触发
GitHub Actions 的 macOS 构建。
输出仅保留一天，不创建公开 Release。

IPA 面向 iPhone/iPad 真机，保留 Apple Watch 配套 App 和扩展。
未签名 IPA 需要通过侧载工具或个人开发证书重新签名后安装。
若使用 Xcode 直接签名安装，应按上游 `CONTRIBUTING.md` 配置自己的
Bundle ID、App Group、Keychain Group 和开发团队；共享钥匙串、Widget、
文件提供器及推送等功能取决于签名工具和证书支持的能力。

已在自己的 Cloudflare 账号配置私有 OAuth Client 和 HTTPS 回调中转，
并更新 `apps/ios/Orange Cloud/Orange Cloud/Core/Auth/OAuthConfig.swift`。
Client ID 和回调地址是公开配置，API Token 不写入源码或 IPA。
私有 Client 只允许所属 Cloudflare 账号的成员登录。

自用回调中转源代码在 `apps/oauth-relay/`。它把授权码和 state 302 跳转到
`curtinp118orangecloud://oauth/callback`；校验 state 和 PKCE 换取令牌仍在设备端完成。
不保存授权码，不设置 Worker secret，也不记录请求日志。Client 注册了 App 使用的
100 项 API scope 和刷新令牌流程；实际授权范围仍由 App 登录时的权限选择决定。
`client.json` 只保留非秘密的客户端注册信息。

检查回调逻辑：

```bash
node --test apps/oauth-relay/worker.test.mjs
```

重新部署回调时，在 `apps/oauth-relay/` 使用 Wrangler，并通过环境变量
`CLOUDFLARE_API_TOKEN` 和 `CLOUDFLARE_ACCOUNT_ID` 提供凭据。不要把 API Token
写入配置文件。官方 Client 和 `o-c.do` 中转不用于此自用构建。

名称和图标仅供自己设备使用；分发改版需遵循 `TRADEMARK.md`、
`LICENSE` 和来源声明要求。
