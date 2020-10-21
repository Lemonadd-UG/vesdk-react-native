#import "RNVideoEditorSDK.h"
#import <React/RCTViewManager.h>

@interface VideoEditorViewManager : RCTViewManager

@property (class) RNVideoEditorSDK *sdk;


+(void)setSdk:(RNVideoEditorSDK *)sdk;
+(RNVideoEditorSDK*)sdk;

@end
