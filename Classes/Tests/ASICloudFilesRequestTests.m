//
//  ASICloudFilesRequestTests.m
//
//  Created by Michael Mayo on 1/6/10.
//

#import "ASICloudFilesRequestTests.h"

// models
#import "ASICloudFilesContainer.h"
#import "ASICloudFilesObject.h"

// requests
#import "ASICloudFilesRequest.h"
#import "ASICloudFilesContainerRequest.h"
#import "ASICloudFilesObjectRequest.h"
#import "ASICloudFilesCDNRequest.h"

// Fill in these to run the tests that actually connect and manipulate objects on Cloud Files
static NSString *username = @"";
static NSString *apiKey = @"";

@implementation ASICloudFilesRequestTests

@synthesize networkQueue;

// Authenticate before any test if there's no auth token present
- (void)authenticate {
	if (![ASICloudFilesRequest authToken]) {
		[ASICloudFilesRequest setUsername:username];
		[ASICloudFilesRequest setApiKey:apiKey];
		[ASICloudFilesRequest authenticate];		
	}
}

// ASICloudFilesRequest
- (void)testAuthentication {
	[self authenticate];
	GHAssertNotNil([ASICloudFilesRequest authToken], @"Failed to authenticate and obtain authentication token");
	GHAssertNotNil([ASICloudFilesRequest storageURL], @"Failed to authenticate and obtain storage URL");
	GHAssertNotNil([ASICloudFilesRequest cdnManagementURL], @"Failed to authenticate and obtain CDN URL");
}

- (void)testDateParser {
	ASICloudFilesRequest *request = [[ASICloudFilesRequest alloc] init];
	NSDate *date = [request dateFromString:@"2009-11-04T19:46:20.192723"];
	GHAssertNotNil(date, @"Failed to parse date string");	
	date = [request dateFromString:@"invalid date string"];
	GHAssertNil(date, @"Failed to not parse with invalid date string");	
	[request release];
}

// ASICloudFilesContainerRequest
- (void)testAccountInfo {
	[self authenticate];
	
	ASICloudFilesContainerRequest *request = [ASICloudFilesContainerRequest accountInfoRequest];
	[request start];
	
	GHAssertTrue([request containerCount] > 0, @"Failed to retrieve account info");
	GHAssertTrue([request bytesUsed] > 0, @"Failed to retrieve account info");
}

- (void)testContainerList {
	[self authenticate];
	
	NSArray *containers = nil;
	
	ASICloudFilesContainerRequest *containerListRequest = [ASICloudFilesContainerRequest listRequest];
	[containerListRequest start];
	
	containers = [containerListRequest containers];
	GHAssertTrue([containers count] > 0, @"Failed to list containers");
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesContainer *container = [containers objectAtIndex:i];
		GHAssertNotNil(container.name, @"Failed to parse container");
	}
	
	ASICloudFilesContainerRequest *limitContainerListRequest = [ASICloudFilesContainerRequest listRequestWithLimit:2 marker:nil];
	[limitContainerListRequest start];	
	containers = [limitContainerListRequest containers];
	GHAssertTrue([containers count] == 2, @"Failed to limit container list");
}

- (void)testContainerCreate {
	[self authenticate];
	
	ASICloudFilesContainerRequest *createContainerRequest = [ASICloudFilesContainerRequest createContainerRequest:@"ASICloudFilesContainerTest"];
	[createContainerRequest start];
	GHAssertTrue([createContainerRequest error] == nil, @"Failed to create container");
}

- (void)testContainerDelete {
	[self authenticate];

	ASICloudFilesContainerRequest *deleteContainerRequest = [ASICloudFilesContainerRequest deleteContainerRequest:@"ASICloudFilesContainerTest"];
	[deleteContainerRequest start];
	GHAssertTrue([deleteContainerRequest error] == nil, @"Failed to delete container");	
}

// ASICloudFilesObjectRequest
- (void)testContainerInfo {
	[self authenticate];

	// create a file first
	ASICloudFilesContainerRequest *createContainerRequest = [ASICloudFilesContainerRequest createContainerRequest:@"ASICloudFilesTest"];
	[createContainerRequest start];
	NSData *data = [@"this is a test" dataUsingEncoding:NSUTF8StringEncoding];
	ASICloudFilesObjectRequest *putRequest 
		= [ASICloudFilesObjectRequest putObjectRequestWithContainer:@"ASICloudFilesTest" 
													 objectPath:@"infotestfile.txt" contentType:@"text/plain" 
													 objectData:data metadata:nil etag:nil];
	
	[putRequest start];
	
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest containerInfoRequest:@"ASICloudFilesTest"];
	[request start];	
	GHAssertTrue([request containerObjectCount] > 0, @"Failed to retrieve container info");
	GHAssertTrue([request containerBytesUsed] > 0, @"Failed to retrieve container info");
}

- (void)testObjectInfo {
	[self authenticate];
	
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest objectInfoRequest:@"ASICloudFilesTest" objectPath:@"infotestfile.txt"];
	[request start];
	
	ASICloudFilesObject *object = [request object];
	GHAssertNotNil(object, @"Failed to retrieve object");
	GHAssertTrue([object.metadata count] > 0, @"Failed to parse metadata");
	
	GHAssertTrue([object.metadata objectForKey:@"Test"] != nil, @"Failed to parse metadata");
	
}

- (void)testObjectList {
	[self authenticate];
	
	ASICloudFilesObjectRequest *objectListRequest = [ASICloudFilesObjectRequest listRequestWithContainer:@"ASICloudFilesTest"];
	[objectListRequest start];
	
	NSArray *containers = [objectListRequest objects];
	GHAssertTrue([containers count] > 0, @"Failed to list objects");
	for (int i = 0; i < [containers count]; i++) {
		ASICloudFilesObject *object = [containers objectAtIndex:i];
		GHAssertNotNil(object.name, @"Failed to parse object");
	}
	
}

- (void)testGetObject {
	[self authenticate];
	
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest getObjectRequestWithContainer:@"ASICloudFilesTest" objectPath:@"infotestfile.txt"];
	[request start];
	
	ASICloudFilesObject *object = [request object];
	GHAssertNotNil(object, @"Failed to retrieve object");
	
	GHAssertNotNil(object.name, @"Failed to parse object name");
	GHAssertTrue(object.bytes > 0, @"Failed to parse object bytes");
	GHAssertNotNil(object.contentType, @"Failed to parse object content type");
	GHAssertNotNil(object.lastModified, @"Failed to parse object last modified");
	GHAssertNotNil(object.data, @"Failed to parse object data");
}

- (void)testPutObject {
	[self authenticate];
	
	ASICloudFilesContainerRequest *createContainerRequest 
			= [ASICloudFilesContainerRequest createContainerRequest:@"ASICloudFilesTest"];
	[createContainerRequest start];

	NSData *data = [@"this is a test" dataUsingEncoding:NSUTF8StringEncoding];
	
	ASICloudFilesObjectRequest *putRequest 
			= [ASICloudFilesObjectRequest putObjectRequestWithContainer:@"ASICloudFilesTest" 
											objectPath:@"puttestfile.txt" contentType:@"text/plain" 
											objectData:data metadata:nil etag:nil];
	
	[putRequest start];
	
	GHAssertNil([putRequest error], @"Failed to PUT object");

	ASICloudFilesObjectRequest *getRequest = [ASICloudFilesObjectRequest getObjectRequestWithContainer:@"ASICloudFilesTest" objectPath:@"puttestfile.txt"];
	[getRequest start];
	
	ASICloudFilesObject *object = [getRequest object];
	NSString *string = [[NSString alloc] initWithData:object.data encoding:NSASCIIStringEncoding];

	GHAssertNotNil(object, @"Failed to retrieve new object");
	GHAssertNotNil(object.name, @"Failed to parse object name");
	GHAssertEqualStrings(object.name, @"puttestfile.txt", @"Failed to parse object name", @"Failed to parse object name");
	GHAssertNotNil(object.data, @"Failed to parse object data");
	GHAssertEqualStrings(string, @"this is a test", @"Failed to parse object data", @"Failed to parse object data");
	
	[string release];
	
	ASICloudFilesContainerRequest *deleteContainerRequest = [ASICloudFilesContainerRequest deleteContainerRequest:@"ASICloudFilesTest"];
	[deleteContainerRequest start];
	
}

- (void)testPostObject {
	[self authenticate];
	
	NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithCapacity:2];
	[metadata setObject:@"test" forKey:@"Test"];
	[metadata setObject:@"test" forKey:@"ASITest"];
	
	ASICloudFilesObject *object = [ASICloudFilesObject object];
	object.name = @"infotestfile.txt";
	object.metadata = metadata;
	
	ASICloudFilesObjectRequest *request = [ASICloudFilesObjectRequest postObjectRequestWithContainer:@"ASICloudFilesTest" object:object];
	[request start];
	
	GHAssertTrue([request responseStatusCode] == 202, @"Failed to post object metadata");
	
	[metadata release];
	
}

- (void)testDeleteObject {
	[self authenticate];
	
	ASICloudFilesObjectRequest *deleteRequest = [ASICloudFilesObjectRequest deleteObjectRequestWithContainer:@"ASICloudFilesTest" objectPath:@"puttestfile.txt"];
	[deleteRequest start];
	GHAssertTrue([deleteRequest responseStatusCode] == 204, @"Failed to delete object");
}

#pragma mark -
#pragma mark CDN Tests

- (void)testCDNContainerInfo {
	[self authenticate];
	
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest containerInfoRequest:@"ASICloudFilesTest"];
	[request start];
	
	GHAssertTrue([request responseStatusCode] == 204, @"Failed to retrieve CDN container info");
	GHAssertTrue([request cdnEnabled], @"Failed to retrieve CDN container info");
	GHAssertNotNil([request cdnURI], @"Failed to retrieve CDN container info");
	GHAssertTrue([request cdnTTL] > 0, @"Failed to retrieve CDN container info");	
}

- (void)testCDNContainerList {
	[self authenticate];
	
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest listRequest];
	[request start];
	
	GHAssertNotNil([request containers], @"Failed to retrieve CDN container list");
}

- (void)testCDNContainerListWithParams {
	[self authenticate];
	
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest listRequestWithLimit:2 marker:nil enabledOnly:YES];
	[request start];
	
	GHAssertNotNil([request containers], @"Failed to retrieve CDN container list");
	GHAssertTrue([[request containers] count] == 2, @"Failed to retrieve limited CDN container list");
}

- (void)testCDNPut {
	[self authenticate];
	
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest putRequestWithContainer:@"ASICloudFilesTest"];
	[request start];
	
	GHAssertNotNil([request cdnURI], @"Failed to PUT to CDN container");
}

- (void)testCDNPost {
	[self authenticate];
	
	ASICloudFilesCDNRequest *request = [ASICloudFilesCDNRequest postRequestWithContainer:@"ASICloudFilesTest" cdnEnabled:YES ttl:86600];
	[request start];
	
	GHAssertNotNil([request cdnURI], @"Failed to POST to CDN container");
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc {
	[networkQueue release];
	[super dealloc];
}

@end
