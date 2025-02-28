//
//  ViewController.m
//  GCDSemaphore
//
//  Created by feiheios on 2025/2/25.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = UIColor.lightGrayColor;
    
    UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    testBtn.frame = CGRectMake(120, 120, 100, 100);
    [testBtn setTitle:@"测试" forState:UIControlStateNormal];
    [testBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    testBtn.backgroundColor = UIColor.whiteColor;
    testBtn.layer.cornerRadius = 5;
    testBtn.clipsToBounds = YES;
    [testBtn addTarget:self action:@selector(testBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testBtn];
    
//    __block int num = 1001;
//    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        num += 10;
//        [testBtn setTitle:[NSString stringWithFormat:@"%d", num] forState:UIControlStateNormal];
//        NSLog(@"------ %@", [NSString stringWithFormat:@"%d", num]);
//    }];
}

#pragma mark - 按钮点击事件
- (void)testBtnClick {
    
    // 基础测试
//    [self test1];
//    [self test2];
//    [self test3];
    
    // 实际应用
//    [self action1];
//    [self action2];
    [self action3];
}

#pragma mark - 串行队列 + 异步 == 只会开启一个子线程，且队列中所有的任务都是在这个子线程中执行
- (void)test1 {
    // 串行队列
    dispatch_queue_t queue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务1：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程1");
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务2：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程2");
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务3：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程3");
    // 输出结果：主线程1、主线程2、主线程3，同一个子线程，顺序输出：任务1、任务2、任务3
}

#pragma mark - 并行队列 + 异步，会开启不同的子线程，且子线程无序执行
// 一定要添加“模拟复杂操作”，否则简单的一个输出语句，无法验证“先主，后异步block无序输出”此结果的正确性，
// 猜测：简单的一个输出语句，处理时间太快，时间四舍五入后，输出的结果与理论上的“先主，后异步block无序输出”
// 的结果不一致
- (void)test2 {
    // 并行队列
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务1：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程1");
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务2：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程2");
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务3：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程3");
    // 输出结果：主线程1、主线程2、主线程3，不同子线程无序输出：任务1、任务2、任务3
}

#pragma mark - 并行队列 + 异步，用GCD的信号量来实现子线程顺序执行
- (void)test3 {
    // 创建一个信号量，大小为0 / 1 / 2
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    // 并行队列
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);// dispatch_get_global_queue(0, 0)
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务1：%@",[NSThread currentThread]);
        // 信号量+1
        dispatch_semaphore_signal(sem);
    });
    
    NSLog(@"主线程1");
    // 信号量-1
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务2：%@",[NSThread currentThread]);
        // 信号量+1
        dispatch_semaphore_signal(sem);
    });
    
    NSLog(@"主线程2");
    // 信号量-1
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_async(queue, ^{
        // 模拟复杂操作
        int i = 0;
        for (int j = 0; j < 100000000; j++) {
            i += 1;
        }
        NSLog(@"任务3：%@",[NSThread currentThread]);
    });
    NSLog(@"主线程3");
    // 信号量大小 == 0 时：
    // 输出结果：主线程1、任务1、主线程2、任务2、主线程3、任务3，在同一个子线程中输出任务，如果
    // 使用的是全局队列，可能不是在同一个子线程中输出任务
    
    // 信号量大小 == 1 时：
    // 输出结果：主线程1、主线程2，无序输出：任务1、任务2、主线程3，但 主线程3 永远不会在无序的第一个，
    // 任务3 永远在最后输出，在不同子线程中输出任务
    
    // 信号量大小 >=2 时：
    // 输出结果：主线程1、主线程2、主线程3，不同子线程无序输出：任务1、任务2、任务3，相当于没有添加信号量
    
    // 根据以上测试结果可以更好的理解，
    // 创建信号量：dispatch_semaphore_create()、
    // 信号量+1：dispatch_semaphore_signal()、
    // 信号量-1：dispatch_semaphore_wait()
    // 这三个方法的含义。
}

#pragma mark - 信号量的应用场景：1、两个请求结果都返回后，再刷新UI；2、并发处理同一个数据；
#pragma mark - 注：异步block中嵌入另一个异步block模拟数据请求
#pragma mark - 方法一：(并行队列 + 异步) + 信号量
// 任务按照顺序执行，完成后，再刷新UI
- (void)action1 {
    
    // 创建一个信号量，大小为0
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    // 并行队列
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        // 模拟数据请求
        dispatch_async(queue, ^{
            
            int i = 0;
            for (int j = 0; j < 100000000; j++) {
                i += 1;
            }
            NSLog(@"任务1：%@",[NSThread currentThread]);
            
            // 信号量+1
            dispatch_semaphore_signal(sem);
        });
    });
    
    NSLog(@"主线程1");
    // 信号量-1
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_async(queue, ^{
        // 模拟数据请求
        dispatch_async(queue, ^{
            
            int i = 0;
            for (int j = 0; j < 100000000; j++) {
                i += 1;
            }
            NSLog(@"任务2：%@",[NSThread currentThread]);
            
            // 信号量+1
            dispatch_semaphore_signal(sem);
        });
    });
    
    NSLog(@"主线程2");
    // 信号量-1
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 主线程刷新UI
        NSLog(@"主线程3，主线程刷新UI");
    });
    // 输出结果：主线程1、任务1、主线程2、任务2、主线程3，主线程刷新UI
}

#pragma mark - 方法二：(并行队列 + 异步组) + dispatch_group_enter、leave(group)对
// 如果不加”dispatch_group_enter、leave(group)对“，输出结果是无序的，
// 且无法得到”两个请求结果都返回后，再刷新UI“的效果。
// 任务按照无序执行，完成后，再刷新UI
- (void)action2 {
    
    // 并行队列
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    // 组
    dispatch_group_t group = dispatch_group_create();
    
    // 进入组
    dispatch_group_enter(group);
    dispatch_group_async(group, queue, ^{
        // 模拟数据请求
        dispatch_async(queue, ^{
            
            int i = 0;
            for (int j = 0; j < 100000000; j++) {
                i += 1;
            }
            NSLog(@"任务1：%@",[NSThread currentThread]);
            
            // 离开组
            dispatch_group_leave(group);
        });
    });
    
    NSLog(@"主线程1");
    
    // 进入组
    dispatch_group_enter(group);
    dispatch_group_async(group, queue, ^{
        // 模拟数据请求
        dispatch_async(queue, ^{
            
            int i = 0;
            for (int j = 0; j < 100000000; j++) {
                i += 1;
            }
            NSLog(@"任务2：%@",[NSThread currentThread]);
            
            // 离开组
            dispatch_group_leave(group);
        });
    });
    
    NSLog(@"主线程2");
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 主线程刷新UI
        NSLog(@"主线程3，主线程刷新UI");
    });
    // 输出结果：主线程1、主线程2、无序输出：任务1、任务2，最后输出：主线程3，主线程刷新UI
}

#pragma mark - 方法三：(并行队列 + 异步组) + 信号量
// 与方法一类似，只是将 异步 换成了 异步组
// 任务按照顺序执行，完成后，再刷新UI
- (void)action3 {
    
    // 创建一个信号量，大小为0
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    // 并行队列
    dispatch_queue_t queue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
    // 组
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        // 模拟数据请求
        dispatch_async(queue, ^{
            
            int i = 0;
            for (int j = 0; j < 100000000; j++) {
                i += 1;
            }
            NSLog(@"任务1：%@",[NSThread currentThread]);
            
            // 信号量+1
            dispatch_semaphore_signal(sem);
        });
    });
    
    NSLog(@"主线程1");
    // 信号量-1
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_group_async(group, queue, ^{
        // 模拟数据请求
        dispatch_async(queue, ^{
            
            int i = 0;
            for (int j = 0; j < 100000000; j++) {
                i += 1;
            }
            NSLog(@"任务2：%@",[NSThread currentThread]);
            
            // 信号量+1
            dispatch_semaphore_signal(sem);
        });
    });
    
    NSLog(@"主线程2");
    // 信号量-1
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 主线程刷新UI
        NSLog(@"主线程3，主线程刷新UI");
    });
    // 输出结果：主线程1、任务1、主线程2、任务2、主线程3，主线程刷新UI
}


@end
