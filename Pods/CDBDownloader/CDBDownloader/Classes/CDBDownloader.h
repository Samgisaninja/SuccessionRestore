//
//  QMDownloader.h
//  QromaScan
//
//  Created by truebucha on 8/2/16.
//  Copyright © 2016 Qroma. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CDBDownloader : NSObject

+ (void)downloadFileAtURL:(NSURL * _Nonnull)URL
                 progress:(void(^ _Nullable)(NSUInteger percents) )progress
               completion:(void (^ _Nullable)(NSURL * _Nullable downloadedFileURL, NSError * _Nullable error))completion;


@end
