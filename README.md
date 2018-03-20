![Token iOS Cover](https://raw.githubusercontent.com/tokenbrowser/token-ios-client/master/GitHub/cover.png)

## Running the project

- Open `Toshi.xcworkspace` and run

### Code formatting

We use [SwiftLint](https://github.com/realm/SwiftLint) and [Danger](https://github.com/danger/danger) to keep our code consistent and our PR's mergeable.

Check our SwiftLint [installation guide](https://github.com/toshiapp/toshi-ios-client/blob/master/installation-guide.md) to setup SwiftLint.

### Code Generation

We're using [Marathon](https://github.com/JohnSundell/Marathon) and [Stencil](https://github.com/kylef/Stencil). 

You should install Marathon using [the instructions on how to install from the Swift Package manager](https://github.com/JohnSundell/Marathon#on-macos) - the version on Homebrew isn't working correctly. 

There's some [weirdness going on with Stencil's test dependencies](https://github.com/kylef/Spectre/pull/34), so using a `Marathonfile` results in weird installation issues. In order to actually get Marathon to work for this project, please follow the following steps, IN THIS ORDER: 

1. Remove the `~/.marathon` folder - this will remove all caches. 
2. run `marathon add https://github.com/johnsundell/Files.git`
3. run `marathon add https://github.com/johnsundell/shellout.git`
4. run `marathon add https://github.com/kylef/Stencil.git`
5. **DO NOT** use `marathon update` until the issue with Stencil's dependencies is resolved.  
