#import "VideoEditorViewManager.h"
#import "RNVideoEditorSDK.h"
#import "RNVideoEditorSDKDelegate.h"
#import "VideoEditorEventManager.h"

@interface VideoEditorViewManager () <RNVideoEditorSDKDelegate>
@end

@implementation VideoEditorViewManager
static RNVideoEditorSDK* _sdk = nil;
static VideoEditorEventManager* _eventManager = nil;

+(void)setSdk:(RNVideoEditorSDK *)sdk {
    _sdk = sdk;
}

+(RNVideoEditorSDK*)sdk {
    return _sdk;
}

RCT_EXPORT_MODULE(VideoEditorView)
-(UIView *)view {
    VideoEditorViewManager.sdk.delegate = self;
    return VideoEditorViewManager.sdk.vevController.view;
}

-(void)toolWillBecomeActive:(NSString*)name {
    if(_eventManager == nil) {
       _eventManager = [VideoEditorEventManager allocWithZone: nil];
       [_eventManager setBridge:self.bridge];
    }
    [_eventManager toolDidBecomeActive:name];
}

@end
