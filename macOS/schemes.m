/*
  to compile: clang -fmodules schemes.m -o schemes
  then run `./schemes`
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#include <stdio.h>

extern OSStatus _LSCopySchemesAndHandlerURLs(CFArrayRef *outSchemes, CFArrayRef *outApps);
extern OSStatus _LSCopyAllApplicationURLs(CFArrayRef *theList);

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    CFArrayRef schemes = NULL;
    CFArrayRef apps = NULL;

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    BOOL appleOnly = [args containsObject:@"--apple"];

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    OSStatus status = _LSCopySchemesAndHandlerURLs(&schemes, &apps);

    if (status != noErr) {
      fprintf(stderr, "Unable to retrive URL information. Exiting");
      abort();
    }

    NSMutableArray *handlersForUrl = [[NSMutableArray alloc] init];
    for (CFIndex i = 0, count = CFArrayGetCount(schemes); i < count; i++) {
      CFStringRef scheme = CFArrayGetValueAtIndex(schemes, i);
      NSString *str = (__bridge NSString *)scheme;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      CFArrayRef handlers = LSCopyAllHandlersForURLScheme(scheme);
#pragma clang diagnostic pop

      if (!handlers) continue;

      [handlersForUrl removeAllObjects];
      for (CFIndex j = 0, bundle_count = CFArrayGetCount(handlers); j < bundle_count; j++) {
        CFStringRef handler = CFArrayGetValueAtIndex(handlers, j);
        NSString *bundleId = (__bridge NSString *)handler;
        // todo: check signature instead
        if (appleOnly && ![bundleId hasPrefix:@"com.apple."])
          continue;
        [handlersForUrl addObject:bundleId];
      }

      if ([handlersForUrl count]) {
        printf("-+-= %s\n", [(__bridge NSString *)scheme UTF8String]);
        for (NSString *bundleId in handlersForUrl) {
          NSString *path = [workspace absolutePathForAppBundleWithIdentifier:bundleId];
          printf(" |-= %s (%s)\n", [bundleId UTF8String], [path UTF8String]);
        }
      }
    }
  }
  return 0;
}
