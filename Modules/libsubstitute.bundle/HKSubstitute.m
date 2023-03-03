#import "HKSubstitute.h"
#import "vendor/substitute/substitute.h"

extern void SubHookMemory(void* target, const void* data, size_t size);

@implementation HKSubstitute
- (BOOL)_hookClass:(Class)objcClass selector:(SEL)selector replacement:(void *)replacement orig:(void **)orig {
    return substitute_hook_objc_message(objcClass, selector, replacement, (void *)orig, NULL) == SUBSTITUTE_OK;
}

- (BOOL)_hookFunction:(void *)function replacement:(void *)replacement orig:(void **)orig {
    struct substitute_function_hook hook = {
        function, replacement, (void *)orig, 0
    };

    return substitute_hook_functions(&hook, 1, NULL, 0) == SUBSTITUTE_OK;
}

- (int)_hookFunctions:(NSArray<HookKitFunctionHook *> *)functions {
    NSMutableData* hooks = [NSMutableData new];

    for(HookKitFunctionHook* function in functions) {
        struct substitute_function_hook hook = {
            [function function], [function replacement], [function orig], 0
        };

        [hooks appendBytes:&hook length:sizeof(struct substitute_function_hook)];
    }

    int result = substitute_hook_functions([hooks mutableBytes], [functions count], NULL, 0);

    if(result != SUBSTITUTE_OK) {
        NSLog(@"[HKSubstitute] warning: batch substitute_hook_functions retval: %d", result);
    }

    return [functions count];
}

- (BOOL)_hookRegion:(void *)target data:(const void *)data size:(size_t)size {
    SubHookMemory(target, data, size);
    return YES;
}

- (int)_hookRegions:(NSArray<HookKitMemoryHook *> *)regions {
    return -1;
}

- (void *)_openImage:(const char *)path {
    return (void *)substitute_open_image(path);
}

- (void)_closeImage:(void *)image {
    substitute_close_image((struct substitute_image *)image);
}

- (void *)_findSymbol:(const char *)symbol image:(void *)image {
    void* result = NULL;

    if(substitute_find_private_syms((struct substitute_image *)image, &symbol, &result, 1) == SUBSTITUTE_OK) {
        return result;
    }

    return NULL;
}
@end
