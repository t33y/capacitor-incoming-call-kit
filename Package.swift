// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CallKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "CallKit",
            targets: ["Classes"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", branch: "main"),
//        .package(url: "https://github.com/stasel/WebRTC.git", .upToNextMajor(from:"130.0.0"))
    ],
    targets: [
                         .binaryTarget(
             name: "webrtc",
             path: "ios/Frameworks/WebRTC.xcframework"
             
        ),
        .target(
            name: "Classes",
            dependencies: [
                 "webrtc",
//                .product(name: "WebRTC", package: "WebRTC"),
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
            ],
            path: "ios/Classes"),
        

        
    ]
)
