//
//  UnityAdsiOS4.m
//  UnityAdsExample
//
//  Created by Johan Halin on 9/4/12.
//  Copyright (c) 2012 Unity Technologies. All rights reserved.
//

#import "UnityAdsiOS4.h"
#import "UnityAdsCampaign/UnityAdsCampaignManager.h"
#import "UnityAdsCampaign/UnityAdsCampaign.h"
#import "UnityAdsCampaign/UnityAdsRewardItem.h"
#import "UnityAdsOpenUDID/UnityAdsOpenUDID.h"
#import "UnityAdsData/UnityAdsAnalyticsUploader.h"
#import "UnityAdsViewManager.h"
#import "UnityAdsDevice/UnityAdsDevice.h"
#import "UnityAdsProperties/UnityAdsProperties.h"

@interface UnityAdsiOS4 () <UnityAdsCampaignManagerDelegate, UIWebViewDelegate, UIScrollViewDelegate, UnityAdsViewManagerDelegate>
//@property (nonatomic, strong) UnityAdsCampaignManager *campaignManager;
@property (nonatomic, strong) UnityAdsAnalyticsUploader *analyticsUploader;

/*
@property (nonatomic, strong) UnityAdsRewardItem *rewardItem;
@property (nonatomic, strong) NSString *gameId;
*/

/*
@property (nonatomic, strong) NSString *campaignJSON;
@property (nonatomic, strong) NSString *machineName;
@property (nonatomic, strong) NSString *md5AdvertisingIdentifier;
@property (nonatomic, strong) NSString *md5DeviceId;
@property (nonatomic, strong) NSString *md5MACAddress;
@property (nonatomic, strong) NSString *md5OpenUDID;
@property (nonatomic, strong) NSString *campaignQueryString;
@property (nonatomic, strong) NSString *gamerID;
@property (nonatomic, strong) NSString *connectionType;
 */
@property (nonatomic, strong) NSThread *backgroundThread;

/*
@property (nonatomic, strong) NSArray *campaigns;
*/

@property (nonatomic, assign) BOOL webViewInitialized;
@property (nonatomic, assign) BOOL testModeEnabled;
@property (nonatomic, assign) dispatch_queue_t queue;
@end

@implementation UnityAdsiOS4

#pragma mark - Private

/*
- (NSString *)_queryString
{
	NSString *advertisingIdentifier = self.md5AdvertisingIdentifier != nil ? self.md5AdvertisingIdentifier : @"";
  NSString *queryParams = @"?";
  
  queryParams = [NSString stringWithFormat:@"%@deviceId=%@&platform=%@&gameId=%@", queryParams, self.md5DeviceId, @"ios", self.gameId];
  
  if (self.md5AdvertisingIdentifier != nil)
    queryParams = [NSString stringWithFormat:@"%@&advertisingTrackingId=%@", queryParams, advertisingIdentifier];

  if ([UnityAdsDevice canUseTracking]) {
    queryParams = [NSString stringWithFormat:@"%@&softwareVersion=%@&hardwareVersion=%@&deviceType=%@&apiVersion=%@&connectionType=%@", queryParams, [[UIDevice currentDevice] systemVersion], @"unknown", self.machineName, kUnityAdsVersion, self.connectionType];
    if (self.md5AdvertisingIdentifier == nil) {
      queryParams = [NSString stringWithFormat:@"%@&macAddress=%@&openUdid=%@", queryParams, self.md5MACAddress, self.md5OpenUDID];
    }
  }
  
  if (_testModeEnabled) {
    queryParams = [NSString stringWithFormat:@"%@test=true", queryParams];
  }

  return queryParams;
}*/

- (void)_backgroundRunLoop:(id)dummy
{
	@autoreleasepool
	{
		NSPort *port = [[NSPort alloc] init];
		[port scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
		while([[NSThread currentThread] isCancelled] == NO)
		{
			@autoreleasepool
			{
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
			}
		}
	}
}

- (void)_refreshCampaignManager
{
	UAAssert( ! [NSThread isMainThread]);
	//UAAssert(self.campaignManager != nil);
	
	[[UnityAdsProperties sharedInstance] refreshCampaignQueryString];
  //self.campaignManager.queryString = self.campaignQueryString;
	[[UnityAdsCampaignManager sharedInstance] updateCampaigns];
  //[self.campaignManager updateCampaigns];
}

- (void)_startCampaignManager
{
	UAAssert( ! [NSThread isMainThread]);
	
	//self.campaignManager = [[UnityAdsCampaignManager alloc] init];
  [[UnityAdsCampaignManager sharedInstance] setDelegate:self];
	//self.campaignManager.delegate = self;
	[self _refreshCampaignManager];
}

- (void)_startAnalyticsUploader
{
	UAAssert( ! [NSThread isMainThread]);
	
	self.analyticsUploader = [[UnityAdsAnalyticsUploader alloc] init];
	[self.analyticsUploader retryFailedUploads];
}

- (void)_logVideoAnalyticsWithPosition:(VideoAnalyticsPosition)videoPosition campaign:(UnityAdsCampaign *)campaign
{
	if (campaign == nil)
	{
		UALOG_DEBUG(@"Campaign is nil.");
		return;
	}
	
	dispatch_async(self.queue, ^{
		NSString *positionString = nil;
		NSString *trackingString = nil;
		if (videoPosition == kVideoAnalyticsPositionStart)
		{
			positionString = @"video_start";
			trackingString = @"start";
		}
		else if (videoPosition == kVideoAnalyticsPositionFirstQuartile)
			positionString = @"first_quartile";
		else if (videoPosition == kVideoAnalyticsPositionMidPoint)
			positionString = @"mid_point";
		else if (videoPosition == kVideoAnalyticsPositionThirdQuartile)
			positionString = @"third_quartile";
		else if (videoPosition == kVideoAnalyticsPositionEnd)
		{
			positionString = @"video_end";
			trackingString = @"view";
		}
		
    // FIX
    
    /*
		NSString *query = [NSString stringWithFormat:@"applicationId=%@&type=%@&trackingId=%@&providerId=%@", self.gameId, positionString, self.gamerID, campaign.id];
		
		[self.analyticsUploader performSelector:@selector(sendViewReportWithQueryString:) onThread:self.backgroundThread withObject:query waitUntilDone:NO];
		
		if (trackingString != nil)
		{
			NSString *trackingQuery = [NSString stringWithFormat:@"%@/%@/%@?gameId=%@", self.gamerID, trackingString, campaign.id, self.gameId];
			[self.analyticsUploader performSelector:@selector(sendTrackingCallWithQueryString:) onThread:self.backgroundThread withObject:trackingQuery waitUntilDone:NO];
		}*/
	});
}

- (BOOL)_adViewCanBeShown
{
  if ([[UnityAdsCampaignManager sharedInstance] campaigns] != nil && [[[UnityAdsCampaignManager sharedInstance] campaigns] count] > 0 && [[UnityAdsCampaignManager sharedInstance] rewardItem] != nil && self.webViewInitialized)
		return YES;
	else
		return NO;
  
  return NO;
}

- (void)_notifyDelegateOfCampaignAvailability
{
	if ([self _adViewCanBeShown])
	{
		if ([self.delegate respondsToSelector:@selector(unityAdsFetchCompleted:)])
			[self.delegate unityAdsFetchCompleted:self];
	}
}

- (void)_trackInstall
{
	if ([[UnityAdsProperties sharedInstance] adsGameId] == nil)
	{
		UALOG_ERROR(@"Unity Ads has not been started properly. Launch with -startWithGameId: first.");
		return;
	}
	
	dispatch_async(self.queue, ^{
		
    // FIX
    
    NSString *queryString = [NSString stringWithFormat:@"%@/install", [[UnityAdsProperties sharedInstance] adsGameId]];
		// NSString *bodyString = [NSString stringWithFormat:@"deviceId=%@", self.md5DeviceId];
		//NSDictionary *queryDictionary = @{ kUnityAdsQueryDictionaryQueryKey : queryString, kUnityAdsQueryDictionaryBodyKey : bodyString };
		/*
		[self.analyticsUploader performSelector:@selector(sendInstallTrackingCallWithQueryDictionary:) onThread:self.backgroundThread withObject:queryDictionary waitUntilDone:NO];*/
	});
}

- (void)_refresh
{
	if ([[UnityAdsProperties sharedInstance] adsGameId] == nil)
	{
		UALOG_ERROR(@"Unity Ads has not been started properly. Launch with -startWithGameId: first.");
		return;
	}
	
	UALOG_DEBUG(@"");
	
	dispatch_async(self.queue, ^{
		[[UnityAdsProperties sharedInstance] refreshCampaignQueryString];
    
		[self performSelector:@selector(_refreshCampaignManager) onThread:self.backgroundThread withObject:nil waitUntilDone:NO];
		[self.analyticsUploader performSelector:@selector(retryFailedUploads) onThread:self.backgroundThread withObject:nil waitUntilDone:NO];
	});
}

#pragma mark - Public

- (void)setTestMode:(BOOL)testModeEnabled {
  _testModeEnabled = testModeEnabled;
}

- (void)startWithGameId:(NSString *)gameId
{
	UAAssert([NSThread isMainThread]);
	
	if (gameId == nil || [gameId length] == 0)
	{
		UALOG_ERROR(@"gameId empty or not set.");
		return;
	}
	
	if ([[UnityAdsProperties sharedInstance] adsGameId] != nil)
		return;
	
	[[UnityAdsProperties sharedInstance] setAdsGameId:gameId];
	self.queue = dispatch_queue_create("com.unity3d.ads", NULL);
	
	dispatch_async(self.queue, ^{
		self.backgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(_backgroundRunLoop:) object:nil];
		[self.backgroundThread start];

		[self performSelector:@selector(_startCampaignManager) onThread:self.backgroundThread withObject:nil waitUntilDone:NO];
		[self performSelector:@selector(_startAnalyticsUploader) onThread:self.backgroundThread withObject:nil waitUntilDone:NO];
		
    dispatch_sync(dispatch_get_main_queue(), ^{
      [[UnityAdsViewManager sharedInstance] setDelegate:self];
		});
	});
}

- (UIView *)adsView
{
	UAAssertV([NSThread mainThread], nil);
	
	if ([self _adViewCanBeShown])
	{
		UIView *adView = [[UnityAdsViewManager sharedInstance] adView];
		if (adView != nil)
		{
			if ([self.delegate respondsToSelector:@selector(unityAdsWillShow:)])
				[self.delegate unityAdsWillShow:self];

			return adView;
		}
	}
	
	return nil;
}

- (BOOL)canShow
{
	UAAssertV([NSThread mainThread], NO);
	return [self _adViewCanBeShown];
}

- (void)stopAll
{
	UAAssert([NSThread isMainThread]);
  [[UnityAdsCampaignManager sharedInstance] performSelector:@selector(cancelAllDownloads) onThread:self.backgroundThread withObject:nil waitUntilDone:NO];
}

- (void)trackInstall
{
	UAAssert([NSThread isMainThread]);
	[self _trackInstall];
}

- (void)refresh
{
	UAAssert([NSThread isMainThread]);
	
	if ([[UnityAdsViewManager sharedInstance] adViewVisible])
		UALOG_DEBUG(@"Ad view visible, not refreshing.");
	else
		[self _refresh];
}

- (void)dealloc
{
	[[UnityAdsCampaignManager sharedInstance] setDelegate:nil];
	[[UnityAdsViewManager sharedInstance] setDelegate:nil];
  [[UnityAdsWebAppController sharedInstance] setDelegate:nil];
	
	dispatch_release(self.queue);
}

#pragma mark - UnityAdsCampaignManagerDelegate

- (void)campaignManager:(UnityAdsCampaignManager *)campaignManager updatedWithCampaigns:(NSArray *)campaigns rewardItem:(UnityAdsRewardItem *)rewardItem gamerID:(NSString *)gamerID
{
	UAAssert([NSThread isMainThread]);
	UALOG_DEBUG(@"");
	
	[[UnityAdsProperties sharedInstance] setRewardItem:rewardItem];
	[self _notifyDelegateOfCampaignAvailability];
}


/*
- (void)campaignManager:(UnityAdsCampaignManager *)campaignManager campaignData:(NSDictionary *)data
{
	UAAssert([NSThread isMainThread]);

  // If the view manager already has campaign JSON data, it means that
	// campaigns were updated, and we might want to update the webapp.
	if ([[UnityAdsViewManager sharedInstance] campaignJSON] != nil) {
		self.webViewInitialized = NO;
	}
  
  if (self.webViewInitialized == NO) {
    [[UnityAdsViewManager sharedInstance] loadWebView];
  }
  
  // FIX (SHOULD NOT EVEN SET THE CAMPAIGN DATA)
  [[UnityAdsViewManager sharedInstance] setCampaignJSON:data];
}*/

- (void)campaignManagerCampaignDataReceived {
  // FIX (remember the "update campaigns")
  UALOG_DEBUG(@"CAMPAIGN DATA RECEIVED");
  [[UnityAdsViewManager sharedInstance] initWebApp];
}

 
#pragma mark - UnityAdsViewManagerDelegate

- (void)viewManager:(UnityAdsViewManager *)viewManager loggedVideoPosition:(VideoAnalyticsPosition)videoPosition campaign:(UnityAdsCampaign *)campaign
{
	UAAssert([NSThread isMainThread]);
	UALOG_DEBUG(@"");
	
  [self _logVideoAnalyticsWithPosition:videoPosition campaign:campaign];
}

- (UIViewController *)viewControllerForPresentingViewControllersForViewManager:(UnityAdsViewManager *)viewManager
{
	UAAssertV([NSThread isMainThread], nil);
	UALOG_DEBUG(@"");
	
	return [self.delegate viewControllerForPresentingViewControllersForAds:self];
}

- (void)viewManagerStartedPlayingVideo {
	UAAssert([NSThread isMainThread]);
	UALOG_DEBUG(@"");
	
	if ([self.delegate respondsToSelector:@selector(unityAdsVideoStarted:)])
		[self.delegate unityAdsVideoStarted:self];
}

- (void)viewManagerVideoEnded {
	UAAssert([NSThread isMainThread]);
	UALOG_DEBUG(@"");
	
	[self.delegate unityAds:self completedVideoWithRewardItemKey:[[UnityAdsProperties sharedInstance] rewardItem].key];
}

- (void)viewManagerWillCloseAdView {
	UAAssert([NSThread isMainThread]);
	UALOG_DEBUG(@"");
	
	if ([self.delegate respondsToSelector:@selector(unityAdsWillHide:)])
		[self.delegate unityAdsWillHide:self];
}

- (void)viewManagerWebViewInitialized {
	UAAssert([NSThread isMainThread]);	
	UALOG_DEBUG(@"");
	
	self.webViewInitialized = YES;	
	[self _notifyDelegateOfCampaignAvailability];
}

@end