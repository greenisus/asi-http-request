//
//  ASICloudFilesContainerRequest.h
//  iPhone
//
//  Created by Michael Mayo on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASICloudFilesRequest.h"

@class ASICloudFilesContainer;

@interface ASICloudFilesContainerRequest : ASICloudFilesRequest {
	NSMutableArray *containerObjects;
	//NSUInteger containerCount;
	//NSUInteger bytesUsed;
	
//	NSUInteger limit;
//	NSString *marker; // last item found as the offset
//	NSString *format; // json or xml
	
	// Internally used while parsing the response
	NSString *currentContent;
	NSString *currentElement;
	ASICloudFilesContainer *currentObject;
	
}

@property (nonatomic, retain) NSString *currentElement;
@property (nonatomic, retain) NSString *currentContent;
@property (nonatomic, retain) ASICloudFilesContainer *currentObject;


#pragma mark Constructors

// HEAD /<api version>/<account>
// HEAD operations against an account are performed to retrieve the number of Containers and the total bytes stored in Cloud Files for the account. This information is returned in two custom headers, X-Account-Container-Count and X-Account-Bytes-Used.
+ (id)accountInfoRequest;

// GET /<api version>/<account>/<container>
// Create a request to list all containers
+ (id)listRequest;
+ (id)listRequestWithLimit:(NSUInteger)limit;
+ (id)listRequestWithMarker:(NSString *)marker;
+ (id)listRequestWithLimit:(NSUInteger)limit marker:(NSString *)marker;

// PUT /<api version>/<account>/<container>
+ (id)createContainerRequest:(NSString *)containerName;

// DELETE /<api version>/<account>/<container>
+ (id)deleteContainerRequest:(NSString *)containerName;


- (NSUInteger)containerCount;
- (NSUInteger)bytesUsed;
- (NSArray *)containers;

// ASICloudFilesContainerListRequest
// GET on account (for containers)
// limit
// marker (last item found as the offset)
// format - 'json' or 'xml'

// create container
// DELETE to delete


@end