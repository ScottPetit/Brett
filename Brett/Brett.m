//
//  Brett.m
//  Brett
//
//  Created by Scott Petit on 5/24/14.
//  Copyright (c) 2014 Scott Petit. All rights reserved.
//

#import "Brett.h"
#import <zlib.h>

@interface Brett ()

+ (BOOL)shouldUnzipFileAtPath:(NSString *)filePath;

+ (BOOL)createFilesAndDirectoriesAtPath:(NSString *)path withTarFile:(id)tarFile size:(NSUInteger)size error:(NSError **)error destinationPath:(NSString **)destinationPath;
+ (char)fileTypeForObject:(id)object atOffset:(NSUInteger)offset;
+ (NSString *)nameForObject:(id)object atOffset:(NSUInteger)offset;
+ (NSUInteger)sizeForObject:(id)object atOffset:(NSUInteger)offset;
+ (void)writeFileDataForObject:(id)object atLocation:(NSUInteger)location withLength:(NSUInteger)length atPath:(NSString *)path;
+ (NSData *)dataForObject:(id)object inRange:(NSRange)range orLocation:(NSUInteger)location andLength:(NSUInteger)length;

@end

static NSUInteger const BrettTarBlockSize = 512;
static NSUInteger const BrettTarTypePosition = 156;
static NSUInteger const BrettTarNamePosition = 0;
static NSUInteger const BrettTarNameSize = 100;
static NSUInteger const BrettTarSizePosition = 124;
static NSUInteger const BrettTarSizeSize = 12;
static NSUInteger const BrettTarMaxBlockLoadInMemory = 100;

NSString * const BrettErrorDomain = @"com.brett.error";

@implementation Brett

+ (BOOL)untarFileAtURL:(NSURL *)fileURL withError:(NSError *__autoreleasing *)error destinationPath:(NSString *__autoreleasing *)destinationPath
{
    if (!fileURL)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:BrettErrorDomain code:BrettErrorInvalidFilePath userInfo:nil];
        }
        return NO;
    }
    
    return [self untarFileAtPath:[fileURL path] withError:error destinationPath:destinationPath];
}

+ (BOOL)untarFileAtPath:(NSString *)filePath withError:(NSError *__autoreleasing *)error destinationPath:(NSString *__autoreleasing *)destinationPath
{
    if (![filePath length])
    {
        if (error)
        {
            *error = [NSError errorWithDomain:BrettErrorDomain code:BrettErrorInvalidFilePath userInfo:nil];
        }
        return NO;
    }
    
    BOOL result = NO;
    
    if ([self shouldUnzipFileAtPath:filePath])
    {
        NSData *unzippedData = [self gunzippedDataForFileAtPath:filePath];
        NSString *path = [filePath stringByDeletingLastPathComponent];
        NSUInteger size = [unzippedData length];

        result = [self createFilesAndDirectoriesAtPath:path withTarFile:unzippedData size:size error:error destinationPath:destinationPath];
    }
    else
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath])
        {
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:error];
            NSUInteger fileSize = [fileAttributes[NSFileSize] unsignedIntegerValue];
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            NSString *path = [filePath stringByDeletingLastPathComponent];
            result = [self createFilesAndDirectoriesAtPath:path withTarFile:fileHandle size:fileSize error:error destinationPath:destinationPath];
            [fileHandle closeFile];
        }
        else
        {
            if (error)
            {
                *error = [NSError errorWithDomain:BrettErrorDomain code:BrettErrorFileNotFound userInfo:nil];
            }
        }
    }
    
    return result;
}

+ (BOOL)createFilesAndDirectoriesAtPath:(NSString *)path withTarFile:(id)tarFile size:(NSUInteger)size error:(NSError *__autoreleasing *)error destinationPath:(NSString *__autoreleasing *)destinationPath
{
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
    
    NSUInteger location = 0; // Position in the file
    NSString *rootDirectoryName = nil;
    
    while (location < size) {
        NSUInteger blockCount = 1;
        switch ([self fileTypeForObject:tarFile atOffset:location]) {
            case '0': // It's a File
            {
                NSString *name = [self nameForObject:tarFile atOffset:location];
                
                if ([rootDirectoryName length])
                {
                    if ([name rangeOfString:rootDirectoryName].length == 0)
                    {
                        name = [rootDirectoryName stringByAppendingPathComponent:name];
                    }
                }
                
                NSString *filePath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                
                if (destinationPath && ![*destinationPath length])
                {
                    *destinationPath = filePath;
                }
                
                NSUInteger size = [self sizeForObject:tarFile atOffset:location];
                
                if (size == 0)
                {
                    [@"" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:error];
                    break;
                }
                
                blockCount += (size - 1) / BrettTarBlockSize + 1; // size/TAR_BLOCK_SIZE rounded up
                
                [self writeFileDataForObject:tarFile atLocation:(location + BrettTarBlockSize) withLength:size atPath:filePath];
                break;
            }
                
            case '5': // It's a directory
            {
                NSString *name = [self nameForObject:tarFile atOffset:location];
                
                if (![rootDirectoryName length])
                {
                    rootDirectoryName = name;
                }
                
                NSString *directoryPath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                
                if (destinationPath && ![*destinationPath length])
                {
                    *destinationPath = directoryPath;
                }
                
                [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil]; //Write the directory on filesystem
                break;
            }
                
            case '\0': // It's a null block
            {
                break;
            }
                
            case '1':
            case '2':
            case '3':
            case '4':
            case '6':
            case '7':
            case 'x':
            case 'g': // It's neither a file neither or a directory
            {
                NSUInteger size = [self sizeForObject:tarFile atOffset:location];
                blockCount += ceil(size / BrettTarBlockSize);
                break;
            }
                
            default: // It's not a tar type
            {
                if (error)
                {
                    *error = [NSError errorWithDomain:BrettErrorDomain code:BrettErrorInvalidBlockType userInfo:nil];
                }
                
                return NO;
            }
        }
        
        location += blockCount * BrettTarBlockSize;
    }
    
    return YES;
}

#pragma mark - Private

+ (BOOL)shouldUnzipFileAtPath:(NSString *)filePath
{
    NSString *pathExtension = [filePath pathExtension];
    return [pathExtension rangeOfString:@"gz"].length != 0;
}

+ (NSData *)gunzippedDataForFileAtPath:(NSString *)filePath
{
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    
    NSMutableData *unzippedData = nil;
    if ([fileData length])
    {
        z_stream stream;
        stream.zalloc = Z_NULL;
        stream.zfree = Z_NULL;
        stream.avail_in = (uint)[fileData length];
        stream.next_in = (Bytef *)[fileData bytes];
        stream.total_out = 0;
        stream.avail_out = 0;
        
        unzippedData = [NSMutableData dataWithLength:(NSUInteger)([fileData length] * 1.5)];
        if (inflateInit2(&stream, 47) == Z_OK)
        {
            int status = Z_OK;
            while (status == Z_OK)
            {
                if (stream.total_out >= [unzippedData length])
                {
                    unzippedData.length += [fileData length] * 0.5;
                }
                stream.next_out = (uint8_t *)[unzippedData mutableBytes] + stream.total_out;
                stream.avail_out = (uInt)([unzippedData length] - stream.total_out);
                status = inflate (&stream, Z_SYNC_FLUSH);
            }
            if (inflateEnd(&stream) == Z_OK)
            {
                if (status == Z_STREAM_END)
                {
                    unzippedData.length = stream.total_out;
                    return unzippedData;
                }
            }
        }
    }
    
    return unzippedData;
}

+ (char)fileTypeForObject:(id)object atOffset:(NSUInteger)offset
{
    char type;
    
    memcpy(&type, [self dataForObject:object inRange:NSMakeRange(offset + BrettTarTypePosition, 1) orLocation:offset + BrettTarTypePosition andLength:1].bytes, 1);
    return type;
}

+ (NSString *)nameForObject:(id)object atOffset:(NSUInteger)offset
{
    char nameBytes[BrettTarNameSize + 1]; // TAR_NAME_SIZE+1 for nul char at end
    
    memset(&nameBytes, '\0', BrettTarNameSize + 1); // Fill byte array with nul char
    memcpy(&nameBytes, [self dataForObject:object inRange:NSMakeRange(offset + BrettTarNamePosition, BrettTarNameSize) orLocation:offset + BrettTarNamePosition andLength:BrettTarNameSize].bytes, BrettTarNameSize);
    return [NSString stringWithCString:nameBytes encoding:NSASCIIStringEncoding];
}

+ (NSUInteger)sizeForObject:(id)object atOffset:(NSUInteger)offset
{
    char sizeBytes[BrettTarSizeSize + 1]; // TAR_SIZE_SIZE+1 for nul char at end
    
    memset(&sizeBytes, '\0', BrettTarSizeSize + 1); // Fill byte array with nul char
    memcpy(&sizeBytes, [self dataForObject:object inRange:NSMakeRange(offset + BrettTarSizePosition, BrettTarSizeSize) orLocation:offset + BrettTarSizePosition andLength:BrettTarSizeSize].bytes, BrettTarSizeSize);
    return strtol(sizeBytes, NULL, 8); // Size is an octal number, convert to decimal
}

+ (void)writeFileDataForObject:(id)object atLocation:(NSUInteger)location withLength:(NSUInteger)length atPath:(NSString *)path
{
    if ([object isKindOfClass:[NSData class]])
    {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[object subdataWithRange:NSMakeRange(location, length)] attributes:nil]; //Write the file on filesystem
    }
    else if ([object isKindOfClass:[NSFileHandle class]])
    {
        if ([[NSData data] writeToFile:path atomically:NO])
        {
            NSFileHandle *destinationFile = [NSFileHandle fileHandleForWritingAtPath:path];
            [object seekToFileOffset:location];
            
            NSUInteger maxSize = BrettTarMaxBlockLoadInMemory * BrettTarBlockSize;
            
            while (length > maxSize) {
                @autoreleasepool {
                    [destinationFile writeData:[object readDataOfLength:maxSize]];
                    location += maxSize;
                    length -= maxSize;
                }
            }
            [destinationFile writeData:[object readDataOfLength:length]];
            [destinationFile closeFile];
        }
    }
}

+ (NSData *)dataForObject:(id)object inRange:(NSRange)range orLocation:(NSUInteger)location andLength:(NSUInteger)length
{
    NSData *data = nil;
    
    if ([object isKindOfClass:[NSData class]])
    {
        data = [object subdataWithRange:range];
    }
    else if ([object isKindOfClass:[NSFileHandle class]])
    {
        [object seekToFileOffset:location];
        data = [object readDataOfLength:length];
    }
    
    return data;
}

@end
