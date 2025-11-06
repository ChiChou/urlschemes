/*
  to compile: clang -fmodules schemes.m -o schemes
  then run `./schemes`
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>

#include <stdio.h>

extern OSStatus _LSCopySchemesAndHandlerURLs(CFArrayRef *outSchemes, CFArrayRef *outApps);
extern OSStatus _LSCopyAllApplicationURLs(CFArrayRef *theList);

BOOL isSignedByApple(NSURL *appURL) {
  BOOL result = NO;

  if (!appURL)
    return NO;

  SecStaticCodeRef staticCode = NULL;
  OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)appURL, kSecCSDefaultFlags, &staticCode);

  if (status != errSecSuccess)
    goto cleanup;

  SecRequirementRef requirement = NULL;
  status = SecRequirementCreateWithString(CFSTR("anchor apple"), kSecCSDefaultFlags, &requirement);

  if (status != errSecSuccess)
    goto cleanup;

  status = SecStaticCodeCheckValidity(staticCode, kSecCSDefaultFlags, requirement);
  result = (status == errSecSuccess);

cleanup:

  if (staticCode)
    CFRelease(staticCode);
  if (requirement)
    CFRelease(requirement);

  return result;
}

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

    for (CFIndex i = 0, count = CFArrayGetCount(schemes); i < count; i++) {
      CFStringRef scheme = CFArrayGetValueAtIndex(schemes, i);
      NSString *str = (__bridge NSString *)scheme;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      CFArrayRef handlers = LSCopyAllHandlersForURLScheme(scheme);
#pragma clang diagnostic pop

      if (!handlers)
        continue;

      NSMutableArray *handlersForUrl = [[NSMutableArray alloc] init];
      for (CFIndex j = 0, bundle_count = CFArrayGetCount(handlers); j < bundle_count; j++) {
        CFStringRef handler = CFArrayGetValueAtIndex(handlers, j);
        NSString *bundleId = (__bridge NSString *)handler;

        if (appleOnly) {
          NSURL *bundleURL = [workspace URLForApplicationWithBundleIdentifier:bundleId];
          if (!bundleURL || !isSignedByApple(bundleURL))
            continue;
        }

        [handlersForUrl addObject:bundleId];
      }

      if ([handlersForUrl count]) {
        printf("\n-+-= %s\n", [(__bridge NSString *)scheme UTF8String]);
        for (NSString *bundleId in handlersForUrl) {
          NSURL *bundleURL = [workspace URLForApplicationWithBundleIdentifier:bundleId];
          printf(" |-= %s (%s)\n", [bundleId UTF8String], [bundleURL fileSystemRepresentation]);
        }
      }

      CFRelease(handlers);
    }

    if (schemes)
      CFRelease(schemes);
    if (apps)
      CFRelease(apps);
  }
  return 0;
}
