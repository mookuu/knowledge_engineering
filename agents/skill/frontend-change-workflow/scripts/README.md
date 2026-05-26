# 前端流程脚本

如果这个前端改动流程逐渐变得重复，可以在这里补充辅助脚本。

可考虑添加的脚本：
- `validate-ui.*`：运行有针对性的 lint、test 或 build 检查
- `collect-frontend-context.*`：收集受影响的路由、组件或样式文件
- `verify-changed-files.*`：检查改动文件是否符合预期前端范围

每个脚本都应说明：
- 输入
- 输出
- 依赖
- 退出行为
