//
//  WebViewBinded.h
//  MacLOR
//
//  Created by Farcaller on 25.09.08.
//  Copyright 2008 Hack&Dev FSO. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface WebViewBinded : WebView {
	id observedObjectForSource;
	NSString *observedKeyPathForSource;
	IBOutlet NSArrayController *myController;
}

@end
