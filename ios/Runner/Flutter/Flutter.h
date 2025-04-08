// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter.h - Comprehensive version to fix sqflite import issues

#ifndef FLUTTER_FLUTTER_H_
#define FLUTTER_FLUTTER_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Forward declarations for Flutter types
@protocol FlutterBinaryMessenger;
@protocol FlutterPluginRegistrar;
@protocol FlutterPlugin;
@class FlutterEngine;
@class FlutterViewController;

// FlutterAppDelegate declaration
@interface FlutterAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) FlutterEngine *flutterEngine;
@end

// FlutterMethodChannel declaration
@interface FlutterMethodChannel : NSObject
+ (instancetype)methodChannelWithName:(NSString*)name
                      binaryMessenger:(id<FlutterBinaryMessenger>)messenger;
- (void)invokeMethod:(NSString*)method arguments:(id _Nullable)arguments;
- (void)setMethodCallHandler:(id _Nullable)handler;
@end

// FlutterEventChannel declaration
@interface FlutterEventChannel : NSObject
+ (instancetype)eventChannelWithName:(NSString*)name
                     binaryMessenger:(id<FlutterBinaryMessenger>)messenger;
@end

// FlutterPluginRegistrar protocol
@protocol FlutterPluginRegistrar <NSObject>
- (id<FlutterBinaryMessenger>)messenger;
- (NSString *)lookupKeyForAsset:(NSString *)asset;
- (NSString *)lookupKeyForAsset:(NSString *)asset fromPackage:(NSString *)package;
@end

// FlutterPlugin protocol
@protocol FlutterPlugin <NSObject>
+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar;
@end

// FlutterResult type
typedef void (^FlutterResult)(id _Nullable result);

// FlutterMethodCall class
@interface FlutterMethodCall : NSObject
@property(nonatomic, readonly) NSString *method;
@property(nonatomic, readonly) id _Nullable arguments;
@end

// FlutterBinaryMessenger protocol
@protocol FlutterBinaryMessenger <NSObject>
- (void)sendOnChannel:(NSString*)channel message:(NSData* _Nullable)message;
- (void)sendOnChannel:(NSString*)channel
              message:(NSData* _Nullable)message
          binaryReply:(void (^_Nullable)(NSData* _Nullable reply))callback;
@end

#endif  // FLUTTER_FLUTTER_H_
