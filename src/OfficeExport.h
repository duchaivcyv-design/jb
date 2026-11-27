#import <Foundation/Foundation.h>

@interface OfficeExport : NSObject
+ (NSURL *)writeTextFile:(NSString *)text error:(NSError **)error;
+ (NSURL *)writeWordFile:(NSString *)text error:(NSError **)error;
@end
