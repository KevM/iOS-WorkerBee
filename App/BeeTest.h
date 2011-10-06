//
//  BeeTest.h
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol BeeTestDelegate;


@interface BeeTest : NSObject

#pragma mark Introspection - Used to display the list of tests

/** Returns an array of Class objects for each available BeeTest subclass. */
+ (NSArray*) allTestClasses;

/** The name to display for a test class. Defaults to the class's name. */
+ (NSString*) displayName;

#pragma mark Instance properties

/** The test's delegate; this will be the associated BeeTestController. */
@property (assign) id<BeeTestDelegate> delegate;

/** On/off switch for the test.
    Set to YES to start it, NO to stop it. Observable. */
@property BOOL running;

/** Current user-visible status message set by the test.
    Subclasses can set this. Observable. */
@property (copy) NSString* status;

/** A fatal error that stopped the test (observable). */
@property (copy) NSError* error;

/** The text of the error (equivalent to self.error.localizedDescription).
    Setting this is a useful way for a test to report an error if it doesn't have a full NSError object handy. */
@property (copy) NSString* errorMessage;

/** The time the test started running (observable). */
@property (readonly, retain) NSDate* startTime;

/** The time the test stopped running (observable). */
@property (readonly, retain) NSDate* endTime;

/** The latest log messages from the test, in chronological order (observable). */
@property (readonly) NSArray* messages;

/** Removes all items from messages. */
- (void) clearMessages;

#pragma mark For subclasses to override:

/** Called when the test starts running; put your own setup code here.
    Be sure to call the superclass method first. */
- (void) setUp;

/** Called when the test stops running; put your own cleanup code here.
    Be sure to call the superclass method last. */
- (void) tearDown;

/** Called when the user exits the app. Call the superclass method. */
- (void)applicationDidEnterBackground: (NSNotification*)notification;

/** Called when the user returns to the app. Call the superclass method. */
- (void)applicationWillEnterForeground: (NSNotification*)notification;

/** Called periodically if the heartbeatInterval is set to a positive value. */
- (void) heartbeat;

#pragma mark For subclasses to call:

/** Writes a string to the test's log, visible in the UI. */
- (void) logMessage: (NSString*)message;

/** Writes a formatted string to the test's log. */
- (void) logFormat: (NSString*)format, ... NS_FORMAT_FUNCTION(1,2);

/** Adds a timestamp to the log. */
- (BOOL) addTimestamp: (NSString*)message;

/** The interval at which the -heartbeat method will be called.
    Defaults to 0, meaning never. You typically call this in your -setup method. */
@property NSTimeInterval heartbeatInterval;

@end


@protocol BeeTestDelegate <NSObject>
- (void) beeTest: (BeeTest*)test isRunning: (BOOL)running;
- (void) beeTest: (BeeTest*)test loggedMessage: (NSString*)message;
@end