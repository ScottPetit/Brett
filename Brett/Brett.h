//
//  Brett.h
//  Brett
//
//  Created by Scott Petit on 5/24/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const BrettErrorDomain;

typedef NS_ENUM(NSInteger, BrettError){
    BrettErrorFileNotFound = 808,
    BrettErrorInvalidBlockType,
    BrettErrorInvalidFilePath
};

@interface Brett : NSObject

/**
 *  Untar a .tar, .tar.gz, or .tgz and return the resulting file or directory path via the destination path parameter.
 *
 *  @param fileURL         The file URL of the tar to be untarred
 *  @param error           The error that occurred while attempting to untar the tar file.
 *  @param destinationPath The destination path where the untarred file or directory is stored.
 *
 *  @return A BOOL indicating if untar was a success.
 */
+ (BOOL)untarFileAtURL:(NSURL *)fileURL withError:(NSError **)error destinationPath:(NSString **)destinationPath;

/**
 *  Untar a .tar, .tar.gz, or .tgz and return the resulting file or directory path via the destination path parameter.
 *
 *  @param filePath         The file path of the tar to be untarred
 *  @param error           The error that occurred while attempting to untar the tar file.
 *  @param destinationPath The destination path where the untarred file or directory is stored.
 *
 *  @return A BOOL indicating if untar was a success.
 */
+ (BOOL)untarFileAtPath:(NSString *)filePath withError:(NSError **)error destinationPath:(NSString **)destinationPath;

/**
 *  Unzips a Gzip file
 *
 *  @param filePath The file path to the gzip file
 *
 *  @return The unzipped data for the given gzip.
 */
+ (NSData *)gunzippedDataForFileAtPath:(NSString *)filePath;

@end
