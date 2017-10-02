//
//  QMDownloader.m
//  QromaScan
//
//  Created by truebucha on 8/2/16.
//  Copyright © 2016 Qroma. All rights reserved.
//

#import "CDBDownloader.h"
#import <AFNetworking/AFNetworking.h>


@implementation CDBDownloader

+ (void)downloadFileAtURL:(NSURL *)URL
                 progress:(void(^)(NSUInteger percents))progress
               completion:(void (^)(NSURL * downloadedFileURL, NSError * error))completion {
    
    NSString * fileName = URL.absoluteString.lastPathComponent;
    NSURL * temporaryFileURL = [[self temporaryDirectory] URLByAppendingPathComponent:fileName];
    NSOutputStream * fileStream = [NSOutputStream outputStreamWithURL:temporaryFileURL
                                                               append:NO];
    
    NSURLRequest * request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation * operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setOutputStream:fileStream];
    if (progress != nil) {
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            NSUInteger percents = (NSUInteger)((totalBytesRead * 100) / totalBytesExpectedToRead);
            progress(percents);
        }];
    }
    
    if (completion != nil) {
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * operation, id responseObject) {
            NSFileManager * manager = [NSFileManager defaultManager];
            NSError * error = nil;
            [[NSFileManager defaultManager] attributesOfItemAtPath:temporaryFileURL.path
                                                             error:&error];
            if (error != nil) {
               [manager removeItemAtURL:temporaryFileURL
                                  error:nil];
               completion(nil, error);
            }
            
            completion(temporaryFileURL, nil);
        } failure:^(AFHTTPRequestOperation * operation, NSError *error) {
            completion(nil, error);
        }];
    }
    
    [operation start];
}

+ (NSURL *)temporaryDirectory {
    NSURL * result = [NSURL fileURLWithPath:NSTemporaryDirectory()
                                isDirectory:YES];
    return result;
}

@end
