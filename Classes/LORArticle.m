//
//  LORArticle.m
//  MacLOR
//
//  Created by Farcaller on 25.09.08.
//  Copyright 2008 Hack&Dev FSO. All rights reserved.
//

#import "LORArticle.h"
#import "LORComment.h"

@implementation LORArticle

@synthesize properties;

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
	[NSString stringWithFormat:@"<LORArticle instance for id %@>", [properties objectForKey:@"id"]];
}

- (id)initWithId:(NSNumber*)i title:(NSString*)t author:(NSString*)a
			date:(NSString*)d tags:(NSArray*)ta body:(NSString*)b
{
	self = [self init];
	
	[properties setValue:t forKey:@"title"];
	[properties setValue:a forKey:@"author"];
	[properties setValue:d forKey:@"date"];
	[properties setValue:ta forKey:@"tags"];
	[properties setValue:b forKey:@"body"];
	[properties setValue:i forKey:@"id"];
	
	return self;
}

- (NSMutableArray*)comments
{
	return [[comments retain] autorelease];
}

- (void)setComments:(NSMutableArray*)c
{
	[c retain];
	[self willChangeValueForKey:@"comments"];
	[comments release];
	comments = c;
	[self didChangeValueForKey:@"comments"];
	NSLog(@"comments set: %@", c);
}

- (void)dealloc
{
	[properties release];
	[comments release];
	[super dealloc];
}

@end
