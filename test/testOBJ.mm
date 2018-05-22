//
//  testOBJ.m
//  test
//
//  Created by loary on 2018/5/22.
//  Copyright © 2018年 eee. All rights reserved.
//
//此demo实现当调用一个不存在方法时，不导致程序崩溃，仅日志输出记录

#import "testOBJ.h"
#import <objc/runtime.h>
#import "Student.h"

//当我们再oc中调用类的方法时，比如[obj mss]；如果当前实例obj的mss方法不存在，则系统会出现“unrecognized selector”的错误，其实在系统报此错误之前，系统给了我们几次“补救”的机会，这几次补救的机会就是ios的消息执行机制，理解如下：

//当调用的方法不存在时，系统会给予三次“补救”的机会：

@implementation testOBJ

//第一步：动态方法解析
//对象在收到无法处理的消息时，系统会调用下面的方法，前者是调用类方法时会调用，后者是调用对象方法时会调用
//+ (BOOL)resolveClassMethod:(SEL)sel [类方法专用 ]
//+ (BOOL)resolveInstanceMethod:(SEL)sel [对象方法专用]

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *method = NSStringFromSelector(sel);
    /**
     添加方法
     
     @param self 调用该方法的对象
     @param sel 选择子
     @param IMP 新添加的方法，是c语言实现的
     @param 新添加的方法的类型，包含函数的返回值以及参数内容类型，eg：void xxx(NSString *name, int size)，类型为：v@i
     参考：https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
     */
    class_addMethod(self, sel, (IMP)emptyFun, "v");
    
    [self unrecognizedClassMethod:method];
    return YES;
}

//第二步：将消息转发给项目中的其他对象来处理，注意接收的对象必须要实现了当前调用
//的方法，不然还是会报错
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    NSString *seletorString = NSStringFromSelector(aSelector);
    if ([@"playPiano" isEqualToString:seletorString]) {
        Student *s = [[Student alloc] init];
        return s;
    }
    // 继续转发
    return [super forwardingTargetForSelector:aSelector];
}


//第三步：完整的消息转发
//经历了前两步，还是无法处理消息，那么就会做最后的尝试，先调用methodSignatureForSelector:获取方法签名，然后再调用forwardInvocation:进行处理，这一步的处理可以直接转发给其它对象，即和第二步的效果等效，但是很少有人这么干，因为消息处理越靠后，就表示处理消息的成本越大，性能的开销就越大。所以，在这种方式下，会改变消息内容，比如增加参数，改变选择子等等
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *method = NSStringFromSelector(aSelector);
    //当调用的方法名字符串不为空都进行处理
    if (method.length > 0) {
        
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
        return signature;
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL sel = @selector(unrecognizedMethodC:);
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    anInvocation = [NSInvocation invocationWithMethodSignature:signature];
    [anInvocation setTarget:self];
    [anInvocation setSelector:@selector(unrecognizedMethodC:)];
    NSString *city = @"北京";
    // 消息的第一个参数是self，第二个参数是选择子，所以"北京"是第三个参数
    [anInvocation setArgument:&city atIndex:2];
    
    if ([self respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:self];
        return;
    } else {
        //也可以直接转发给其它对象，类似于forwardingTargetForSelector的处理方式
        Student *s = [[Student alloc] init];
        if ([s respondsToSelector:sel]) {
            [anInvocation invokeWithTarget:s];
            return;
        }
    }
    
    // 从继承树中查找
    [super forwardInvocation:anInvocation];
}

- (void)unrecognizedMethodC:(NSString *)methodName {
    NSLog(@"找不到当前方法---%@",methodName);
    
}

+ (void)unrecognizedClassMethod:(NSString *)methodName {
//    NSLog(@"找不到当前方法11---%@",[NSString stringWithUTF8String:methodName]);
    NSLog(@"找不到当前方法11---%@",methodName);
}

//空的C函数实现
void emptyFun(){}
@end
