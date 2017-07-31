//
//  ViewController.m
//  PDF
//
//  Created by iMac on 17/7/25.
//  Copyright © 2017年 kangbing. All rights reserved.
//

#import "ViewController.h"
#import <QuickLook/QuickLook.h>
#import "AFNetworking.h"

@interface ViewController ()<QLPreviewControllerDataSource,QLPreviewControllerDelegate,UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIButton *btn;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, copy) NSString *pathString;

@property (nonatomic, strong) QLPreviewController *QLPVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    // 方法1
//    [self webViewLoad];
    
    // 方法2
    [self QLPreviewControllerLoad];
    

    // 方法3
//    [self UIDocumentInteractionControllerLoad];
    
    
    // 方法4 把view导出成PDF
//    [self viewConvertPdf];

}


#pragma mark 方法1
- (void)webViewLoad{

    // demo.pdf
    // worddemo.docx
    // exceldemo.xlsx
    // pptdemo.pptx
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.backgroundColor = [UIColor whiteColor];
    NSURL *filePath = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"pptdemo" ofType:@"pptx"]];
    NSURLRequest *request = [NSURLRequest requestWithURL: filePath];
    [webView loadRequest:request];
    [webView setScalesPageToFit:YES];
    [self.view addSubview:webView];

}


#pragma mark 方法2
- (void)QLPreviewControllerLoad{

    NSString *name = @"demo.pdf";
    // 检查本地是否存在
    if ([self isFileExist:name]) {
        
        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *pathString = [path stringByAppendingFormat:@"/%@",name];
        NSLog(@"path:%@", pathString);
        self.pathString = pathString;
    }else{
        
        //重新下载
        [self loadHttpPdfWithUrl:@"http://192.168.1.25/demo.pdf"];
        
    }
    
    // 方法2
    QLPreviewController *QLPVC = [[QLPreviewController alloc] init];
    self.QLPVC = QLPVC;
    QLPVC.delegate = self;
    QLPVC.dataSource = self;
    [self presentViewController:QLPVC animated:YES completion:nil];

}


#pragma mark 方法3
- (void)UIDocumentInteractionControllerLoad{

    NSString *path = [[NSBundle mainBundle] pathForResource:@"pptdemo" ofType:@"pptx"];
    UIDocumentInteractionController *docVC = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
    docVC.delegate = self;
    [docVC presentPreviewAnimated:YES];

}

#pragma mark 方法4
- (void)viewConvertPdf{

    UIButton *btn = [[UIButton alloc]init];
    self.btn = btn;
    [btn setTitle:@"按钮" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    btn.backgroundColor = [UIColor yellowColor];
    btn.frame = CGRectMake(100, 100, 200, 200);

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithTitle:@"save" style:UIBarButtonItemStylePlain target:self action:@selector(rightItemClick)];
    self.navigationItem.rightBarButtonItem = rightItem;

}


#pragma mark 方法3代理
#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    
    return self;
}

- (UIView*)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)controller {
    
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)controller {
    return CGRectMake(0, 30, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}


#pragma mark 方法2代理
#pragma mark QLPreviewControllerDataSource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return self.pathString == nil ? 0 : 1;
}
- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    // 加载本地
    NSString *path = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"pdf"];
    return [NSURL fileURLWithPath:path];
    
    // 加载网络下载的, 其实也在本地沙盒了
//    return [NSURL fileURLWithPath:self.pathString];;
}


#pragma mark 根据url下载的操作
- (void)loadHttpPdfWithUrl:(NSString *)url{
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    //下载Task操作
    _downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // totalUnitCount;     需要下载文件的总大小
        // completedUnitCount; 当前已经下载的大小
        NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);

        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //返回的这个URL就是文件的位置的路径
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [documentPath stringByAppendingPathComponent:response.suggestedFilename];
        NSLog(@"%@",path);
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //  下载完成
        NSString *localFilePath = [filePath path];// 将NSURL转成NSString
        self.pathString = localFilePath;
        NSLog(@"已经下载完成的路径%@",localFilePath);
        // 下载完成刷新, 加载
        [self.QLPVC reloadData];
        NSLog(@"%@",error);
        
    }];
    // 开始下载
    [_downloadTask resume];


}

- (BOOL)isFileExist:(NSString *)fileName{
    
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;

    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:filePath];
    
    NSLog(@"这个文件是否存在%d",result);
    return result;
}










#pragma mark 方法4
- (void)rightItemClick{
    
    [self createPDFfromUIView:self.btn saveToDocumentsWithFileName:@"btn.pdf"];
    
}

- (void)createPDFfromUIView:(UIView*)aView saveToDocumentsWithFileName:(NSString*)aFilename {
    
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, aView.bounds, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    [aView.layer renderInContext:pdfContext];
    UIGraphicsEndPDFContext();
    NSArray* documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString* documentDirectory = [documentDirectories objectAtIndex:0];
    NSString* documentDirectoryFilename = [documentDirectory stringByAppendingPathComponent:aFilename];
    [pdfData writeToFile:documentDirectoryFilename atomically:YES];
    NSLog(@"documentDirectoryFileName: %@",documentDirectoryFilename);
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
