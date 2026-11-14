# 自用 iOS IPA

此分支在主 App 的 Debug、Release 配置中启用了作者提供的
`OPENSOURCE_UNLOCKED`，使用上游自编译版的 Pro 解锁逻辑。

本机构建需要完整 Xcode 26 或更高版本、iOS SDK、watchOS SDK：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  bash scripts/build-personal-ipa.sh
```

输出保存在 `artifacts/personal-ipa-<时间>/`，包括未签名 IPA、SHA-256、
构建日志和构建信息。一次性中间文件在脚本结束时清理。

`self-build` 分支的相关源码变更也会触发 GitHub Actions 的 macOS 构建。
输出仅保留一天，不创建公开 Release。

IPA 面向 iPhone/iPad 真机，保留 Apple Watch 配套 App 和扩展。
未签名 IPA 需要通过侧载工具或个人开发证书重新签名后安装。
若使用 Xcode 直接签名安装，应按上游 `CONTRIBUTING.md` 配置自己的
Bundle ID、App Group、Keychain Group 和开发团队；共享钥匙串、Widget、
文件提供器及推送等功能取决于签名工具和证书支持的能力。

自编译版的登录还需要自己的 Cloudflare OAuth Client 和 HTTPS 回调中转，
配置位置为
`apps/ios/Orange Cloud/Orange Cloud/Core/Auth/OAuthConfig.swift`。
官方 OAuth Client 和 `o-c.do` 中转不对第三方构建开放，参见
`CONTRIBUTING.md` 与 `apps/web/README.md`。构建不代表该登录配置已经完成。

名称和图标仅供自己设备使用；分发改版需遵循 `TRADEMARK.md`、
`LICENSE` 和来源声明要求。
