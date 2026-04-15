NS_ASSUME_NONNULL_BEGIN

@interface CC26LocalizableManager : NSObject
+ (NSString *)localizedString:(NSString *)key;
@end

NS_ASSUME_NONNULL_END

#define CC26_LOCALIZABLE(key) [CC26LocalizableManager localizedString:key]