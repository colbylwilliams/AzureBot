# AzureBot

AzureBot is an iOS SDK for embedding a bot created using Microsoft Bot Framework.


### Features
- [x] [Direct Line API](https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-direct-line-3-0-api-reference?view=azure-bot-service-4.0)
- [x] [Uses websockets](https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-direct-line-3-0-concepts?view=azure-bot-service-4.0#receiving-messages) _(instead of polling GET requests)_
- [x] Sample App
- [x] Native Chat UI
- [ ] [Rich Card](https://docs.microsoft.com/en-us/azure/bot-service/bot-service-design-user-experience?view=azure-bot-service-4.0#cards) Support
    - [ ] AdaptiveCard
    - [ ] AnimationCard
    - [ ] AudioCard
    - [ ] HeroCard
    - [ ] ThumbnailCard
    - [ ] ReceiptCard
    - [ ] SignInCard
    - [ ] SuggestedAction
    - [ ] VideoCard
    - [ ] CardCarousel

### Requirements
- iOS 11.0+
- Xcode 9.3+
- Swift 4.1+
- [A Bot](https://docs.microsoft.com/en-us/azure/bot-service/bot-builder-basics?view=azure-bot-service-4.0)



# Try Me

Want to check out the SDK first?  Check out the example app.  Just clone this repo, add your Direct Line Secret to the [Example App's `AzureData.plist`](https://github.com/colbylwilliams/AzureBot/blob/master/Example/AzureBot%20Example/Source/AzureBot.plist) file and run.


# Installation

Follow one of these three options to add the framework to your own project.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate AzureBot into your Xcode project using Carthage, specify it in your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "colbylwilliams/AzureBot"
```

Run `carthage update` to build the framework and drag the built `AzureBot.framework` into your Xcode project.

### CocoaPods
[CocoaPods](https://cocoapods.org/) manages library dependencies for your Xcode projects.

The dependencies for your projects are specified in a single text file called a Podfile. CocoaPods will resolve dependencies between libraries, fetch the resulting source code, then link it together in an Xcode workspace to build your project.

You can install CocoaPods with the following command:

```bash
$ sudo gem install cocoapods
```

To integrate AzureBot into your Xcode project using CocoaPods, specify it in your [Podfile](https://guides.cocoapods.org/using/the-podfile.html)
```
pod 'AzureBot', :git => 'https://github.com/baillyjamy/AzureBot.git'
```
Run `pod install` to create your workspace. For more information, see the [documentation](https://guides.cocoapods.org/)

### Swift Package Manager

_Coming soon_



# Keys

To get started using AzureBot, you need to provide the SDK with your [Direct Line Secret](https://docs.microsoft.com/en-us/azure/bot-service/rest-api/bot-framework-rest-direct-line-3-0-concepts?view=azure-bot-service-4.0#authentication). There are two ways to provide the Direct Line Secret; programmatically, or by adding it to a plist file:

### Programmatically

The simplest way to provide these values and start using the SDK is to set the values programmatically:

```
BotClient.shared.configure(withSecret: "BOT_FRAMEWORK_DIRECT_LINE_SECRET")
```


### Plist File

Alternatively, you can provide these values in your project's `info.plist`, a separate [`AzureBot.plist`](https://github.com/colbylwilliams/AzureBot/blob/master/AzureBot/AzureBot.plist), or provide the name of your own plist file to use.  Simply add the `BotFrameworkDirectLineSecret` key and provide your Direct Line Secret.

**_Note: This method is provided for convenience when quickly developing samples and is not recommended to ship this secret in a plist in production apps._**

#### Info.plist

```
...
<dict>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>BotFrameworkDirectLineSecret</key>
    <string>BOT_FRAMEWORK_DIRECT_LINE_SECRET</string>
...
```

#### AzureBot.plist

Or add a [`AzureBot.plist`](https://github.com/colbylwilliams/AzureBot/blob/master/AzureBot/AzureBot.plist) file.

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BotFrameworkDirectLineSecret</key>
    <string>BOT_FRAMEWORK_DIRECT_LINE_SECRET</string>
</dict>
</plist>
```

#### Named plist

Finally, you can `BotFrameworkDirectLineSecret` key/value to any plist in your project's **main bundle** and provide the name of the plist:

```swift
BotClient.shared.configure(withPlistNamed: "SuperDuperDope")
```


# BotViewController

`BotViewController` is a UIViewController that renders the conversational interface for your bot.

![BotViewController-0](/images/azurebot_0.png?raw=true "BotViewController") | ![BotViewController-1](/images/azurebot_1.png?raw=true "BotViewController") | ![BotViewController-2](/images/azurebot_2.png?raw=true "BotViewController")
:-------------------------:|:-------------------------:|:-------------------------:

You can add a `BotViewController` to your application programmatically or in your Storyboard file:

### Programmatically

```swift
let botController = BotViewController.create()

present(botController, animated: true, completion: nil)
```


### Storyboard

![Storyboard](/images/storyboard.png?raw=true "Storyboard")


# About


## Third-party Code ❤️
- [SortedArray](https://github.com/ole/SortedArray)
- [Starscream](https://github.com/daltoniam/starscream)


## License
Licensed under the MIT License.  See [LICENSE](License) for details.
