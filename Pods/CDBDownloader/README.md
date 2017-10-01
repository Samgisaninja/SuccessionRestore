# CDBDownloader

[![CI Status](http://img.shields.io/travis/Kanstantsin Bucha/CDBDownloader.svg?style=flat)](https://travis-ci.org/Kanstantsin Bucha/CDBDownloader)
[![Version](https://img.shields.io/cocoapods/v/CDBDownloader.svg?style=flat)](http://cocoapods.org/pods/CDBDownloader)
[![License](https://img.shields.io/cocoapods/l/CDBDownloader.svg?style=flat)](http://cocoapods.org/pods/CDBDownloader)
[![Platform](https://img.shields.io/cocoapods/p/CDBDownloader.svg?style=flat)](http://cocoapods.org/pods/CDBDownloader)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.
```objc
    [CDBDownloader downloadFileAtURL:URL
                            progress:nil
                          completion:^(NSURL * downloadedFileURL, NSError *error) {
        if (error != nil) {
            [[NSFileManager new] removeItemAtURL:downloadedFileURL
                                           error:nil];
            return;
        }

        NSLog(@" Download document to URL:\
              \r\n %@", downloadedFileURL);
    }];
```

remember to add section to your app in info.plist file,
replace www.pdf995.com to your download domain

```
    <key>NSAppTransportSecurity</key>
    <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
    <key>www.pdf995.com</key>
    <dict>
    <key>NSIncludesSubdomains</key>
    <true/>
    <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
    <true/>
    <key>NSTemporaryExceptionMinimumTLSVersion</key>
    <string>TLSv1.1</string>
    </dict>
    </dict>
    </dict>
```

## Requirements

## Installation

CDBDownloader is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CDBDownloader"
```

## Author

Kanstantsin Bucha, truebucha@gmail.com

## License

CDBDownloader is available under the MIT license. See the LICENSE file for more info.
