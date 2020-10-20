#import "VideoEditorViewManager.h"


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
    return VideoEditorViewManager.sdk.vevController.view;
}

@end
