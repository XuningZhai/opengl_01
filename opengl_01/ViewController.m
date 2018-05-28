//
//  ViewController.m
//  opengl_01
//
//  Created by aipu on 2018/5/25.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>

@interface ViewController ()

@property (nonatomic,strong)EAGLContext *eaglContext;//上下文
@property (nonatomic,strong)GLKBaseEffect *effect;//着色器
@property (nonatomic,assign)int count;//顶点个数

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /****1、新建OpenGLES上下文****/
    //新建OpenGLES上下文
    self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];//2.0
    GLKView *glkView = (GLKView *)self.view;
    glkView.delegate = self;
    glkView.context = self.eaglContext;
    glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;//颜色缓冲区格式
    [EAGLContext setCurrentContext:self.eaglContext];
    
    /****2、顶点数组和索引数组****/
    //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
    GLfloat squareVertexData[] =
    {
//        0.5,-0.5,0.0f,  1.0f,0.0f,//右下 0
//        0.5,0.5,0.0f,   1.0f,1.0f,//右上 1
//        -0.5,0.5,0.0f,  0.0f,1.0f,//左上 2
//        -0.5,-0.5,0.0f, 0.0f,0.0f,//左下 3
        0.0,-0.5,0.0f,  1.0f,0.0f,//右下 0
        0.0,0.5,0.0f,   1.0f,1.0f,//右上 1
        -1.0,0.5,0.0f,  0.0f,1.0f,//左上 2
        -1.0,-0.5,0.0f, 0.0f,0.0f,//左下 3
        1.0,-0.5,0.0f,  0.0f,0.0f,//右下 4（纹理左下,左右翻转）
        1.0,0.5,0.0f,   0.0f,1.0f,//右上 5（纹理左上）
        -0.0,0.5,0.0f,  1.0f,1.0f,//左上 6（纹理右上）
        -0.0,-0.5,0.0f, 1.0f,0.0f,//左下 7（纹理右下）
    };
    //顶点索引
    GLuint indices[] =
    {
//        0,1,2,
//        0,2,3,
        0,1,2,
        0,2,3,
        4,5,6,
        4,6,7,
    };
    self.count = sizeof(indices)/sizeof(GLuint);
//    NSLog(@"%lu %lu %d",sizeof(indices),sizeof(GLuint),self.count);//24 4 6 //48 4 12
    /*
     顶点坐标：范围是[-1,1]，[0,0]原点在屏幕中间，[x,y,z]
     纹理坐标：范围是[0,1]，[0,0]原点在左下角，[1,1]在右上角
     索引数组是顶点数组的索引，把squareVertexData数组看成4个顶点，每个顶点会有5个GLfloat数据，索引从0开始。
     */
    
    /****3、顶点数据缓存****/
    //创建顶点缓存对象（VBO）
    /*
     1.使用glGenBuffers()生成新缓存对象。
     2.使用glBindBuffer()绑定缓存对象。
     3.使用glBufferData()将顶点数据拷贝到缓存对象中。
     */
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW);
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);//顶点数据缓存
    glVertexAttribPointer(GLKVertexAttribPosition,
                          3,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(GLfloat)*5,
                          (GLfloat *)NULL+0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);//纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(GLfloat)*5,
                          (GLfloat *)NULL+3);
    /*
     核心内容：
     glGenBuffers申请一个标识符
     glBindBuffer把标识符绑定到GL_ARRAY_BUFFER上
     glBufferData把顶点数据从cpu内存复制到gpu内存
     glEnableVertexAttribArray 是开启对应的顶点属性
     glVertexAttribPointer设置合适的格式从buffer里面读取数据
     */
    
    /****4、纹理贴图****/
    //纹理贴图
    /*
     我们把一张图片加载成为要渲染的纹理，由于纹理坐标系是跟手机显示的Quartz 2D坐标系的y轴正好相反，纹理坐标系使用左下角为原点，往上为y轴的正值，往右是x轴的正值，所以需要设置一下GLKTextureLoaderOriginBottomLeft。
     GLKit中使用GLKTextureInfo表示纹理对象。
     */
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"for_test" ofType:@"jpg"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    //GLKTextureLoader读取图片，创建纹理GLKTextureInfo
    
    //着色器
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = textureInfo.name;
    //创建着色器GLKBaseEffect，把纹理赋值给着色器
}

#pragma mark - GLKViewDelegate
/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
//    //背景颜色
//    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //启动着色器
    [self.effect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}


@end
