//
//  Test26_PushReplicateWithAttachment.h
//  Worker Bee
//
//  Created by Li Yang on 7/23/14.
//  Copyright (c) 2014 Couchbase, Inc. All rights reserved.
//

#import "BeeCouchMultipleTest.h"

@interface Test26_PushReplicateWithAttachment : BeeCouchMultipleTest

@property CBLReplication *push;

extern NSString * const syncGatewayURL;

@end