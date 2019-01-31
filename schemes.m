/*
  to compile: clang -fmodules schemes.m -o schemes
  then run `./schemes`
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <stdio.h>

extern OSStatus _LSCopySchemesAndHandlerURLs(CFArrayRef *outSchemes, CFArrayRef *outApps);
extern OSStatus _LSCopyAllApplicationURLs(CFArrayRef *theList);


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        CFArrayRef schemes;
        CFArrayRef apps;
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        _LSCopySchemesAndHandlerURLs(&schemes, &apps);
        for (CFIndex i = 0, count = CFArrayGetCount(schemes); i < count; i++) {
            CFStringRef scheme = CFArrayGetValueAtIndex(schemes, i);
            CFArrayRef handlers = LSCopyAllHandlersForURLScheme(scheme);
            printf("-+--= %s\n", [(__bridge NSString *)scheme UTF8String]);
            for (CFIndex j = 0, bundle_count = CFArrayGetCount(handlers); j < bundle_count; j++) {
                CFStringRef handler = CFArrayGetValueAtIndex(handlers, j);
                NSString *bundle = [workspace absolutePathForAppBundleWithIdentifier:(__bridge NSString *)handler];
                printf(" |--= %s (%s)\n", [(__bridge NSString *)handler UTF8String], [bundle UTF8String]);
            }
        }
    }
    return 0;
}
