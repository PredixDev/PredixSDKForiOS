//
//  PredixSDK.h
//  PredixSDK
//
//  Created by Johns, Andy (GE Corporate) on 5/19/15.
//  Copyright (c) 2015 GE. All rights reserved.
//
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#ifndef PredixSDK_h
#define PredixSDK_h

//! Project version number for PredixSDK.
FOUNDATION_EXPORT double PredixSDKVersionNumber;

//! Project version string for PredixSDK.
FOUNDATION_EXPORT const unsigned char PredixSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PredixSDK/PublicHeader.h>

#import "Extensions.h"
#endif
