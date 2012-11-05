//
//  UnityAdsProperties.h
//  UnityAds
//
//  Created by bluesun on 11/2/12.
//  Copyright (c) 2012 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UnityAdsProperties : NSObject
  @property (nonatomic, strong) NSString *webViewBaseUrl;
  @property (nonatomic, strong) NSString *analyticsBaseUrl;
  @property (nonatomic, strong) NSString *adsBaseUrl;
  @property (nonatomic, strong) NSString *campaignDataUrl;

+ (id)sharedInstance;
@end
