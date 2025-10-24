# Cronista

Cronista is a simple lib written in Swift capable of showing both log messages with Xcode new renderer and arbitrary console. A small part of the larger iOS deploy infrastructure at Plata.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/plataformatec/cronista.git", from: "1.0.2")
]
```

## Usage

```swift
let logger = Cronista(
    module: "some_module", 
    category: "some_category", 
    isFileLoggingEnabled: true, // default is false
    isSecretFilterEnabled: true // default is true
)

logger.info("message")
logger.fault("fault")
logger.error("some error message")
...
```

File logging is disabled by default. If enabled, find your logs in `~/.plata-logger/YYYY-MM-DD`. Useful for CI environments. Secret filtering is enabled by default and made possible by https://github.com/mazen160/secrets-patterns-db

