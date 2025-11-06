import sys
from ctypes.util import find_library
from ctypes import CDLL, Structure, c_bool, c_int32, c_long, c_uint32, c_char_p, c_void_p, POINTER, create_string_buffer


OSStatus = c_int32  # typedef int32_t OSStatus;


class OpaqueType(Structure):
    pass


OpaqueTypeRef = POINTER(OpaqueType)
CFURLRef = OpaqueTypeRef  # typedef const struct __CFURL *CFURLRef;
CFStringRef = OpaqueTypeRef  # typedef const struct __CFString *CFStringRef;
CFErrorRef = OpaqueTypeRef  # typedef const struct __CFError *CFErrorRef;
CFArrayRef = OpaqueTypeRef  # typedef const struct __CFArray *CFArrayRef;
CFIndex = c_long  # typedef long CFIndex;


# declare API

LaunchServices = CDLL(find_library('LaunchServices'))

LaunchServices._LSCopySchemesAndHandlerURLs.argtypes = [
    POINTER(CFArrayRef), POINTER(CFArrayRef)]
LaunchServices._LSCopySchemesAndHandlerURLs.restype = OSStatus

# LaunchServices._LSCopyAllApplicationURLs.argtypes = [POINTER(CFArrayRef)]
# LaunchServices._LSCopyAllApplicationURLs.restype = OSStatus

LaunchServices._LSCopyBundleURLWithIdentifier.argtypes = [CFStringRef]
LaunchServices._LSCopyBundleURLWithIdentifier.restype = CFURLRef

LaunchServices.LSCopyAllHandlersForURLScheme.argtypes = [CFStringRef]
LaunchServices.LSCopyAllHandlersForURLScheme.restype = CFArrayRef

LaunchServices.LSCopyApplicationURLsForBundleIdentifier.argtypes = [
    CFStringRef, POINTER(CFErrorRef)]
LaunchServices.LSCopyApplicationURLsForBundleIdentifier.restype = OSStatus


cf = CDLL(find_library('CoreFoundation'))
cf.CFRelease.argtypes = [c_void_p]
cf.CFRelease.restype = None

cf.CFArrayGetCount.argtypes = [CFArrayRef]
cf.CFArrayGetCount.restype = CFIndex

cf.CFArrayGetValueAtIndex.argtypes = [CFArrayRef, CFIndex]
cf.CFArrayGetValueAtIndex.restype = OpaqueTypeRef

cf.CFStringGetLength.argtypes = [CFStringRef]
cf.CFStringGetLength.restype = CFIndex
cf.CFStringGetCString.argtypes = [CFStringRef, c_char_p, CFIndex, c_uint32]
cf.CFStringGetCString.restype = c_bool

CFURLRef = OpaqueTypeRef
cf.CFURLGetString.argtypes = [CFURLRef]
cf.CFURLGetString.restype = CFStringRef

cf.CFStringCreateWithCString.argtypes = [c_void_p, c_char_p, c_uint32]
cf.CFStringCreateWithCString.restype = CFStringRef

Security = CDLL(find_library('Security'))
Security.SecStaticCodeCreateWithPath.argtypes = [
    CFURLRef, c_uint32, POINTER(OpaqueTypeRef)]
Security.SecStaticCodeCreateWithPath.restype = OSStatus

Security.SecRequirementCreateWithString.argtypes = [
    CFStringRef, c_uint32, POINTER(OpaqueTypeRef)]
Security.SecRequirementCreateWithString.restype = OSStatus

Security.SecStaticCodeCheckValidity.argtypes = [
    OpaqueTypeRef, c_uint32, OpaqueTypeRef]
Security.SecStaticCodeCheckValidity.restype = OSStatus


def cfstr2py(cfstringref):
    str_length = cf.CFStringGetLength(cfstringref) + 1
    buf = create_string_buffer(str_length)
    result = cf.CFStringGetCString(cfstringref, buf, str_length, 0)
    if result:
        return buf.value.decode('utf-8')

    raise ValueError('unable to decode string')


def py2cfstr(s: str) -> CFStringRef:
    # kCFStringEncodingUTF8
    return cf.CFStringCreateWithCString(None, s.encode('utf-8'), 0)


def is_apple(cfurl) -> bool:
    static_code = OpaqueTypeRef()
    status = Security.SecStaticCodeCreateWithPath(
        cfurl, 0, POINTER(OpaqueTypeRef)(static_code))
    if status != 0:
        return False

    requirement = OpaqueTypeRef()
    cfstr = py2cfstr("anchor apple")
    status = Security.SecRequirementCreateWithString(
        cfstr, 0, POINTER(OpaqueTypeRef)(requirement))

    if status != 0:
        Security.CFRelease(static_code)
        return False

    status = Security.SecStaticCodeCheckValidity(
        static_code, 0, requirement)

    Security.CFRelease(static_code)
    Security.CFRelease(requirement)

    return status == 0


filter_apple = '--apple' in sys.argv

schemes = CFArrayRef()
LaunchServices._LSCopySchemesAndHandlerURLs(schemes, None)

count = cf.CFArrayGetCount(schemes)
for i in range(count):
    scheme = cf.CFArrayGetValueAtIndex(schemes, i)
    handlers = LaunchServices.LSCopyAllHandlersForURLScheme(scheme)

    handlers_list: list[tuple[str, str]] = []
    scheme_str = cfstr2py(scheme)

    if not handlers:
        continue

    count_handlers = cf.CFArrayGetCount(handlers)
    for j in range(count_handlers):
        handler = cf.CFArrayGetValueAtIndex(handlers, j)
        bundle_id = cfstr2py(handler)
        cfurl = LaunchServices._LSCopyBundleURLWithIdentifier(handler)
        bundle_url = '(N/A)'

        if cfurl:
            if filter_apple and not is_apple(cfurl):
                cf.CFRelease(cfurl)
                continue

            cfstr = cf.CFURLGetString(cfurl)
            if cfstr:
                bundle_url = cfstr2py(cfstr)
                handlers_list.append((bundle_id, bundle_url))
            cf.CFRelease(cfurl)

    if len(handlers_list):
        print()
        print(f'{scheme_str}://')

        for bundle_id, bundle_url in handlers_list:
            print(f'>  {bundle_id} ({bundle_url})')


    cf.CFRelease(handlers)


cf.CFRelease(schemes)
