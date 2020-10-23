#import "RNVideoEditorSDK.h"
#import "RNImglyKit.h"
#import "RNImglyKitSubclass.h"
#import "VideoEditorViewManager.h"
#import "RNVideoEditorSDKDelegate.h"

@interface RNVideoEditorSDK () <PESDKVideoEditViewControllerDelegate>

@end

@implementation RNVideoEditorSDK {
    PESDKPhotoEditToolController *vetController;
}

RCT_EXPORT_MODULE();

+ (RNVESDKConfigurationBlock)configureWithBuilder {
  return RN_IMGLY_ImglyKit.configureWithBuilder;
}

+ (void)setConfigureWithBuilder:(RNVESDKConfigurationBlock)configurationBlock {
  RN_IMGLY_ImglyKit.configureWithBuilder = configurationBlock;
}

static RNVESDKWillPresentBlock _willPresentVideoEditViewController = nil;

+ (RNVESDKWillPresentBlock)willPresentVideoEditViewController {
  return _willPresentVideoEditViewController;
}

+ (void)setWillPresentVideoEditViewController:(RNVESDKWillPresentBlock)willPresentBlock {
  _willPresentVideoEditViewController = willPresentBlock;
}

- (void)present:(nonnull PESDKVideo *)video withConfiguration:(nullable NSDictionary *)dictionary andSerialization:(nullable NSDictionary *)state
        resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
  [self present:^PESDKMediaEditViewController * _Nullable(PESDKConfiguration * _Nonnull configuration, NSData * _Nullable serializationData) {

    PESDKPhotoEditModel *photoEditModel = [[PESDKPhotoEditModel alloc] init];

    if (serializationData != nil) {
      PESDKDeserializationResult *deserializationResult = [PESDKDeserializer deserializeWithData:serializationData imageDimensions:video.size assetCatalog:configuration.assetCatalog];
      photoEditModel = deserializationResult.model ?: photoEditModel;
    }

    PESDKVideoEditViewController *videoEditViewController = [[PESDKVideoEditViewController alloc] initWithVideoAsset:video
                                                                                                       configuration:configuration
                                                                                                      photoEditModel:photoEditModel];
    self.vevController = videoEditViewController;
    [VideoEditorViewManager setSdk:self];
    [self customizeVevController];
    videoEditViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    videoEditViewController.delegate = self;
    RNVESDKWillPresentBlock willPresentVideoEditViewController = RNVideoEditorSDK.willPresentVideoEditViewController;
    if (willPresentVideoEditViewController != nil) {
      willPresentVideoEditViewController(videoEditViewController);
    }
    return videoEditViewController;

  } withUTI:^CFStringRef _Nonnull(PESDKConfiguration * _Nonnull configuration) {

    return configuration.videoEditViewControllerOptions.videoContainerFormatUTI;

  } configuration:dictionary serialization:state resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(unlockWithLicenseURL:(nonnull NSURL *)url)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    [VESDK unlockWithLicenseFromURL:url error:&error];
    [self handleLicenseError:error];
  });
}

RCT_EXPORT_METHOD(unlockWithLicenseString:(nonnull NSString *)string)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    [VESDK unlockWithLicenseFromString:string error:&error];
    [self handleLicenseError:error];
  });
}

RCT_EXPORT_METHOD(unlockWithLicenseObject:(nonnull NSDictionary *)dictionary)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSError *error = nil;
    [VESDK unlockWithLicenseFromDictionary:dictionary error:&error];
    [self handleLicenseError:error];
  });
}

RCT_EXPORT_METHOD(unlockWithLicense:(nonnull id)json)
{
  [super unlockWithLicense:json];
}

RCT_EXPORT_METHOD(present:(nonnull NSURLRequest *)request
                  configuration:(nullable NSDictionary *)configuration
                  serialization:(nullable NSDictionary *)state
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  // TODO: Handle React Native URLs from camera roll.
  if (request.URL.isFileURL) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:request.URL.path]) {
      reject(RN_IMGLY.kErrorUnableToLoad, @"File does not exist", nil);
      return;
    }
  }
  PESDKVideo *video = [[PESDKVideo alloc] initWithURL:request.URL];
  [self present:video withConfiguration:configuration andSerialization:state resolve:resolve reject:reject];
}

#pragma mark - PESDKVideoEditViewControllerDelegate

- (void)videoEditViewController:(nonnull PESDKVideoEditViewController *)videoEditViewController didFinishWithVideoAtURL:(nullable NSURL *)url {
  NSError *error = nil;
  id serialization = nil;

  if (self.serializationEnabled)
  {
    NSData *serializationData = [videoEditViewController serializedSettings];
    if ([self.serializationType isEqualToString:RN_IMGLY.kExportTypeFileURL]) {
      if ([serializationData RN_IMGLY_writeToURL:self.serializationFile andCreateDirectoryIfNecessary:YES error:&error]) {
        serialization = self.serializationFile.absoluteString;
      }
    } else if ([self.serializationType isEqualToString:RN_IMGLY.kExportTypeObject]) {
      serialization = [NSJSONSerialization JSONObjectWithData:serializationData options:kNilOptions error:&error];
    }
  }

  RCTPromiseResolveBlock resolve = self.resolve;
  RCTPromiseRejectBlock reject = self.reject;
  if (error == nil) {
    resolve(@{ @"video": (url != nil) ? url.absoluteString : [NSNull null],
               @"hasChanges": @(videoEditViewController.hasChanges),
               @"serialization": (serialization != nil) ? serialization : [NSNull null] });
  } else {
      reject(RN_IMGLY.kErrorUnableToExport, [NSString RN_IMGLY_string:@"Unable to export video or serialization." withError:error], error);
  }
}

- (void)videoEditViewControllerDidCancel:(nonnull PESDKVideoEditViewController *)videoEditViewController {
  RCTPromiseResolveBlock resolve = self.resolve;
  [self dismiss:videoEditViewController animated:YES completion:^{
    resolve([NSNull null]);
  }];
}

- (void)videoEditViewControllerDidFailToGenerateVideo:(nonnull PESDKVideoEditViewController *)videoEditViewController {
  RCTPromiseRejectBlock reject = self.reject;
  [self dismiss:videoEditViewController animated:YES completion:^{
    reject(RN_IMGLY.kErrorUnableToExport, @"Unable to generate video", nil);
  }];
}

- (void)mediaEditViewController:(PESDKMediaEditViewController *)mediaEditViewController willPresentToolController:(PESDKPhotoEditToolController *)toolController {
    vetController = toolController;
    if(_delegate != nil) {
        [_delegate toolWillBecomeActive:NSStringFromClass([toolController class])];
    }
}
#pragma mark - BouncyCustom

- (void)customizeVevController {
    [_vevController.menuViewController hideMenuWithAnimated:false];
    [_vevController.toolbar setHidden:true];
    _vevController.mediaEditPreviewController.previewView.layer.cornerRadius = 10;
    _vevController.mediaEditPreviewController.previewView.layer.masksToBounds = true;
}

RCT_EXPORT_METHOD(showToolFilter) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController presentToolFor:PESDKToolMenuItem.createFilterToolItem];
    });
}

RCT_EXPORT_METHOD(showToolTrim) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController presentToolFor:PESDKToolMenuItem.createTrimToolItem];
    });
}

RCT_EXPORT_METHOD(showToolText) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController presentToolFor:PESDKToolMenuItem.createTextToolItem];
    });
}

RCT_EXPORT_METHOD(showToolSticker) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController presentToolFor:PESDKToolMenuItem.createStickerToolItem];
    });
}

RCT_EXPORT_METHOD(showToolTextDesign) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController presentToolFor:PESDKToolMenuItem.createTextDesignToolItem];
    });
}

RCT_EXPORT_METHOD(undo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController.undoController undo];
    });
}

RCT_EXPORT_METHOD(redo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController.undoController redo];
    });
}

RCT_EXPORT_METHOD(discardTool) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->vetController != nil) {
            [self->vetController discard:self->vetController.toolbarItem];
            self->vetController = nil;
        }
    });
}

RCT_EXPORT_METHOD(applyTool) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->vetController != nil) {
            [self->vetController apply:self->vetController.toolbarItem];
            self->vetController = nil;
        }
    });
}

RCT_EXPORT_METHOD(renderHighResolutionVariant) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.vevController renderHighResolutionVariant];
    });
}

RCT_EXPORT_METHOD(pausePreview) {
    [self.vevController pause];
}

RCT_EXPORT_METHOD(playPreview) {
    [self.vevController play];
}

@end
