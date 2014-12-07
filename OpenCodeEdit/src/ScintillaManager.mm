//
//  ScintillaManager.m
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

#import "Languages.h"
#import "ScintillaManager.h"

#pragma mark Constants

#define NUM_BRACES 8

#pragma mark Debug flags

#define DEBUG_STYLE YES
#define DEBUG_CURRENT_WORD NO

@implementation ScintillaManager

static NSDictionary *utiToLangCode;
static NSDictionary *keywords;

+(void)initialize {
	NSBundle *mainBundle = [NSBundle mainBundle];
    if(!utiToLangCode) {
        NSString *filePath = [mainBundle pathForResource:@"languages" ofType:@"plist"];
        utiToLangCode = [NSDictionary dictionaryWithContentsOfFile:filePath];
    }
	if(!keywords) {
		NSString *filePath = [mainBundle pathForResource:@"keywords" ofType:@"plist"];
		keywords = [NSDictionary dictionaryWithContentsOfFile:filePath];
	}
}

-(id)initWithCodeDocument:(CodeDocument*)codeDocument {
    document = codeDocument;
    sv = [document sv];
    return self;
}

- (void)notification: (SCNotification*)notification {
    int margin = notification->margin;
    switch (notification->nmhdr.code) {
        case SCN_SAVEPOINTREACHED:
            [document setLoaded:YES];
            [sv setStatusText:@"Ready"];
            break;
		case SCN_UPDATEUI: {
			long selectionLength = [sv message:SCI_GETSELECTIONEND] - [sv message:SCI_GETSELECTIONSTART];
			if((notification->updated == SC_UPDATE_SELECTION || notification->updated == SC_UPDATE_CONTENT) && !selectionLength) {
				long pos = [sv message:SCI_GETCURRENTPOS];
				// Style debugging
				if(DEBUG_STYLE) {
					NSString *statusText = [NSString stringWithFormat:@"Style: %ld",[sv getGeneralProperty:SCI_GETSTYLEAT parameter:pos]];
					[sv setStatusText:statusText];
				}
				[self handleMatchingBraces];
                
                // This causes null pointer references... must be a better way
				// [self handleWordMatches];
			}
			break;
		}
		case SCN_MODIFIED:
            [self handleDocumentModifications:notification];
            break;
		case SCN_CHARADDED:
            if(notification->ch == '\r' || notification->ch == '\n') {
                [self handleAutoIndent];
            }
            break;
        case SCN_MARGINCLICK:
            if(margin == 1) {
                [self handleMarginClick:notification];
            }
            break;
        default:
            break;
    }
}

const char braces[] = {'(', ')', '[', ']', '{', '}'};

- (BOOL) isBrace:(long)pos {
    char c = [sv message:SCI_GETCHARAT wParam:pos];
    for (int i = 0; i < NUM_BRACES; ++i) {
        if (c != '\0' && braces[i] == c) {
            return true;
        }
    }
    return false;
}

# pragma mark Action handlers

- (void)handleMatchingBraces {
    long startAfter = [sv getGeneralProperty:SCI_GETCURRENTPOS];
    long startBefore = startAfter - 1;
    long endAfter = [sv message:SCI_BRACEMATCH wParam:startAfter lParam:0];
    long endBefore = [sv message:SCI_BRACEMATCH wParam:startBefore lParam:0];
	if(endAfter >= 0) {
		[sv setGeneralProperty:SCI_BRACEHIGHLIGHT parameter:startAfter value:endAfter];
		[sv message:SCI_FINDINDICATORFLASH wParam:endAfter lParam:endAfter + 1];
	}
	else if (endBefore >= 0) {
        [sv setGeneralProperty:SCI_BRACEHIGHLIGHT parameter:startBefore value:endBefore];
		[sv message:SCI_FINDINDICATORFLASH wParam:endBefore lParam:endBefore + 1];
	}
    else {
        [sv setGeneralProperty:SCI_BRACEHIGHLIGHT parameter:-1 value:-1];
        if([self isBrace:startAfter])
            [sv message:SCI_BRACEBADLIGHT wParam:startAfter];
        else if([self isBrace:startBefore])
            [sv message:SCI_BRACEBADLIGHT wParam:startBefore];
    }
}

- (void)handleWordMatches {
    long pos = [sv getGeneralProperty:SCI_GETCURRENTPOS];
    long wordStart = [sv getGeneralProperty:SCI_WORDSTARTPOSITION parameter:pos extra:YES];
    long wordEnd = [sv getGeneralProperty:SCI_WORDENDPOSITION parameter:pos extra:YES];
    Sci_TextRange tr;
    tr.chrg.cpMin = wordStart;
    tr.chrg.cpMax = wordEnd;
    tr.lpstrText = new char[wordEnd - wordStart];
    [sv message:SCI_GETTEXTRANGE wParam:(uptr_t)nil lParam:(sptr_t)&tr];
    Sci_TextToFind ttf;
    ttf.chrg.cpMin = 0;
    ttf.chrg.cpMax = wordStart - 1;
    ttf.lpstrText = tr.lpstrText;
    BOOL textFound = [sv message:SCI_FINDTEXT wParam:SCFIND_WHOLEWORD lParam:(sptr_t)&ttf] != -1;
    if (!textFound) {
        long doclen = [sv getGeneralProperty:SCI_GETLENGTH];
        ttf.chrg.cpMin = fmin(wordEnd,doclen - 1);
        ttf.chrg.cpMax = [sv getGeneralProperty:SCI_GETLENGTH] - 1;
        textFound = [sv message:SCI_FINDTEXT wParam:SCFIND_WHOLEWORD lParam:(sptr_t)&ttf] != -1;
    }
    if(textFound) {
        [sv setGeneralProperty:SCI_SETKEYWORDS parameter:1 value:(sptr_t)tr.lpstrText];
    }
    else {
        [sv setStringProperty:SCI_SETKEYWORDS parameter:1 value:@""];
    }
    // Current word debugging
    if(DEBUG_CURRENT_WORD) {
        NSString *statusText = [NSString stringWithFormat:@"Current word: \"%@\"",[NSString stringWithCString:tr.lpstrText encoding:NSUTF8StringEncoding]];
        [sv setStatusText:statusText];
    }
}

-(void)handleDocumentModifications:(SCNotification*)notification {
    int type = notification->modificationType;
    if ((type & SC_PERFORMED_USER) == SC_PERFORMED_USER)
    {
        if (((type & SC_MOD_INSERTTEXT) == SC_MOD_INSERTTEXT) ||
            ((type & SC_MOD_DELETETEXT) == SC_MOD_DELETETEXT))
        {
            if ([document loaded])
            {
                [document updateChangeCount:NSChangeDone];
            }
        }
    }
    else if (((type & SC_MOD_INSERTTEXT) != SC_MOD_INSERTTEXT) &&
             ((type & SC_MOD_DELETETEXT) != SC_MOD_DELETETEXT))
    {
        if ((type & SC_PERFORMED_UNDO) == SC_PERFORMED_UNDO)
        {
            [document updateChangeCount:NSChangeUndone];
        }
        else if ((type & SC_PERFORMED_REDO) == SC_PERFORMED_REDO)
        {
            [document updateChangeCount:NSChangeRedone];
        }
    }
}

-(void)handleAutoIndent {
    // Auto indent
    long pos = [sv getGeneralProperty:SCI_GETCURRENTPOS];
    long line = [sv getGeneralProperty:SCI_LINEFROMPOSITION parameter:pos];
    long lineLen = [sv getGeneralProperty:SCI_LINELENGTH parameter:line + 1];
    char lineBuf[lineLen];
    [sv message:SCI_GETLINE wParam:line + 1 lParam:(sptr_t)lineBuf];
    NSMutableString *tabs = [NSMutableString stringWithString:@""];
    int i;
    for(i = 0; i < lineLen; ++i) {
        if (lineBuf[i] == '\t') {
            [tabs appendString:@"\t"];
        }
        else {
            break;
        }
    }
    [sv insertText:tabs];
    // Add close brace to blocks and increase indent
	// TODO: Support other syntax besides C++
    char prevChar = [sv message:SCI_GETCHARAT wParam:pos - 2];
	BOOL braceBad = [sv message:SCI_BRACEMATCH wParam:pos - 2 lParam:0] == -1;
    if(prevChar == '{' && braceBad) {
        [tabs insertString:@"\n" atIndex:0];
        [tabs appendString:@"}"];
        [sv insertText:@"\t"];
		[sv message:SCI_INSERTTEXT wParam:pos + [tabs length] - 1 lParam:(sptr_t)[tabs cStringUsingEncoding:NSUTF8StringEncoding]];
		pos = [sv getGeneralProperty:SCI_GETCURRENTPOS];
		[sv message:SCI_FINDINDICATORFLASH wParam:pos + [tabs length] - 1 lParam:pos + [tabs length]];
    }
}

-(void)handleMarginClick:(SCNotification*)notification {
    long pos = notification->position;
    long line = [sv getGeneralProperty:SCI_LINEFROMPOSITION parameter:pos];
    [sv message:SCI_TOGGLEFOLD wParam:line];
}

#pragma mark Language setting
-(void)setLanguage:(NSInteger)tag {
    [sv message:SCI_CLEARDOCUMENTSTYLE];
    switch (tag) {
		case LANG_NONE:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_NULL];
            break;
		case LANG_CPP:
		case LANG_JAVA:
		case LANG_JAVASCRIPT:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_CPP];
            break;
		case LANG_CSS:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_CSS];
            break;
		case LANG_HTML:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_HTML];
            break;
		case LANG_MAKEFILE:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_MAKEFILE];
			break;
		case LANG_PYTHON:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_PYTHON];
			break;
		case LANG_XML:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_XML];
			break;
		case LANG_YAML:
			[sv setGeneralProperty:SCI_SETLEXER value:SCLEX_YAML];
			break;
        default:
            break;
    }
	[self setProperties:tag];
    [document setLanguage:tag];
    [document applyStyle];
	NSString *keywordString = [keywords objectForKey:[NSString stringWithFormat:@"%ld",tag]];
	if(keywordString)
		[sv setStringProperty:SCI_SETKEYWORDS parameter:0 value:keywordString];
	else
		[sv setStringProperty:SCI_SETKEYWORDS parameter:0 value:@""];
    [sv message:SCI_COLOURISE wParam:0 lParam:-1];
}

-(void)setLanguageForUTI:(NSString*)uti {
    NSInteger langCode = [[utiToLangCode objectForKey:uti] integerValue];
    if(!langCode)
        langCode = LANG_NONE;
    [self setLanguage:langCode];
}

-(void)setProperties:(NSInteger)language {
	[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold" lParam:(sptr_t)"1"];
	[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.compact" lParam:(sptr_t)"0"];
	[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.comment" lParam:(sptr_t)"1"];
	switch (language) {
		case LANG_CPP:
			[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.preprocessor" lParam:(sptr_t)"1"];
			[sv message:SCI_SETPROPERTY wParam:(uptr_t)"lexer.cpp.track.preprocessor" lParam:(sptr_t)"0"];
			break;
		case LANG_HTML:
		case LANG_XML:
			[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.html" lParam:(sptr_t)"1"];
			[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.hypertext.comment" lParam:(sptr_t)"1"];
			break;
		default:
			break;
	}
}

@end
