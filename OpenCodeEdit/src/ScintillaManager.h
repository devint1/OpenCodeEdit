//
//  ScintillaManager.h
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/18/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Scintilla/ScintillaView.h>
#import "CodeDocument.h"

@class CodeDocument;

@interface ScintillaManager : NSObject <ScintillaNotificationProtocol> {
    CodeDocument *document;
    ScintillaView *sv;
}

-(id)initWithCodeDocument:(CodeDocument*)codeDocument;
-(void)setLanguage:(NSInteger)tag;
-(void)setLanguageForUTI:(NSString*)uti;

@end
