#import <Cocoa/Cocoa.h>

@interface LORController : NSObject {
	NSMutableArray *topics;
	Boolean loadingTopics;
	
	IBOutlet NSArrayController *topicController;
}

- (void)awakeFromNib;

@end
