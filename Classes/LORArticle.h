//
//  LORArticle.h
//  MacLOR
//
//  Created by Farcaller on 25.09.08.
//  Copyright 2008 Hack&Dev FSO. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LORArticle : NSObject {
	NSMutableDictionary *properties;
	NSMutableArray *comments;
}

@property (readonly,retain) NSDictionary *properties;
@property (readwrite,retain) NSMutableArray *comments;

- (id)init;
- (id)initWithId:(NSNumber*)i title:(NSString*)t author:(NSString*)a date:(NSString*)d tags:(NSArray*)ta body:(NSString*)b;
- (void)dealloc;

@end
