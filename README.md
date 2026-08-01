# WebViewBridge

[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/Sunalamye/WebViewBridge/releases)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B%20%7C%20iOS%2017%2B-lightgrey.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Swift 與網頁的雙向通訊橋接層：**JavaScript 模組注入、訊息回傳、WebSocket 攔截**。

---

## ⚠️ 兩個版本門檻不一樣

這件事容易搞混，先講清楚：

| | 版本 |
|---|---|
| **套件可以被加進去** | macOS 14+ / iOS 17+ |
| **`WebViewBridge` 這個型別可以用** | **macOS 26+ / iOS 26+** |

套件本身的部署目標是 14/17，所以**你的 App 只要 14+ 就能把它列為依賴**，
不會被迫整包升上去。但橋接器是建立在 `WebPage` API 上的，
那個 API 只有 26 才有，所以實際使用要包在 `@available` 裡。

如果你的 App 需要在 26 以下也能運作，得自己準備 `WKWebView` 的替代路徑。

---

## 安裝

```swift
dependencies: [
    .package(url: "https://github.com/Sunalamye/WebViewBridge.git", from: "0.2.0")
]
```

---

## 快速開始

```swift
import WebViewBridge
import WebKit

@available(macOS 26.0, iOS 26.0, *)
@MainActor
final class MyController {
    let bridge = WebViewBridge(handlerName: "myBridge")
    var webPage: WebPage?

    func setUp() {
        // 內建模組（sendToSwift、WebSocket 攔截器等）
        bridge.registerCoreModules()

        // 自己的模組
        bridge.registerModule(JavaScriptModule(
            name: "my-module",
            source: """
                window.myApp = {
                    send(msg) {
                        window.__bridgeCore.sendToSwift('custom_message', { message: msg });
                    }
                };
            """))

        bridge.onMessage = { type, data in
            print("收到：\(type) — \(data)")
        }

        var configuration = WebPage.Configuration()
        let controller = WKUserContentController()
        bridge.configure(contentController: controller)
        configuration.userContentController = controller

        webPage = WebPage(configuration: configuration)
        bridge.configure(webPage: webPage!)
    }
}
```

### JavaScript → Swift

```javascript
window.__bridgeCore.sendToSwift('my_event', { key: 'value' });
```

### Swift → JavaScript

```swift
let title = try await bridge.callJavaScript("return document.title")
```

> ### ⚠️ 必須寫 `return`
>
> `WebPage.callJavaScript()` 收的是**函式主體**，不是運算式。
>
> - ❌ `"document.title"` → 回傳 `null`
> - ✅ `"return document.title"` → 回傳實際標題
>
> 這是最常踩的坑，而且不會報錯，只會靜默拿到 `null`。

### 攔截 WebSocket

```javascript
window.__bridgeCore.installWebSocketInterceptor({
    shouldIntercept: (url) => url.includes('your-api.com')
});
```

攔截到的訊息會以 `websocket_message` 型別送到 Swift 端的 `onMessage`。

---

## 結構

```
Sources/WebViewBridge/
├── Core/
│   └── WebViewBridge.swift    橋接器本體
├── JavaScript/
│   └── bridge-core.js         內建 JS 模組
└── WebViewBridgeKit.swift     版本資訊
```

---

## API

### WebViewBridge

| 成員 | 說明 |
|------|------|
| `handlerName` | 訊息處理器名稱 |
| `delegate` | 代理 |
| `onMessage` | 訊息回呼 `(type, data) -> Void` |
| `registerModule(_:)` | 註冊 JS 模組 |
| `registerCoreModules()` | 註冊內建模組 |
| `configure(webPage:)` | 綁定 `WebPage` 實例 |
| `configure(contentController:)` | 綁定 `WKUserContentController` |
| `callJavaScript(_:)` | 執行 JS（**要寫 `return`**） |
| `isWebSocketConnected` | WebSocket 連線狀態 |

### JavaScriptModule

| 屬性 | 說明 |
|-----|------|
| `name` | 模組名稱 |
| `source` | JavaScript 原始碼 |
| `injectAtStart` | 是否在文件開始時注入 |
| `mainFrameOnly` | 是否只注入主框架 |

### bridge-core.js

| 方法 | 說明 |
|------|------|
| `sendToSwift(type, data)` | 送訊息到 Swift |
| `log(message)` | 送日誌 |
| `arrayBufferToBase64(buffer)` | ArrayBuffer → Base64 |
| `base64ToArrayBuffer(base64)` | Base64 → ArrayBuffer |
| `blobToBase64(blob, callback)` | Blob → Base64 |
| `installWebSocketInterceptor(options)` | 安裝 WebSocket 攔截器 |

### 內建訊息型別

全部是 JS → Swift 方向：

| 型別 | 說明 |
|------|------|
| `websocket_open` | 開始連線 |
| `websocket_connected` | 已連線 |
| `websocket_message` | 收到訊息 |
| `websocket_closed` | 已關閉 |
| `websocket_error` | 發生錯誤 |
| `console_log` | 日誌訊息 |

---

## 更新日誌

### v0.2.0

- 部署目標降到 macOS 14 / iOS 17（`WebViewBridge` 型別本身仍需 26+）
- 升級到 Swift 6.2

### v0.1.x

- 初始版本

---

## License

[MIT](LICENSE)
