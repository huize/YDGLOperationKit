//
//  ViewController.m
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "ViewController.h"
#import "CustomGLView.h"
#import <MobileCoreServices/MobileCoreServices.h>


@import ImageIO;
struct RGBA{

    uint8_t R;
    uint8_t G;
    uint8_t B;
    uint8_t A;

};

@interface ViewController (){

    UIImage *_image;
    
    CustomGLView *_customView;

}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    _customView=[[CustomGLView alloc]initWithFrame:CGRectMake(0, 0, 300, 300)];
    
    _customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    [self.view addSubview:_customView];
    
    //[self readImage];
    
    //[self createImage];
    
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    [_customView startRender];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)createImage{

    int size_w=20;
    
    GLubyte *const tm=calloc(1,size_w*size_w*sizeof(GLubyte)*4);
    //GLubyte *const tm=malloc(size_w*size_w*sizeof(GLubyte)*4);
    //memset(tm, 0b00000000, sizeof(size_w*size_w*sizeof(GLubyte)*4));

    NSLog(@"地址:%p",tm);
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore= dispatch_semaphore_create(1);
    
    struct RGBA* tmp=(struct RGBA*)tm;
    
    dispatch_barrier_sync(queue, ^{
        
        dispatch_semaphore_wait(semaphore, 0.1);
        
        for (int i=0; i<size_w*size_w; i++) {
            
            struct RGBA pixel=tmp[i];
            
            NSLog(@"r:%i,g:%i,b:%i,a:%i\n",pixel.R,pixel.G,pixel.B,pixel.A);
            
        }
        
        dispatch_semaphore_signal(semaphore);
    });

    return ;
    
    //0x7fd1cd80a400 0x7fbf93812800
    //通常所说的RGB格式,其实就是R放在高位,如果以小端的方式存储的话,直接访问数据,数据布局是BGR(低位在起始位置),拿出来的数据依次是BGR
    //所以kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big 就保证了数据内存布局格式是RGBA,直接拿出来的话数据依次是RGBA
    
    CGContextRef context= CGBitmapContextCreate(tm, size_w, size_w, 8, size_w*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGContextSaveGState(context);
    
    //const CGFloat cc[]={255.0,0.0,0.0,1.0};
    
    //CGContextSetFillColor(context, &cc[0]);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1.0 green:0 blue:0.0 alpha:0.8].CGColor);
    
    //CGContextClearRect(context, CGRectMake(0, 0, size_w, size_w));
    
    CGContextFillRect(context, CGRectMake(0, 0, size_w, size_w));

    CGContextRestoreGState(context);
    
    CGImageRef cimage= CGBitmapContextCreateImage(context);
    
    UIImage *uimage=[UIImage imageWithCGImage:cimage];
    
    UIImageView *imageview=[[UIImageView alloc]initWithImage:uimage];
    
    imageview.center=[self.view convertPoint:self.view.center fromView:self.view];
    
    NSData *d=  UIImagePNGRepresentation(uimage);
    
    NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:@"tests.png"];
    
    unlink([path UTF8String]);
    
    [d writeToFile:path atomically:YES];
    
    GLubyte *data=CGBitmapContextGetData(context);
    
//    dispatch_async(queue, ^{
//        
//        dispatch_semaphore_wait(semaphore, 0.1);
//        
//        for (int i=0; i<size_w*size_w; i++) {
//            
//            struct RGBA pixel=tmp[i];
//        
//            NSLog(@"r:%i,g:%i,b:%i,a:%i\n",pixel.R,pixel.G,pixel.B,pixel.A);
//            
//        }
//        
//        dispatch_semaphore_signal(semaphore);
//   });
    
    _image=uimage;
    
    [self.view addSubview:imageview];
    
    dispatch_async(queue, ^{
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        free(tm);
        
        CGContextRelease(context);
        
        dispatch_semaphore_signal(semaphore);
        
    });
    
}

-(void)readImage{

    UIImage *image=[UIImage imageNamed:@"ic_bouns"];
    
    CGImageRef cg=image.CGImage;
    
    CGImageAlphaInfo alphainfo= CGImageGetAlphaInfo(cg);
    
    switch (alphainfo&kCGBitmapAlphaInfoMask) {
            
        case kCGImageAlphaLast:
            break;
        
        default:
            break;
    }

    CGDataProviderRef cd= CGImageGetDataProvider(cg);
    
    CFDataRef cfd= CGDataProviderCopyData(cd);

    const uint8_t *p= CFDataGetBytePtr(cfd);
    
    struct RGBA* tmp=(struct RGBA*)p;
    
    for (int i=0; i<100; i++) {
        
        struct RGBA pixel=tmp[i];
        
        NSLog(@"r:%i,g:%i,b:%i,a:%i\n",pixel.R,pixel.G,pixel.B,pixel.A);
        
    }
    
}


@end
