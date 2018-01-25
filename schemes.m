/*
  to compile: clang -fmodules schemes.m -o schemes
  then run `./schemes`
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

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
            NSLog(@"%@:", scheme);

            for (CFIndex j = 0, bundle_count = CFArrayGetCount(handlers); j < bundle_count; j++) {
                CFStringRef handler = CFArrayGetValueAtIndex(handlers, j);
                NSLog(@"\t%@ (%@)", handler, [workspace absolutePathForAppBundleWithIdentifier:(__bridge NSString *)handler]);
            }
        }
        NSLog(@"\n");
    }
    return 0;
}

