#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface VideoEditorEventManager : RCTEventEmitter <RCTBridgeModule>
- (void)toolDidBecomeActive:(NSString *)name;
@end
