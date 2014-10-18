#import <Scintilla/InfoBar.h>
#import "AppDelegate.h"
#import "CodeDocument.h"
#import "CodeStyler.h"

#pragma mark Constants

#define NUM_BRACES 8

#pragma mark Debug flags

#define DEBUG_STYLE YES
#define DEBUG_CURRENT_WORD NO

@implementation CodeDocument

#pragma mark Scintilla methods
- (void)notification: (SCNotification*)notification {
	int type = notification->modificationType;
    int margin = notification->margin;
    
	switch (notification->nmhdr.code) {
		case SCN_SAVEPOINTREACHED:
			loaded = YES;
			[sv setStatusText:@"Ready"];
			break;
		case SCN_UPDATEUI: {
			// Highlight word matches
            long pos = [sv getGeneralProperty:SCI_GETCURRENTPOS];
			long wordStart = [sv getGeneralProperty:SCI_WORDSTARTPOSITION parameter:pos extra:YES];
			long wordEnd = [sv getGeneralProperty:SCI_WORDENDPOSITION parameter:pos extra:YES];
			Sci_TextRange tr;
			tr.chrg.cpMin = wordStart;
			tr.chrg.cpMax = wordEnd;
			tr.lpstrText = new char[wordEnd - wordStart];
			[sv message:SCI_GETTEXTRANGE wParam:nil lParam:(sptr_t)&tr];
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
				[sv setGeneralProperty:SCI_SETKEYWORDS parameter:1 value:(sptr_t)""];
			}
			if(DEBUG_CURRENT_WORD) {
				NSString *statusText = [NSString stringWithFormat:@"Current word: \"%@\"",[NSString stringWithCString:tr.lpstrText encoding:NSUTF8StringEncoding]];
				[sv setStatusText:statusText];
			}
			
			// Style debugging
			if(DEBUG_STYLE) {
				NSString *statusText = [NSString stringWithFormat:@"Style: %ld",[sv getGeneralProperty:SCI_GETSTYLEAT parameter:pos]];
				[sv setStatusText:statusText];
			}
			
			// Highlight matching braces
			[self handleBraces];
			break;
		}
		case SCN_MODIFIED:
			if ((type & SC_PERFORMED_USER) == SC_PERFORMED_USER)
			{
				if (((type & SC_MOD_INSERTTEXT) == SC_MOD_INSERTTEXT) ||
					((type & SC_MOD_DELETETEXT) == SC_MOD_DELETETEXT))
				{
					if (loaded)
					{
						[self updateChangeCount:NSChangeDone];
					}
				}
			}
			else if (((type & SC_MOD_INSERTTEXT) != SC_MOD_INSERTTEXT) &&
					 ((type & SC_MOD_DELETETEXT) != SC_MOD_DELETETEXT))
			{
				if ((type & SC_PERFORMED_UNDO) == SC_PERFORMED_UNDO)
				{
					[self updateChangeCount:NSChangeUndone];
				}
				else if ((type & SC_PERFORMED_REDO) == SC_PERFORMED_REDO)
				{
					[self updateChangeCount:NSChangeRedone];
				}
			}
			break;
		case SCN_CHARADDED:
            // Auto indent
			if(notification->ch == '\r' || notification->ch == '\n') {
                long pos = [sv getGeneralProperty:SCI_GETCURRENTPOS];
                long line = [sv getGeneralProperty:SCI_LINEFROMPOSITION parameter:pos];
                long lineLen = [sv getGeneralProperty:SCI_LINELENGTH parameter:line - 1];
                char lineBuf[lineLen];
                [sv message:SCI_GETLINE wParam:line - 1 lParam:(sptr_t)lineBuf];
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
				char prevChar = [sv message:SCI_GETCHARAT wParam:pos - 2];
				if(prevChar == '{') {
					[tabs insertString:@"\n" atIndex:0];
					[tabs appendString:@"}"];
					[sv insertText:@"\t"];
					[sv message:SCI_INSERTTEXT wParam:pos + [tabs length] - 1 lParam:(sptr_t)[tabs cString]];
				}
			}
			break;
        case SCN_MARGINCLICK:
            if(margin == 1) {
                long pos = notification->position;
                long line = [sv getGeneralProperty:SCI_LINEFROMPOSITION parameter:pos];
                [sv message:SCI_TOGGLEFOLD wParam:line];
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

- (void)handleBraces {
	long startAfter = [sv getGeneralProperty:SCI_GETCURRENTPOS];
	long startBefore = startAfter - 1;
	long endAfter = [sv message:SCI_BRACEMATCH wParam:startAfter lParam:0];
	long endBefore = [sv message:SCI_BRACEMATCH wParam:startBefore lParam:0];
	if(endAfter >= 0)
		[sv setGeneralProperty:SCI_BRACEHIGHLIGHT parameter:startAfter value:endAfter];
	else if (endBefore >= 0)
		[sv setGeneralProperty:SCI_BRACEHIGHLIGHT parameter:startBefore value:endBefore];
	else {
		[sv setGeneralProperty:SCI_BRACEHIGHLIGHT parameter:-1 value:-1];
		if([self isBrace:startAfter])
			[sv message:SCI_BRACEBADLIGHT wParam:startAfter];
		else if([self isBrace:startBefore])
			[sv message:SCI_BRACEBADLIGHT wParam:startBefore];
	}
}

-(void)setUpFolding {
	// Set items to fold
	[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold" lParam:(sptr_t)"1"];
	[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.compact" lParam:(sptr_t)"0"];
	
	long lex = [sv getGeneralProperty:SCI_GETLEXER];
	if(lex == SCLEX_HTML) {
		[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.html" lParam:(sptr_t)"1"];
		[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.hypertext.comment" lParam:(sptr_t)"1"];
	} else {
		[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.preprocessor" lParam:(sptr_t)"1"];
		[sv message:SCI_SETPROPERTY wParam:(uptr_t)"fold.comment" lParam:(sptr_t)"1"];
	}
	
	// Folding margins
	[sv setGeneralProperty:SCI_SETMARGINTYPEN parameter:1 value:SC_MARGIN_SYMBOL];
	[sv setGeneralProperty:SCI_SETMARGINMASKN parameter:1 value:SC_MASK_FOLDERS];
	[sv setGeneralProperty:SCI_SETMARGINSENSITIVEN parameter:1 value:YES];
	
	// Folding marker symbols
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDER value:SC_MARK_ARROW];
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPEN value:SC_MARK_ARROWDOWN];
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEREND value:SC_MARK_EMPTY];
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERMIDTAIL value:SC_MARK_TCORNERCURVE];
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPENMID value:SC_MARK_EMPTY];
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERSUB value:SC_MARK_VLINE];
	[sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERTAIL value:SC_MARK_LCORNERCURVE];
	
	// Folding marker colors
	[sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDER value:[NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1]];
	[sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDEROPEN value:[NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1]];
	[sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDERMIDTAIL value:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
	[sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDERSUB value:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
	[sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDERTAIL value:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
}

// Sets up the ScintillaView (and a few other things)
-(void)setUpView {
	// Some basic initialization stuff
	loaded = NO;
	savePromptOpen = NO;
	sv = [[ScintillaView alloc] initWithFrame:NSZeroRect];
	[sv setDelegate:self];
	
	// TODO: Get rid of hardcoded cpp stuff
	[sv message:SCI_SETLEXER wParam:SCLEX_CPP];
	[sv message:SCI_SETPROPERTY wParam:(uptr_t)"lexer.cpp.track.preprocessor" lParam:(sptr_t)"0"];
	
	[sv setAutoresizingMask:NSViewMaxYMargin|
	 NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|
	 NSViewHeightSizable|
	 NSViewMinYMargin];
	[self applyStyle];
	
	// Create a NSScrollView to which we add the NSTextView
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
	[scrollView setDocumentView:sv];
	
	// Set the NSScrollView as our view
	self.view = scrollView;
	
	// C++ Keywords
	[sv setStringProperty:SCI_SETKEYWORDS parameter:0 value:@"alignas alignof and and_eq asm auto bitand bitor bool break case catch char char16_t char32_t class compl const constexpr const_cast continue decltype default delete do double dynamic_cast else enum explicit export extern false float for friend goto if inline int long mutable namespace new noexcept not not_eq nullptr operator or or_eq private protected public register reinterpret_cast return short signed sizeof static static_assert static_cast struct switch template this thread_local throw true try typedef typeid typename union unsigned using virtual void volatile wchar_t while xor xor_eq"];
	
	// Line numbers in left margin
	[sv setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:30];
	[sv setGeneralProperty:SCI_SETMARGINTYPEN parameter:0 value:SC_MARGIN_NUMBER];
	
    // Indentation guides
    [sv setGeneralProperty:SCI_SETTABINDENTS value:YES];
    [sv setGeneralProperty:SCI_SETINDENTATIONGUIDES value:SC_IV_LOOKBOTH];
	
	[self setUpFolding];
	
	InfoBar *infoBar = [[InfoBar alloc] initWithFrame:NSZeroRect];
	[infoBar setDisplay:IBShowAll];
	[sv setInfoBar:infoBar top:NO];
}

-(void)applyStyle {
    NSString *style = [[NSUserDefaults standardUserDefaults] objectForKey:@"style"];
	// TODO: Get rid of hardcoded "cpp"
	CodeStyler *styler = [[CodeStyler alloc] initWithTheme:style language:@"cpp"];
	[styler stylizeScintillaView:sv];
}

#pragma mark Button actions
-(IBAction)increaseIndent:(id)sender {
    [sv message:SCI_TAB];
}

-(IBAction)decreaseIndent:(id)sender {
    [sv message:SCI_BACKTAB];
}

-(IBAction)toggleEOL:(id)sender {
    BOOL showEOL = [sv message:SCI_GETVIEWEOL];
    [sv message:SCI_SETVIEWEOL wParam:!showEOL];
    if(eolButton == nil) {
        eolButton = sender;
    }
}

#pragma mark Initializers
-(id)init {
	self = [super init];
	[self setUpView];
	return self;
}

-(id)initWithBaseTabContents:(CTTabContents*)baseContents {
	if (!(self = [super initWithBaseTabContents:baseContents])) return nil;
	[self setUpView];
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	[self setUpView];
	self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	return self;
}

#pragma mark File I/O
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSString *docName = [self title];
	[sv setStatusText:[NSString stringWithFormat:@"Loading document: %@",docName,nil]];
	void *bytes = malloc([data length]);
	[data getBytes:bytes];
	[sv message:SCI_APPENDTEXT wParam:[data length] lParam:(sptr_t)bytes];
	free(bytes);
	[sv message:SCI_EMPTYUNDOBUFFER];
	[sv message:SCI_SETSAVEPOINT];
	[sv setStatusText:[NSString stringWithFormat:@"Loaded document: %@",docName,nil]];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[NSThread sleepForTimeInterval:3];
		[sv setStatusText:@"Ready"];
	});
	return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSString *docName = [self title];
	[sv setStatusText:[NSString stringWithFormat:@"Saving document: %@",docName,nil]];
	long docLength = [sv getGeneralProperty:SCI_GETLENGTH] + 1;
	char text[docLength];
	[sv message:SCI_GETTEXT wParam:docLength lParam:(sptr_t)text];
	NSString *strText = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
	NSData *data = [strText dataUsingEncoding:NSUTF8StringEncoding];
	[sv setStatusText:[NSString stringWithFormat:@"Saved document: %@",docName,nil]];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[NSThread sleepForTimeInterval:3];
		[sv setStatusText:@"Ready"];
	});
	return data;
}

#pragma mark Tab management
-(void)tabDidBecomeActive {
	[self becomeFirstResponder];
	[self addWindowController:browser_.windowController];
    if(eolButton != nil) {
        BOOL showEOL = [sv message:SCI_GETVIEWEOL];
        [eolButton setState:showEOL];
    }
}

-(void)tabWillResignActive {
	[self removeWindowController:browser_.windowController];
    if(eolButton != nil) {
        [eolButton setState:NSOffState];
    }
}

#pragma mark Document closing
-(void)close {
	[[self delegate] removeDocument:self];
	if (savePromptOpen) {
		[[self browser] closeTab];
	}
}

- (void)document:(NSDocument *)doc shouldClose:(BOOL)shouldClose  contextInfo:(void  *)contextInfo {
	BOOL *close = (BOOL*)contextInfo;
	if(shouldClose) {
		*close = YES;
		[self close];
	} else {
		savePromptOpen = NO;
	}
}

-(BOOL)closingOfTabDidStart:(CTTabStripModel *)model {
	BOOL shouldClose = NO;
	SEL selector = @selector(document:shouldClose:contextInfo:);
	if(!savePromptOpen) {
		[self canCloseDocumentWithDelegate:self shouldCloseSelector:selector contextInfo:(void*)&shouldClose];
		savePromptOpen = YES;
	} else {
		shouldClose = YES;
	}
	return shouldClose;
}

#pragma mark Misc
-(void)setLanguageMenu:(NSString*)title {
	AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
	NSMenu *menu = [appDelegate languageMenu];
	NSMenuItem *menuItem = [menu itemWithTitle:title];
	for(int i = 0; i < [[menu itemArray] count]; ++i) {
		[[menu itemAtIndex:i] setState:NSOffState];
	}
	[menuItem setState:NSOnState];
}

-(IBAction)setLanguage:(id)sender {
	NSString *title = [sender title];
	[sv message:SCI_SETLEXER wParam:[sender tag]];
	[self setUpFolding];
	[sv message:SCI_COLOURISE wParam:0 lParam:-1];
	[self setLanguageMenu:title];
}

-(void)setLoaded:(BOOL)isLoaded {
	loaded = isLoaded;
	[sv setStatusText:@"Ready"];
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
	return YES;
}

-(void)setFileURL:(NSURL *)url {
	title_ = [url lastPathComponent];
	[browser_ updateTabStateForContent:self];
	[super setFileURL:url];
}

- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *errorOrNil))completionHandler {
	title_ = [url lastPathComponent];
	[browser_ updateTabStateForContent:self];
	[super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:completionHandler];
}

-(void)viewFrameDidChange:(NSRect)newFrame {
	// We need to recalculate the frame of the NSTextView when the frame changes.
	// This happens when a tab is created and when it's moved between windows.
	[super viewFrameDidChange:newFrame];
	NSRect frame = NSZeroRect;
	frame.size = [(NSScrollView*)(view_) contentSize];
	[sv setFrame:frame];
}

@end
