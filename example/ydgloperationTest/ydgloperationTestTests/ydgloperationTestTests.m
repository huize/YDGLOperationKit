//
//  ydgloperationTestTests.m
//  ydgloperationTestTests
//
//  Created by 辉泽许 on 16/3/16.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <XCTest/XCTest.h>

@import  GLKit;

@interface ydgloperationTestTests : XCTestCase

@end

@implementation ydgloperationTestTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    
    GLKMatrix4 project=GLKMatrix4MakePerspective(45.0, 1.0, 100, 200);
    
    GLKMatrix4 modelView=GLKMatrix4Identity;
    
    GLKMatrix4 mvp=GLKMatrix4Multiply(modelView, project);
    
    GLKVector4 position=GLKVector4Make(0, 100, 10, 1.0);

    GLKVector4 result=GLKMatrix4MultiplyVector4(mvp, position);

    NSLog(@"归一化前result:%f %f %f %f",result.x,result.y,result.z,result.w);

    result=GLKVector4Normalize(result);
    NSLog(@"归一化后result:%f %f %f %f",result.x,result.y,result.z,result.w);
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
