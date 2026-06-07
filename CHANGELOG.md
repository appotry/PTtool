# Changelog

## [1.1.0] - 2026-06-07

### Changed
- 架构重构：`for $(find)` 替换为 `find | while read`，修复 Shell 注入风险
- 稳定性：`dirlink.sh` 用 `find` 替代 `ls` 遍历子目录
- 路径安全：`autolink.sh` 用 `dirname` 替代 `..` 相对路径
- 清理：移除未使用的 `servicectl()` 死代码

### Added
- 需求文档：UC-5 跨文件系统检测、UC-6 符号链接处理、UC-7 增量补充
- 架构文档：错误流退出码规范
- 测试：TC-CROSSFS、TC-SPECIALCHARS、TC-EXCLUDE、TC-CONCURRENT、TC-FILEGIG-EDGE、TC-STRESS
- 工程：`.gitignore`、`CHANGELOG.md`

### Documentation
- `AGENTS.md`：增加编码规范和敏感数据引用
- `ARCHITECTURE.md`：补充错误流
- `REQUIREMENTS.md`：补充用例和非功能指标

## [1.0.0] - 2026-06-06

### Added
- 初始发布：mklink.sh、dirlink.sh、autolink.sh、autoThanks.sh、rename_episodes.py
- POSIX sh 兼容 + i18n 国际化
- Docker 测试套件（test_suite.sh + verify_nas.sh）
- 工程文档体系（REQUIREMENTS / ARCHITECTURE / TESTING）
