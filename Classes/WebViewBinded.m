//
//  WebViewBinded.m
//  MacLOR
//
//  Created by Farcaller on 25.09.08.
//  Copyright 2008 Hack&Dev FSO. All rights reserved.
//

#import "WebViewBinded.h"

static void *SourceBindingIdentifier = (void *)@"WebViewSource";

@implementation WebViewBinded

- (void)dealloc {
	[self unbind:@"source"];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[self
	 bind:@"source"
	 toObject:myController
	 withKeyPath:@"selection.properties.body"
	 options:nil];
}

- (NSArray *)exposedBindings {
	NSMutableArray *bindingNames = [NSMutableArray arrayWithArray:[super
																   exposedBindings]];
	
	[bindingNames addObject:@"source"];
	return bindingNames;
}

- (Class)valueClassForBinding:(NSString *)binding {
	if([binding isEqualToString:@"source"])
		return [NSString class];
	else
		return [super valueClassForBinding:binding];
}

- (void)bind:(NSString *)binding
	toObject:(id)observableObject
 withKeyPath:(NSString *)keyPath
	 options:(NSDictionary *)options {
	
	// Observe the observableObject for changes -- note, pass binding identifier
	// as the context, so you get that back in observeValueForKeyPath:...
	// This way you can easily determine what needs to be updated.
	
	if([binding isEqualToString:@"source"]) {
		[observableObject addObserver:self
						   forKeyPath:keyPath
							  options:0
							  context:SourceBindingIdentifier];
		
		// Register what object and what keypath are associated with this binding
		observedObjectForSource = [observableObject retain];
		observedKeyPathForSource = [keyPath copy];
	} else {
		[super bind:binding toObject:observableObject withKeyPath:keyPath
			options:options];
	}
	
}    

- (NSDictionary *)infoForBinding:(NSString *)binding {
	if([binding isEqualToString:@"source"]) {
		return [NSDictionary
		 dictionaryWithObjectsAndKeys:observedObjectForSource,NSObservedObjectKey,
		 observedKeyPathForSource, NSObservedKeyPathKey, nil];
	} else {
		return [super infoForBinding:binding];
	}
}

- (void)unbind:(NSString *)binding {
	if([binding isEqualToString:@"source"]) {
		[observedObjectForSource release];
		[observedKeyPathForSource release];
	} else {
		[super unbind:binding];
	}
}

- (void)updateForMouseEvent:(NSEvent *)event {
    if (observedObjectForSource != nil) {
        NSString *newSource = [(DOMHTMLElement *)[[[self mainFrame]
												   DOMDocument] documentElement] outerHTML];
        
        [observedObjectForSource setValue:newSource
							   forKeyPath:observedKeyPathForSource];
    }    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
    // You passed the binding identifier as the context when registering
    // as an observer--use that to decide what to update...
    if (context == SourceBindingIdentifier) {
        NSString *newSource = [observedObjectForSource
							   valueForKeyPath:observedKeyPathForSource];
		[[self mainFrame] loadHTMLString:newSource baseURL:nil];
    } else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change
							  context:context];
	}
	
}

@end
