#import "LORController.h"
#import "LORArticle.h"
#import "LORComment.h"
#import <RegexKit/RegexKit.h>

#define LOR_WEB @"http://www.linux.org.ru/"
#define LOR_LOCAL @"file:///Users/farcaller/Developer/MacLOR/xslt/tidy-index.html"

#define LOR_COMMENTS_URL @"http://www.linux.org.ru/view-message.jsp?msgid=%@&page=-1"
#define LOR_NEWS_URL LOR_WEB

enum CommentStates {
	C_COMMENT,
	C_TITLE1,
	C_TITLE2,
	C_MSG
};

@implementation LORController

- (void)awakeFromNib
{
	
	[topicController
	 addObserver:self
	 forKeyPath:@"selection"
	 options:NSKeyValueObservingOptionNew
	 context:NULL];
	
	
	[self willChangeValueForKey:@"loadingTopics"];
	loadingTopics = YES;
	[self didChangeValueForKey:@"loadingTopics"];
	
	[NSThread
	 detachNewThreadSelector:@selector(updateTopicsList:)
	 toTarget:self
	 withObject:nil];
	
	//[self willChangeValueForKey:@"topics"];
	//topics = [NSArray arrayWithObjects:@"1", @"2", @"3", nil];
	//[self didChangeValueForKey:@"topics"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == topicController && [keyPath isEqualToString:@"selection"]) {
		if([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeSetting) {
			LORArticle *a = [[topicController selection] valueForKey:@"self"];
			NSLog(@"KVO fired for %@", a);
			if([a class] == [LORArticle class])
			[NSThread
			 detachNewThreadSelector:@selector(updateCommentsList:)
			 toTarget:self
			 withObject:[a retain]];
		} else {
			NSLog(@"not requested KVO change for %@ %@ %@", object, keyPath, change);
		}
	} else {
		NSLog(@"not requested KVO for %@ %@ %@", object, keyPath, change);
	}
}

- (void)parseSign:(NSXMLElement*)node author:(NSString**)a date:(NSString**)d
{
	NSString *firstLine = [node description];
	NSRange r = [firstLine rangeOfString:@"\n"];
	if(r.location != NSNotFound)
		firstLine = [firstLine substringToIndex:r.location];
	NSString *author = [firstLine
			  stringByMatching:@".*sign\">([^ \\(]+).*"
			  replace:RKReplaceAll
			  withReferenceString:@"$1"];
	NSString *date = [firstLine
			  stringByMatching:@".*</a>\\) \\(([^\\)]+)\\).*"
			  replace:RKReplaceAll
			  withReferenceString:@"$1"];
	/*
	NSString *author = [[node childAtIndex:0] stringValue];
	NSString *date = [[node childAtIndex:2] stringValue];
	author = [[author substringToIndex:[author length]-1]
			  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	date = [[date substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	*/
	*a = author;
	*d = date;
}

- (void)updateCommentsList:(LORArticle*)topic
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // new thread - own pool
	NSError *err;
	
	NSXMLDocument *doc = [[NSXMLDocument alloc]
						  initWithContentsOfURL:[NSURL URLWithString:
						  [NSString stringWithFormat:LOR_COMMENTS_URL, [topic.properties valueForKey:@"id"]]]
						  options:NSXMLDocumentTidyHTML
						  error:&err];
	if(!doc) {
		// load failed
		[err retain];
		[self
		 performSelector:@selector(failCommentsListWithError:)
		 onThread:[NSThread mainThread]
		 withObject:err
		 waitUntilDone:YES];
		goto fail1;
	}
	
	NSXMLElement *root = [doc rootElement];
	NSArray *commentNode = [root
						  nodesForXPath:@"/html/body/div/div[@class='comment']"
						  error:&err];
	if(err) {
		// xpath failed
		[err retain];
		[self
		 performSelector:@selector(failCommentsListWithError:)
		 onThread:[NSThread mainThread]
		 withObject:err
		 waitUntilDone:YES];
		goto fail2;
	}
	
	NSArray *commentNodes = [[commentNode objectAtIndex:0] children];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	NSMutableArray *cl = [[NSMutableArray alloc] init];
	enum CommentStates state;
	NSNumber *cid;
	NSNumber *pcid;
	
	for(NSXMLElement *node in commentNodes) {
		if([node kind] == NSXMLCommentKind) {
			state = C_COMMENT;
			cid = [NSNumber
				   numberWithInteger:[[[node stringValue]
				   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
									  integerValue]];
		} else {
			NSString *tagClass = [[node attributeForName:@"class"] stringValue];
			if([tagClass isEqualToString:@"title"]) {
				switch(state) {
					case C_COMMENT:
						state = C_TITLE1;
						pcid = nil;
						break;
					case C_TITLE1:
						state = C_TITLE2;
						NSString *s = [[[node childAtIndex:1] attributeForName:@"onclick"] stringValue];
						s = [s
							 stringByMatching:@".*\\((\\d+)\\).*"
							 replace:RKReplaceAll
							 withReferenceString:@"$1"];
						pcid = [NSNumber numberWithInteger:[s integerValue]];
						break;
					default:
						NSLog(@"title class in state %d!", state);
						break;
				}
			} else if([tagClass isEqualToString:@"msg"]) {
				//BOOL rootComment = NO;
				switch(state) {
					case C_TITLE1:
						//rootComment = YES;
					case C_TITLE2: {
						NSString *title = [[[[node childAtIndex:0] childAtIndex:0]
										   stringValue] stringByTrimmingCharactersInSet:
										   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
						NSMutableString *msgHtml = [NSMutableString string];
						NSXMLElement *n = [node childAtIndex:1];
						NSXMLNode *attr;
						while(1) {
							if([n class] == [NSXMLElement class]) {
								attr = [n attributeForName:@"class"];
								if(attr && [[attr stringValue] isEqualToString:@"sign"])
									break;
							}
							[msgHtml appendString:[n description]];
							n = [n nextSibling];
						}
						
						NSString *author;
						NSString *date;
						[self parseSign:n author:&author date:&date];
						
						LORComment *co = [[LORComment alloc]
										  initWithId:cid
										  parent:pcid
										  title:title
										  author:author
										  date:date
										  body:msgHtml];
						[dict setObject:co forKey:cid];
						if(pcid != nil) {
							LORComment *pco = [dict objectForKey:pcid];
							assert(pco != nil);
							[[pco comments] addObject:co];
						} else {
							[cl addObject:co];
						}
						[co release];
						}
						break;
					default:
						NSLog(@"msg class in state %d!", state);
						break;
				}
			} else {
				NSLog(@"Unknown tag class in tree: %@", tagClass);
			}
		}
	}
	[self
	 performSelector:@selector(setCommentList:)
	 onThread:[NSThread mainThread]
	 withObject:[[NSArray alloc] initWithObjects:topic, cl, nil]
	 waitUntilDone:YES];
	
	[dict release];
fail2:
	[doc release];
fail1:
	[topic release];
	[pool release];	
}

- (void)setCommentList:(NSArray*)list
{
	((LORArticle*)[list objectAtIndex:0]).comments = [list objectAtIndex:1];
	[list release];
}

- (void)updateTopicsList:(id)unused
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // new thread - own pool
	NSError *err;
	
	NSXMLDocument *doc = [[NSXMLDocument alloc]
						  initWithContentsOfURL:[NSURL URLWithString:LOR_NEWS_URL]
						  options:NSXMLDocumentTidyHTML
						  error:&err];
	if(!doc) {
		// load failed
		[err retain];
		[self
		 performSelector:@selector(failTopicListWithError:)
		 onThread:[NSThread mainThread]
		 withObject:err
		 waitUntilDone:YES];
		goto fail1;
	}
	// loaded ok, getting the required nodes
	NSXMLElement *root = [doc rootElement];
	NSArray *newsNodes = [root
						  nodesForXPath:@"/html/body/div/div/div[@class='news']"
						  error:&err];
	if(err) {
		// xpath failed
		[err retain];
		[self
		 performSelector:@selector(failTopicListWithError:)
		 onThread:[NSThread mainThread]
		 withObject:err
		 waitUntilDone:YES];
		goto fail2;
	}
	
	NSMutableArray *tl = [[NSMutableArray alloc] init];
	for(NSXMLElement *node in newsNodes) {
		NSString *url = [[[[node childAtIndex:0] childAtIndex:0] attributeForName:@"href"] stringValue];
		url = [url
			   // view-message.jsp?msgid=3119159&lastmod=1222370114354
			   stringByMatching:@".*msgid=(\\d+)&.*"
			   replace:RKReplaceAll
			   withReferenceString:@"$1"];
		NSString *title = [[[[node childAtIndex:0] childAtIndex:0] childAtIndex:0] stringValue];
		NSXMLElement *body = [node childAtIndex:2];
		NSString *msgHtml = [[body childAtIndex:0] description];
		NSMutableArray *tags = [NSMutableArray array];
		for(NSXMLElement *tag in [[body childAtIndex:2] children]) {
			if([tag childCount] == 1) {
				[tags addObject:[[tag childAtIndex:0] stringValue]];
			}
		}
		NSString *author;
		NSString *date;
		[self parseSign:[body childAtIndex:3] author:&author date:&date];
		
		// need to clean url:    parse post id
		//               author: remote trailing '('
		//               date:   remove leading ') ' and trailing '\n'
		// title, msgHtml and tags are ready for use as is
		
		//NSLog(@"Parsed article '%@' by '%@' at '%@'\nTags: %@\nBody: %d bytes long",
		//	  title, author, date, tags, [msgHtml length]);
		
		LORArticle *a = [[LORArticle alloc]
						 initWithId:[NSNumber numberWithInteger:[url integerValue]]
						 title:title
						 author:author
						 date:date
						 tags:tags
						 body:msgHtml];
		[tl addObject:a];
		[a release];
	}
	
	[self
	 performSelector:@selector(setTopicList:)
	 onThread:[NSThread mainThread]
	 withObject:tl
	 waitUntilDone:NO];
	// we don't release tl, as it's ownership passed to self.topics in main thread

fail2:
	[doc release];
fail1:
	[pool release];
}

- (void)failCommentsListWithError:(NSError *)err
{
	NSAlert *alt = [NSAlert alertWithError:err];
	[alt runModal];
	[err release];
}

- (void)failTopicListWithError:(NSError *)err
{
	[self willChangeValueForKey:@"loadingTopics"];
	loadingTopics = NO;
	[self didChangeValueForKey:@"loadingTopics"];
	NSAlert *alt = [NSAlert alertWithError:err];
	[alt runModal];
	[err release];
}

- (void)setTopicList:(NSArray*)list
{
	[self willChangeValueForKey:@"topics"];
	[self willChangeValueForKey:@"loadingTopics"];
	[topics release];
	topics = list;
	
	loadingTopics = NO;
	[self didChangeValueForKey:@"loadingTopics"];
	[self didChangeValueForKey:@"topics"];
}

@end
