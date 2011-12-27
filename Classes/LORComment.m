//
//  LORComment.m
//  MacLOR
//
//  Created by Farcaller on 25.09.08.
//  Copyright 2008 Hack&Dev FSO. All rights reserved.
//

#import "LORComment.h"


@implementation LORComment

@synthesize properties, comments;

- (id)init
{
	if( (self = [super init]) ) {
		properties = [[NSMutableDictionary alloc] init];
		comments = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<LORComment %@ %@>",
			[properties valueForKey:@"id"], comments];
}

- (id)initWithId:(NSNumber*)i parent:(NSNumber*)p title:(NSString*)t author:(NSString*)a
			date:(NSString*)d body:(NSString*)b
{
	self = [self init];
	
	[properties setValue:i forKey:@"id"];
	[properties setValue:p forKey:@"parent"];
	[properties setValue:t forKey:@"title"];
	[properties setValue:a forKey:@"author"];
	[properties setValue:d forKey:@"date"];
	[properties setValue:b forKey:@"body"];
	
	return self;
}

- (void)dealloc
{
	[properties release];
	[comments release];
	[super dealloc];
}

@end
