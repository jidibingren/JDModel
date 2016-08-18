# JDModel
	基于 FMDB 的 Model 支持model嵌套、元素为model类型的数组、支持遵循NSCoding协议的Foundation和自定义对象


支持的属性类型：

	1.所有基础类型，如：int long float double等

	2.类型为JDModel子类型的属性
	
	3.元素类型为JDModel子类型的数组的属性
	
	4.遵循NSCoding协议的Foundation类型的属性
	
	5.遵循NSCoding协议的自定义类型的属性
	
	6.所有接口都支持异步

	注：4、5中嵌套的子元素若为对象，则必须都支持NSCoding协议，如：NSDictionary类型的属性value及value的子对象都必须支持NSCoding协议.

安装：
	pod 'JDModel'


使用示例：

1. 类型嵌套

	@interface Depart : JDModel

	/** 部门编号 */
	@property (nonatomic, copy)     NSString                    *departNum;
	/** 部门名称 */
	@property (nonatomic, copy)     NSString                    *departName;

	@end

	@interface User : JDModel

	@property (nonatomic, copy)     Depart                      *depart;

	@end


2. model数组

	用JDM_ARRAY_TYPE宏定义与数组元素类名相同的协议

	JDM_ARRAY_TYPE(Depart)

	@interface User : JDModel

	@property (nonatomic, copy)   NSArray<Depart>               *departsArray;

	@end

	注： 
		1. JDM_ARRAY_TYPE(Depart) 中的'Depart'必须与departsArray中元素的类名相同

		2. NSArray<Depart> 中的'Depart'为Depart，而非'Depart *'


3. 遵循 NSCoding 的 Foundation 对象

	@interface User : JDModel

	@property (nonatomic, copy)     NSDictionary                *testDict;

	@end

4. 遵循 NSCoding 的自定义对象
	
	NSCoding协议的实现不在赘述

	@interface TestOb : NSObject <NSCoding>

	/** 部门编号 */
	@property (nonatomic, copy)     NSString                    *departNum;
	/** 部门名称 */
	@property (nonatomic, copy)     NSString                    *departName;

	@end

	@interface User : JDModel

	@property (nonatomic, copy)     TestOb                      *test;

	@property (nonatomic, copy)     NSArray<TestOb*>            *test;

	@end

