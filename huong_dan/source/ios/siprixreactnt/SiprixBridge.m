#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(SiprixBridge, NSObject)

RCT_EXTERN_METHOD(openSiprixCall:(NSString *)phone
                  username:(NSString *)username
                  password:(NSString *)password)

@end
