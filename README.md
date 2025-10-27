# Cronista
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

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


## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/adurymanov"><img src="https://avatars.githubusercontent.com/u/21358938?v=4?s=100" width="100px;" alt="Andrei"/><br /><sub><b>Andrei</b></sub></a><br /><a href="https://github.com/platacard/cronista/commits?author=adurymanov" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!