# UMake

这是一个Makefile的自动生成工具，用来创建一些较为复杂的自动化测试脚本，主要特性：

1. 支持自动生成基础的Makefile框架，以及导入自己编写的Makefile框架
2. 支持进行安全检测，每个步骤结束后，对生成的文件，文件夹都会进行检测，来确保确实生成成功，否则脚本就会尽早报错，避免一些传参时，文件在找不到时工具却没有报错的情况。
3. 对脚本执行是否成功进行检测，如果遇到执行失败的命令会中断并保留现场方便调试
4. 支持完整性检测，每个步骤只有所有的步骤全部完成后，最后的标记才会标记当前步骤已完成
5. 自动对一系列可能情况生成target，避免模式匹配中匹配不到的问题
6. 自动确保cd到的目录，目标文件生成目录均存在

定义文法：

