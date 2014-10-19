//
//  FindBarView.m
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/18/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <ChromiumTabs/GTMNSColor+Luminance.h>
#import "FindBarView.h"

#define kToolbarTopOffset 35
#define kToolbarMaxHeight 25

@implementation FindBarView

static NSGradient *_gradientFaded = nil;
static NSGradient *_gradientNotFaded = nil;

static NSGradient *_mkGradient(BOOL faded) {
	NSColor* base_color = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
	NSColor* start_color =
	[base_color gtm_colorAdjustedFor:GTMColorationLightHighlight
							   faded:faded];
	NSColor* mid_color =
	[base_color gtm_colorAdjustedFor:GTMColorationLightMidtone
							   faded:faded];
	NSColor* end_color =
	[base_color gtm_colorAdjustedFor:GTMColorationLightShadow
							   faded:faded];
	NSColor* glow_color =
	[base_color gtm_colorAdjustedFor:GTMColorationLightPenumbra
							   faded:faded];
	return [[NSGradient alloc] initWithColorsAndLocations:start_color, 1,
			mid_color, 0.25,
			end_color, 0.5,
			glow_color, 0.75,
			nil];
}

+ (void)load {
	_gradientFaded = _mkGradient(YES);
	_gradientNotFaded = _mkGradient(NO);
}

- (void)drawBackground {
	NSGradient *gradient = [[self window] isKeyWindow] ? _gradientNotFaded :
	_gradientFaded;
	CGFloat winHeight = NSHeight([[self window] frame]);
	NSPoint startPoint =
	[self convertPoint:NSMakePoint(0, winHeight - kToolbarTopOffset)
			  fromView:nil];
	NSPoint endPoint =
	NSMakePoint(0, winHeight - kToolbarTopOffset - kToolbarMaxHeight);
	endPoint = [self convertPoint:endPoint fromView:nil];
	
	[gradient drawFromPoint:startPoint
					toPoint:endPoint
					options:(NSGradientDrawsBeforeStartingLocation |
							 NSGradientDrawsAfterEndingLocation)];
	
	// Draw bottom stroke
	[[self strokeColor] set];
	NSRect borderRect, contentRect;
	NSDivideRect([self bounds], &borderRect, &contentRect, 1, NSMinYEdge);
	NSRectFillUsingOperation(borderRect, NSCompositeSourceOver);
	
}

- (void)drawRect:(NSRect)rect {
	// The toolbar's background pattern is phased relative to the tab strip view's
	// background pattern.
	NSPoint phase = NSZeroPoint;
	[[NSGraphicsContext currentContext] setPatternPhase:phase];
	[self drawBackground];
}

@end
