//
//  FindBarView.m
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/18/14.
//  Copyright (c) 2014 Devin Tuchsen. All rights reserved.
//
//  This file is part of OpenCodeEdit.
//
//  OpenCodeEdit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OpenCodeEdit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
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
