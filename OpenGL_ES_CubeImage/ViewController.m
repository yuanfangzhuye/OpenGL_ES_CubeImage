//
//  ViewController.m
//  OpenGL_ES_CubeImage
//
//  Created by tlab on 2020/7/28.
//  Copyright © 2020 yuanfangzhuye. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3  positionCoord;  //顶点坐标
    GLKVector2  textureCoord;   //纹理坐标
    GLKVector3  normal;         //法线
} LVertex;

static NSInteger const kCoordCount = 36;    //总顶点数

@interface ViewController ()<GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) LVertex *vertexs;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger angle;
@property (nonatomic, assign) GLuint vertexBuffer;

@end

@implementation ViewController

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertexs) {
        free(_vertexs);
        _vertexs = nil;
    }
    
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    [self.displayLink invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.View背景色
    self.view.backgroundColor = [UIColor redColor];
    
    //2. OpenGL ES 相关初始化
    [self setupConfig];
    
    //3. 顶点数据
    [self setupVertexs];
    
    //4. 设置纹理数据
    [self setupTexture];
    
    //5. 添加CADisplayLink
    [self addDisplayLinkTimer];
}

- (void)setupConfig
{
    //1. 创建上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //2. 设置当前上下文
    [EAGLContext setCurrentContext:context];
    
    //3. 创建GLKView并设置代理
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc] initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    //4. 使用深度缓存
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //默认是(0, 1)，这里用于翻转 z 轴，使正方形朝屏幕外
    glDepthRangef(1, 0);
    
    //5. 将 GLKView 添加 self.view 上
    [self.view addSubview:self.glkView];
}

- (void)setupTexture
{
    //1. 获取纹理图片路径
    NSString *imageFilePath = [[NSBundle mainBundle] pathForResource:@"timg" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imageFilePath];
    
    //2. 设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft:@(1)};
    GLKTextureInfo *textInfo = [GLKTextureLoader textureWithCGImage:[image CGImage] options:options error:nil];
    
    //3. 使用 baseEffect
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textInfo.name;
    self.baseEffect.texture2d0.target = textInfo.target;
    
    //开启光照效果
    self.baseEffect.light0.enabled = YES;
    //漫反射颜色
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    //光源位置
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);
}

- (void)setupVertexs
{
    /**
     这里我们不复用顶点，使用每 3 个点画一个三角形的方式，需要 12 个三角形，则需要 36 个顶点,以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
     */
    
    //9. 开辟顶点数据空间(数据结构 SenceVertex 大小 * 顶点个数kCoordCount)
    self.vertexs = malloc(sizeof(LVertex) * kCoordCount);
    
    // 前面
    self.vertexs[0] = (LVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}};
    self.vertexs[1] = (LVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertexs[2] = (LVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertexs[3] = (LVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertexs[4] = (LVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertexs[5] = (LVertex){{0.5, -0.5, 0.5}, {1, 0}, {0, 0, 1}};
    
    // 上面
    self.vertexs[6] = (LVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 1, 0}};
    self.vertexs[7] = (LVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertexs[8] = (LVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertexs[9] = (LVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertexs[10] = (LVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertexs[11] = (LVertex){{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}};
    
    // 下面
    self.vertexs[12] = (LVertex){{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}};
    self.vertexs[13] = (LVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertexs[14] = (LVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertexs[15] = (LVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertexs[16] = (LVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertexs[17] = (LVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}};
    
    // 左面
    self.vertexs[18] = (LVertex){{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}};
    self.vertexs[19] = (LVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertexs[20] = (LVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertexs[21] = (LVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertexs[22] = (LVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertexs[23] = (LVertex){{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}};
    
    // 右面
    self.vertexs[24] = (LVertex){{0.5, 0.5, 0.5}, {1, 1}, {1, 0, 0}};
    self.vertexs[25] = (LVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertexs[26] = (LVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertexs[27] = (LVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertexs[28] = (LVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertexs[29] = (LVertex){{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}};
    
    // 后面
    self.vertexs[30] = (LVertex){{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}};
    self.vertexs[31] = (LVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertexs[32] = (LVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertexs[33] = (LVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertexs[34] = (LVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertexs[35] = (LVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}};
    
    //开辟顶点缓存区
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(LVertex) *kCoordCount;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertexs, GL_STATIC_DRAW);
    
    //顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(LVertex), NULL + offsetof(LVertex, positionCoord));
    
    //纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(LVertex), NULL + offsetof(LVertex, textureCoord));
    
    //法线数据
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(LVertex), NULL + offsetof(LVertex, normal));
}

- (void)addDisplayLinkTimer
{
    //CADisplayLink 类似定时器,提供一个周期性调用.属于QuartzCore.framework中
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTimer)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)updateTimer
{
    //1.计算旋转度数
    self.angle = (self.angle + 5) % 360;
    
    //2.修改baseEffect.transform.modelviewMatrix
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1.0, 0.7);
    
    //重新渲染
    [self.glkView display];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //1. 开启深度测试
    glEnable(GL_DEPTH_TEST);
    //2. 清除颜色缓存区&深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //3. 准备绘制
    [self.baseEffect prepareToDraw];
    
    //4. 绘图
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);
}


@end
