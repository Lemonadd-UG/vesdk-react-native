#import "VideoEditorEventManager.h"

@implementation VideoEditorEventManager {
    bool hasListeners;
}

RCT_EXPORT_MODULE();

+ (id)allocWithZone:(NSZone *)zone {
    static VideoEditorEventManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"EventToolActive"];
}

- (void)toolDidBecomeActive:(NSString *)name {
    hasListeners = true;
    if(hasListeners) {
        [self sendEventWithName:@"EventToolActive" body:@{@"name": name}];
    }
}

@end
