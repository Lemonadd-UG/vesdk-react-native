#import "VideoEditorViewManager.h"
#import "VideoEditorView.h"
#import "RNVideoEditorSDK.h"
#import "RNVideoEditorSDKDelegate.h"

@interface VideoEditorViewManager () <RNVideoEditorSDKDelegate>
@end

@implementation VideoEditorViewManager
static RNVideoEditorSDK* _sdk = nil;

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
    //if(!VideoEditorViewManager.sdk.vevController.view.onToolDidBecomeActive) {
    //    return;
    //}
    //VideoEditorViewManager.sdk.vevController.view.onToolDidBecomeActive(@{@"name": name});
    NSLog(@"%@", name);
}

@end
