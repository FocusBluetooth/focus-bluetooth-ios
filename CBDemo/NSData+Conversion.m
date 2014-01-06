//
//  NSData+Conversion.m
//  CBDemo
//
//  Created by Frank Mao on 2013-11-11.
//
//

#import "NSData+Conversion.h"

@implementation NSData (Conversion)
- (NSString *)hexadecimalString {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

// 64 -> d
-(NSString*)convert:(NSString*)decoded{
    
    unichar unicodeValue = (unichar) strtol([decoded UTF8String], NULL, 16);
    char buffer[2];
    int len = 1;
    
    if (unicodeValue > 127) {
        buffer[0] = (unicodeValue >> 8) & (1 << 8) - 1;
        buffer[1] = unicodeValue & (1 << 8) - 1;
        len = 2;
    } else {
        buffer[0] = unicodeValue;
    }
    
    return [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
    
    
    
}
@end
