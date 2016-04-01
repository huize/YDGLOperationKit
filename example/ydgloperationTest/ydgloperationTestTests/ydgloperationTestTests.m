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
    
    CGRect viewFrame=CGRectMake(0, 0, 320.0, 480.0);
    
    CGSize viewSize=viewFrame.size;
    
    float width_view=viewSize.width;
    float height_view=viewSize.height;
    float aspect=fabsf(width_view/height_view);
    float nearZ=height_view/2;
    float farZ=nearZ+100;
    int viewport[4]={0,0,width_view,height_view};//按照坐标原点是左下角
    
    GLKMatrix4 projection=GLKMatrix4MakePerspective(M_PI_2, aspect, nearZ, farZ);
    
    GLKMatrix4 modelView=GLKMatrix4Identity;
    
    modelView=GLKMatrix4Translate(modelView, -width_view/2, height_view/2,-nearZ);
    
    modelView=GLKMatrix4Rotate(modelView, M_PI, 1.0, 0.0, 0.0);
    //以上2步,将modelView的原点从照相机的原点(0,0,0)移动到了近平面的左上角,与UIView的坐标系重叠
    
    ////要显示在窗口右上角的点
    //GLKVector3 position=GLKVector3Make(1.0, 1.0,-nearZ);
    
    GLKVector3 zeroPosition=GLKVector3Make(0.0,0.0,0.0);//modelView 变换了,所以原点左三角
    
    GLKVector3 leftTopPosition=zeroPosition;
    
    GLKVector3 rightTopPosition=GLKVector3Make(width_view,0.0, 0.0);
    
    GLKVector3 leftBottomPosition=GLKVector3Make(0.0, height_view, 0.0);
    
    GLKVector3 rightBottomPosition=GLKVector3Make(width_view,height_view, 0.0);
    
    GLKVector3 pzeroPosition=GLKMathProject(zeroPosition, modelView, projection, viewport);
    
    GLKVector3 pleftTopPosition=GLKMathProject(leftTopPosition, modelView, projection, viewport);
    
    GLKVector3 prightTopPosition=GLKMathProject(rightTopPosition, modelView, projection, viewport);
    
    GLKVector3 pleftBottomPosition=GLKMathProject(leftBottomPosition, modelView, projection, viewport);
    
    GLKVector3 prightBottomPosition=GLKMathProject(rightBottomPosition, modelView, projection, viewport);
    
    NSLog(@"zero:%f %f %f",pzeroPosition.x,pzeroPosition.y,pzeroPosition.z);
    NSLog(@"lefttop:%f %f %f",pleftTopPosition.x,pleftTopPosition.y,pleftTopPosition.z);
    NSLog(@"righttop:%f %f %f",prightTopPosition.x,prightTopPosition.y,prightTopPosition.z);
    NSLog(@"leftbottom:%f %f %f",pleftBottomPosition.x,pleftBottomPosition.y,pleftBottomPosition.z);
    NSLog(@"rightbottom:%f %f %f",prightBottomPosition.x,prightBottomPosition.y,prightBottomPosition.z);
    
}


- (void)testExample2 {
    
    CGSize sizeInPixel=CGSizeMake(2, 2);
    
    float aspect=fabsf(sizeInPixel.width/sizeInPixel.height);
    float nearZ=sizeInPixel.height/2;
    
    float farZ=nearZ+100;
    
    GLKMatrix4 projection=GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, nearZ, farZ);
    
    GLKMatrix4 modelView=GLKMatrix4Identity;
    
    GLKMatrix4 mvp= GLKMatrix4Multiply(projection,modelView);//modelView*projection
    
    GLKVector3 position=GLKVector3Make(-1.0,1.0,-nearZ);
    
    GLKVector3 pposition= GLKMatrix4MultiplyVector3(GLKMatrix4Invert(mvp, NULL), position);
    
    NSLog(@"pposition:%f %f %f",pposition.x,pposition.y,pposition.z);
    
}

-(void)testGLKMatrix4Multiply{

    //得出结论是GLKMatrix4Multiply(A,B)==B*A

    GLKMatrix4 left=GLKMatrix4Identity;
    
    left=GLKMatrix4Translate(left, 1, 2, 3);
    
    for (int index=0; index<4; index++) {
        
        NSLog(@"%f %f %f %f",left.m[index*4+0],left.m[index*4+1],left.m[index*4+2],left.m[index*4+3]);
        
    }
    
    NSLog(@"=======================");
    
    GLKMatrix4 right=GLKMatrix4Identity;
    
    right=GLKMatrix4Scale(right, 2.0, 3.0, 4.0);
    
    for (int index=0; index<4; index++) {
        
        NSLog(@"%f %f %f %f",right.m[index*4+0],right.m[index*4+1],right.m[index*4+2],right.m[index*4+3]);
        
    }

    
    NSLog(@"*****************************");
    GLKMatrix4 lr=GLKMatrix4Multiply(left, right);


    for (int index=0; index<4; index++) {
        
        NSLog(@"%f %f %f %f",lr.m[index*4+0],lr.m[index*4+1],lr.m[index*4+2],lr.m[index*4+3]);
        
    }

    
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
