//
//  CodeStyleElement.h
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/14/14.
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

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface CodeStyleElement : NSObject

@property (readwrite) int styleId;
@property (readwrite) NSString *description;
@property (readwrite) NSString *fontName;
@property (readwrite) int fontSize;
@property (readwrite) BOOL bold;
@property (readwrite) BOOL italic;
@property (readwrite) BOOL underline;
@property (readwrite) NSColor *foregroundColor;
@property (readwrite) NSColor *backgroundColor;
@property (readwrite) BOOL eolFilled;

// These are only used in the editor style
@property (readwrite) NSColor *caretForegroundColor;

@end
