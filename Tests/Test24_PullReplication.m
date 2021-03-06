//
//  Test24_PullReplication.m
//  Worker Bee
//
//  Created by Li Yang on 7/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import <malloc/malloc.h>
#import "Test24_PullReplication.h"
#import <CouchbaseLite/CouchbaseLite.h>

//To run this test, start a fresh sync_gateway and change sync_gateway_ip in config.json

@implementation Test24_PullReplication
{
    bool pushReplicationRunning, pullReplicationRunning;
}

- (void) pushReplicationChanged: (NSNotificationCenter*)n {
    // Uncomment the following line to see the progress of push replication
    //[self logFormat: @"Push: completed %d Out of total %d",self.push.completedChangesCount,self.push.changesCount];
    if (self.push.status == kCBLReplicationStopped) {
        if (self.push.lastError)
        [self logSummary:[NSString stringWithFormat:
                          @"*** Replication Stopped and error found - %@", self.push.lastError]];
        pushReplicationRunning = NO;
    }
}

- (void) pullReplicationChanged: (NSNotificationCenter*)n {
    // Uncomment the following line to see the progress of pull replication
    //[self logFormat: @"Pull: completed %d Out of total %d",self.pull.completedChangesCount,self.pull.changesCount];
    if (self.pull.status == kCBLReplicationStopped) {
        if (self.pull.lastError)
            [self logFormat: @"Pull replication Stopped and error found - %@", self.pull.lastError];
        pullReplicationRunning = NO;
    }
}

- (double) runOne:(int)kNumberOfDocuments sizeOfDocuments:(int)kSizeofDocument {
    NSDictionary* environmentConfig = [[BeeTest config] objectForKey:@"environment"];
    NSString* syncGatewayIp = [environmentConfig  objectForKey:@"sync_gateway_ip"];
    NSString* syncGatewayPort = [environmentConfig  objectForKey:@"sync_gateway_port"];
    NSString* syncGatewayDb = [environmentConfig  objectForKey:@"sync_gateway_db"];
    NSString* syncGatewayUrl = [NSString  stringWithFormat:@"http://%@:%@/%@",
                                syncGatewayIp, syncGatewayPort, syncGatewayDb];
    [self logFormat: @"Starting Test %@ - Sync_gateway %@, kNumberOfDocuments %i, kSizeofDocument %i", [self class], syncGatewayUrl, kNumberOfDocuments, kSizeofDocument];
    
    @autoreleasepool {
        NSMutableData* utf8 = [NSMutableData dataWithLength: kSizeofDocument];
        memset(utf8.mutableBytes, '1', utf8.length);
        NSString* str = [[NSString alloc] initWithData: utf8 encoding: NSUTF8StringEncoding];
        NSDictionary* props = @{@"k": str};
        
        [self.database inTransaction:^BOOL{
            for (int j = 0; j < kNumberOfDocuments; j++) {
                @autoreleasepool {
                    CBLDocument* doc = [self.database createDocument];
                    NSError* error;
                    if (![doc putProperties: props error: &error]) {
                        [self logFormat: @"!!! Failed to create doc %@", props];
                        self.error = error;
                    }
                }
            }
            return YES;
        }];
    }
    NSURL *syncGateway  = [NSURL URLWithString:syncGatewayUrl];
    
    @autoreleasepool {
        self.push = [self.database createPushReplication: syncGateway];
        [self logFormat: @"Starting Push Replication"];
        
        [self.push start];
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(pushReplicationChanged:)
                     name: kCBLReplicationChangeNotification object: self.push];
        
        pushReplicationRunning = YES;
        while (pushReplicationRunning) {
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                     beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
        }
        [self logFormat: @"Push Replication Done"];
    }
    
    @autoreleasepool {
        [self deleteDatabase];
    }
    
    @autoreleasepool {
        self.pull = [self.database createPullReplication: syncGateway];
        [self logFormat: @"Starting Pull Replication"];
        
        // Start measuring time from here
        NSDate* start = [NSDate date];
        [self.pull start];
        NSNotificationCenter* nctr = [NSNotificationCenter defaultCenter];
        [nctr addObserver: self selector: @selector(pullReplicationChanged:)
                     name: kCBLReplicationChangeNotification object: self.pull];
        
        pullReplicationRunning = YES;
        while (pullReplicationRunning) {
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                     beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
        }
        NSDate *methodFinish = [NSDate date];
        [self logFormat: @"Pull Replication Done"];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start] * 1000;
        [self deleteDatabase];
        sleep(20);
        return executionTime;
    }

}



@end
