//
//  FScriptLoader.m
//  FScriptLoader
//
//  Created by Wolfgang Baird on 2/4/18.
//Copyright © 2018 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#include <sys/time.h>

#define DISPATCH_AFTER(delayInSeconds, block) \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, \
        (int64_t)(delayInSeconds * NSEC_PER_SEC)), \
        dispatch_get_main_queue(), block)

@class FSInterpreterView;

@interface FScriptMenuItem : NSMenuItem
{
    IBOutlet FSInterpreterView *interpreterView;
    IBOutlet NSPanel *preferencePanel;
    IBOutlet NSTextField *fontSizeUI;
    IBOutlet NSButton *automaticallyIntrospectDeclaredPropertiesUI;
}

- (FSInterpreterView *)interpreterView;
- (IBAction)openObjectBrowser:(id)sender;
- (IBAction)showMenuConsole:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)updatePreference:(id)sender;

@end

@interface FScriptLoader : NSObject {
    id eventMonitor;
    FScriptMenuItem* menuItem;
}

+(void) load;
+(FScriptLoader*) sharedInstance;
@end

@implementation FScriptLoader

+ (instancetype)sharedInstance{
    static FScriptLoader *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

static FScriptLoader* plugin = nil;

+ (void)load {
    NSLog(@"fscriptloader : %@", NSBundle.mainBundle.bundleIdentifier);
    NSArray *blackList = [[NSArray alloc] initWithObjects:@"com.apple.dock", @"com.apple.loginwindow", nil];
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    if (![blackList containsObject:NSBundle.mainBundle.bundleIdentifier]) {
        // Load F-Script
        NSString *FScript = [NSString stringWithFormat:@"%@/Contents/Frameworks/FScript.framework", [[NSBundle bundleWithIdentifier:@"org.w0lf.FScriptLoader"] bundlePath]];
        if ([[NSBundle bundleWithPath:FScript] load]) {
            DISPATCH_AFTER(1, ^{
                // Add menuitem into main menu
                [NSClassFromString(@"FScriptMenuItem") performSelector:@selector(insertInMainMenu)];

                // Setup keywatch
                plugin = [FScriptLoader sharedInstance];

                // Log
                NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
            });
        } else {
            NSLog(@"%@ failed to load into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
        }
    } else {
        NSLog(@"%@ aborted loading into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
    }
}

-(id) init {
    self = [super init];
    if( !self ) {
        NSLog(@"%s [super init] failed!", __PRETTY_FUNCTION__);
        return nil;
    }
    menuItem = (FScriptMenuItem*) [[[NSApplication sharedApplication] mainMenu] itemWithTitle:@"F-Script"];//[NSClassFromString(@"FScriptMenuItem").alloc init];

    [NSEvent addGlobalMonitorForEventsMatchingMask:NSKeyDownMask
                                           handler:^(NSEvent *event){
                                               if ([event modifierFlags] == 1704234 && [event keyCode] == 8) {
                                                   /*CMD, ALT, SHIFT + C*/
                                                   [self->menuItem performSelector:@selector(showMenuConsole:) withObject:nil];
                                               } else if ([event modifierFlags] == 1704234 && [event keyCode] == 31) {
                                                   /*CMD, ALT, SHIFT + O*/
                                                   [self->menuItem performSelector:@selector(openObjectBrowser:) withObject:nil];
                                               }
                                           }];
    
    NSEvent * (^monitorHandler)(NSEvent *);
    monitorHandler = ^NSEvent * (NSEvent * event){
        if ([event modifierFlags] == 1704234 && [event keyCode] == 8) {
            /*CMD, ALT, SHIFT + C*/
            [self->menuItem performSelector:@selector(showMenuConsole:) withObject:nil];
            return nil;
        } else if ([event modifierFlags] == 1704234 && [event keyCode] == 31) {
            /*CMD, ALT, SHIFT + O*/
            [self->menuItem performSelector:@selector(openObjectBrowser:) withObject:nil];
            return nil;
        }
        // Return the event, a new event, or, to stop
        // the event from being dispatched, nil
        return event;
    };
    
    eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask
                                                         handler:monitorHandler];
    return self;
}

@end
