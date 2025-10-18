# Cronista

Cronista is a simple lib written in Swift capable of showing both log messages with Xcode new renderer and arbitrary console. A small part of the larger iOS deploy infrastructure at Plata.

## Usage

```swift
let logger = Cronista(module: "some_module", category: "some_category")

logger.info("message")
logger.fault("fault")
logger.error("some error message")
...
```

Secret filtering is made possible by https://github.com/mazen160/secrets-patterns-db

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/plataformatec/cronista.git", from: "1.0.2")
]
```