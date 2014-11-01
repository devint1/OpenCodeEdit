#import "AppDelegate.h"
#import "CodeDocument.h"
#import "UserDefaultsKeys.h"

#define DEBUG_UTI YES

@implementation AppDelegate

static CTBrowser *browser;

static NSDictionary *defaultValues() {
	static NSDictionary *defaults = nil;
	if(!defaults) {
		defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
					@"Default", UD_THEME,
					@{}, UD_STYLE_OVERRIDES,
					nil
					];
	}
	return defaults;
}

+(void)initialize {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:defaultValues()];
}

- (void)newBrowserWindow {
	if(!browser) {
		browser = [CTBrowser browser];
	}
	if (!browser.windowController) {
		browser.windowController = [[CTBrowserWindowController alloc] initWithBrowser:browser];
	}
	if(![[browser.windowController window] isVisible]) {
		[browser.windowController showWindow:self];
	}
}

- (id)makeDocumentWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	CodeDocument *document = [[CodeDocument alloc] initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	return document;
}

-(id)makeDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError	{
	CodeDocument *document = [[CodeDocument alloc] initWithContentsOfURL:contentsURL ofType:typeName error:outError];
	return document;
}

- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	CFStringRef pathExtension = (__bridge CFStringRef)[[urlOrNil lastPathComponent] pathExtension];
	NSString *fileUTI = (__bridge NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil);
	if(DEBUG_UTI)
		NSLog(@"UTI: %@",fileUTI);
	__block __strong CodeDocument *document = [self documentForURL:urlOrNil];
	BOOL documentAlreadyOpen = document != nil;
	if ([CodeDocument canConcurrentlyReadDocumentsOfType:fileUTI]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			document = [self makeDocumentForURL:urlOrNil withContentsOfURL:contentsURL ofType:fileUTI error:nil];
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self finishOpenDocument:document documentAlreadyOpen:documentAlreadyOpen display:displayDocument url:urlOrNil completionHandler:completionHandler];
			});
		});
	} else {
		document = [self makeDocumentForURL:urlOrNil withContentsOfURL:contentsURL ofType:fileUTI error:nil];
		[self finishOpenDocument:document documentAlreadyOpen:documentAlreadyOpen display:displayDocument url:urlOrNil completionHandler:completionHandler];
	}
}

-(void)finishOpenDocument:(CodeDocument*)document documentAlreadyOpen:(BOOL)documentOpen display:(BOOL)displayDocument url:(NSURL *)url completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	if(documentOpen) {
		int tabIndex = [browser indexOfTabContents:document];
		[browser selectTabAtIndex:tabIndex];
	} else {
		[self newBrowserWindow];
		[document setDelegate:self];
		[self addDocument:document];
		[document addWindowController:browser.windowController];
		[browser addTabContents:document];
		completionHandler(document, documentOpen, nil);
	}
}

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	CFStringRef pathExtension = (__bridge CFStringRef)[[url lastPathComponent] pathExtension];
	NSString *fileUTI = (__bridge NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil);
	if(DEBUG_UTI)
		NSLog(@"UTI: %@",fileUTI);
	BOOL documentAlreadyOpen = YES;
	__block __strong CodeDocument *document;
	if([self documentForURL:url] == nil) {
		documentAlreadyOpen = NO;
		if ([CodeDocument canConcurrentlyReadDocumentsOfType:fileUTI]) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
				document = [self makeDocumentWithContentsOfURL:url ofType:fileUTI error:nil];
				dispatch_sync(dispatch_get_main_queue(), ^{
					[self finishOpenDocument:document documentAlreadyOpen:documentAlreadyOpen display:displayDocument url:url completionHandler:completionHandler];
				});
			});
		} else {
			document = [self makeDocumentWithContentsOfURL:url ofType:fileUTI error:nil];
			[self finishOpenDocument:document documentAlreadyOpen:documentAlreadyOpen display:displayDocument url:url completionHandler:completionHandler];
		}
	} else {
		[self reopenDocumentForURL:url withContentsOfURL:url display:displayDocument completionHandler:completionHandler];
	}
}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
	[self newBrowserWindow];
	CodeDocument *newTab = [[CodeDocument alloc] init];
	[newTab setLoaded:YES];
	[newTab setDelegate:self];
	[self addDocument:newTab];
	[newTab addWindowController:browser.windowController];
	[browser addTabContents:newTab];
	return newTab;
}

-(IBAction)showPreferences:(id)sender {
	preferencesWindowController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
	[preferencesWindowController showWindow:self];
}

@end
