//
//  GooglyPuffTests.m
//  GooglyPuffTests
//
//  Created by A Magical Unicorn on A Sunday Night.
//  Copyright (c) 2014 Derek Selander. All rights reserved.
//

#import <XCTest/XCTest.h>

const int64_t kDefaultTimeoutLengthInNanoSeconds = 10000000000; // 10 Seconds

@interface GooglyPuffNetworkIntegrationTests : XCTestCase
@end


@implementation GooglyPuffNetworkIntegrationTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testMikeAshImageURL
{
    [self downloadImageURLWithString:kLotsOfFacesURLString];
}

- (void)testMattThompsonImageURL
{
    [self downloadImageURLWithString:kSuccessKidURLString];
}

- (void)testAaronHillegassImageURL
{
    [self downloadImageURLWithString:kOverlyAttachedGirlfriendURLString];
}

- (void)downloadImageURLWithString:(NSString *)URLString
{
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *url = [NSURL URLWithString:URLString];
    __unused Photo *photo = [[Photo alloc]
                             initwithURL:url
                             withCompletionBlock:^(UIImage *image, NSError *error) {
                                 if (error) {
                                     XCTFail(@"%@ failed. %@", URLString, error);
                                 }
                                 //increment semaphore by 1
                                 dispatch_semaphore_signal(semaphore);
                             }];
    
    // this waits on the semaphore with a given timeout
    // blocks the curent thread until the semaphore has been signalled
    // A non-zero return code means the timeout has been reached
    // In this case, test is failed because it is deemed that the network
    // should not take more than 10 seconds to return
    dispatch_time_t timeoutTime = dispatch_time(DISPATCH_TIME_NOW, kDefaultTimeoutLengthInNanoSeconds);
    if (dispatch_semaphore_wait(semaphore, timeoutTime)) {
        XCTFail(@"%@ timed out", URLString);
        }

    
    
    
//    NSURL *url = [NSURL URLWithString:URLString];
//    __block BOOL isFinishedDownloading = NO;
//    __unused Photo *photo = [[Photo alloc]
//                             initwithURL:url
//                             withCompletionBlock:^(UIImage *image, NSError *error) {
//                                 if (error) {
//                                     XCTFail(@"%@ failed. %@", URLString, error);
//                                 }
//                                 isFinishedDownloading = YES;
//                             }];
//    
//  //spinlock: wasting valuable CPU cycles waiting in the while loop
//    // Debug navigaor shows 100% + for CPU vs ~50% for above code
//    while (!isFinishedDownloading) {}
}


@end
