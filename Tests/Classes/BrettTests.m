//
//  BrettTests.m
//  BrettTests
//
//  Created by Scott Petit on 5/24/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Brett.h"

@interface BrettTests : XCTestCase

- (NSURL *)URLForFileNotOnDisk;

@end

@implementation BrettTests

- (void)testUntarFileWithNilURLReturnsError
{
    NSError *error = nil;
    
    [Brett untarFileAtURL:nil withError:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, BrettErrorDomain);
    XCTAssertEqual(error.code, BrettErrorInvalidFilePath);
}

- (void)testUntarFileWithNilPathReturnsError
{
    NSError *error = nil;
    
    [Brett untarFileAtPath:nil withError:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, BrettErrorDomain);
    XCTAssertEqual(error.code, BrettErrorInvalidFilePath);
}

- (void)testUntarFileWhenFileDoesntExistReturnsNo
{
    NSURL *fileURL = [self URLForFileNotOnDisk];
    
    XCTAssertFalse([Brett untarFileAtURL:fileURL withError:nil]);
}

- (void)testUntarFileWhenFileDoesntExistPopulatesAnError
{
    NSURL *fileURL = [self URLForFileNotOnDisk];
    
    NSError *error = nil;
    
    [Brett untarFileAtURL:fileURL withError:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, BrettErrorDomain);
    XCTAssertEqual(error.code, BrettErrorFileNotFound);
}

#pragma mark - Helpers

- (NSURL *)URLForFileNotOnDisk
{
    NSString *filePath = @"file://thisdoesntexistyouliar";
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    return fileURL;
}

@end
