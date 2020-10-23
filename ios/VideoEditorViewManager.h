#import <React/RCTViewManager.h>

@class RNVideoEditorSDK;
@interface VideoEditorViewManager : RCTViewManager

@property (class) RNVideoEditorSDK *sdk;

+(void)setSdk:(RNVideoEditorSDK *)sdk;
+(RNVideoEditorSDK*)sdk;
-(void)toolWillBecomeActive:(NSString*)name;

@end
